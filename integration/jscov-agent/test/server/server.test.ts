import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join, relative } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { resolveConfiguration, type AgentConfig } from '../../src/configuration/config.js';
import i18n from '../../src/i18n.js';
import { LoggerProvider } from '../../src/logging/logger.js';
import { RestServiceStartupError, startAgent, type StartedAgent } from '../../src/server/server.js';

describe('startAgent', () => {
    const agents: StartedAgent[] = [];
    const temporaryRoots: string[] = [];
    let loggerRuntimeData: string;

    beforeEach(async () => {
        loggerRuntimeData = mkdtempSync(join(tmpdir(), 'jscov-server-test-'));
        temporaryRoots.push(loggerRuntimeData);
        await configureLogger();
    });

    afterEach(async () => {
        await Promise.all(agents.splice(0).map((agent) => agent.close()));
        await LoggerProvider.close();
        vi.restoreAllMocks();
        await i18n.changeLanguage('en');
        temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true }));
    });

    async function findAvailablePort(): Promise<number> {
        const server = createServer();
        try {
            await new Promise<void>((resolve, reject) => {
                server.once('error', reject);
                server.listen(0, () => {
                    server.off('error', reject);
                    resolve();
                });
            });
            const address = server.address();
            if (!address || typeof address === 'string') {
                throw new Error('Test server did not bind to a TCP port');
            }
            return address.port;
        } finally {
            if (server.listening) {
                await new Promise<void>((resolve, reject) => {
                    server.close((error) => (error ? reject(error) : resolve()));
                });
            }
        }
    }

    async function startTestAgent(overrides: Partial<AgentConfig> = {}): Promise<{ agent: StartedAgent; runtimeData: string; baseUrl: string; url: string }> {
        const runtimeData = overrides.runtimeData ?? mkdtempSync(join(tmpdir(), 'jscov-agent-server-'));
        if (overrides.runtimeData === undefined) {
            temporaryRoots.push(runtimeData);
        }
        const config: AgentConfig = {
            settings: undefined,
            runtimeData,
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 0,
            debug: false,
            silentMode: true,
            ...overrides
        };
        const agent = await startAgent(config);
        agents.push(agent);
        const baseUrl = `http://127.0.0.1:${agent.port}`;
        return { agent, runtimeData: config.runtimeData, baseUrl, url: `${baseUrl}/session/start` };
    }

    it('autostarts one default-user session before serving the REST API', async () => {
        const { runtimeData, url } = await startTestAgent({ sessionAutostart: true });

        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);

        const response = await fetch(url);
        expect(response.status).toBe(400);
        expect(await response.json()).toEqual({
            messageCode: 150,
            message: i18n.t('session_already_started')
        });
        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);
    });

    it('does not autostart a session when autostart is disabled', async () => {
        const { runtimeData, url } = await startTestAgent({ sessionAutostart: false });

        expect(() => readdirSync(join(runtimeData, '__default__'))).toThrowError(expect.objectContaining({ code: 'ENOENT' }));

        const response = await fetch(url);
        expect(response.status).toBe(200);
        expect(await response.json()).toMatchObject({ session: expect.stringMatching(/^runtime_coverage_\d{8}_\d{4}_0$/) });
        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);
    });

    async function configureLogger(debug = false): Promise<void> {
        await LoggerProvider.close();
        LoggerProvider.initialize({
            settings: undefined,
            runtimeData: loggerRuntimeData,
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 8050,
            debug,
            silentMode: true
        });
    }

    function readLoggerOutput(): string {
        const logFile = readdirSync(loggerRuntimeData).filter((file) => file.endsWith('.log')).sort().at(-1);
        if (!logFile) {
            throw new Error('Agent log file was not created.');
        }
        return readFileSync(join(loggerRuntimeData, logFile), 'utf8');
    }

    type ResponseLog = {
        date: string;
        time: string;
        clientAddress: string;
        userIdentifier: string;
        serverAddress: string;
        serverPort: string;
        method: string;
        resourcePath: string;
        resourceQuery: string;
        statusCode: string;
        responseSize: string;
        requestSize: string;
        duration: string;
        host: string;
        userAgent: string;
        referrer: string;
    };

    function parseResponseLog(message: string): ResponseLog {
        const [
            date, time, clientAddress, userIdentifier, serverAddress, serverPort,
            method, resourcePath, resourceQuery, statusCode, responseSize, requestSize,
            duration, host, userAgent, referrer
        ] = message.split('\t');
        return {
            date, time, clientAddress, userIdentifier, serverAddress, serverPort,
            method, resourcePath, resourceQuery, statusCode, responseSize, requestSize,
            duration, host, userAgent, referrer
        };
    }

    it('writes an access log after every registered route response', async () => {
        const info = vi.spyOn(LoggerProvider.console, 'info');
        const { url } = await startTestAgent();
        info.mockClear();

        const status = await fetch(new URL('/status?userId=__Default__', url), {
            headers: { 'User-Agent': 'status-access-log-test', Referer: 'https://example.test/status' }
        });
        expect(status.status).toBe(200);
        await status.json();

        const session = await fetch(url, {
            method: 'POST',
            headers: { 'User-Agent': 'session-access-log-test', Referer: 'https://example.test/session' }
        });
        expect(session.status).toBe(200);
        await session.json();

        const [statusLog, sessionLog] = info.mock.calls.map(([message]) => parseResponseLog(message));

        expect(statusLog.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        expect(statusLog.time).toMatch(/^\d{2}:\d{2}:\d{2}$/);
        expect(statusLog.clientAddress).toEqual(expect.any(String));
        expect(statusLog.userIdentifier).toBe('-');
        expect(statusLog.serverAddress).toEqual(expect.any(String));
        expect(statusLog.serverPort).toMatch(/^\d+$/);
        expect(statusLog.method).toBe('GET');
        expect(statusLog.resourcePath).toBe('/status');
        expect(statusLog.resourceQuery).toBe('userId=__Default__');
        expect(statusLog.statusCode).toBe('200');
        expect(statusLog.responseSize).toMatch(/^\d+$/);
        expect(statusLog.requestSize).toBe('0');
        expect(statusLog.duration).toMatch(/^\d+$/);
        expect(statusLog.host).toMatch(/^127\.0\.0\.1:\d+$/);
        expect(statusLog.userAgent).toBe('status-access-log-test');
        expect(statusLog.referrer).toBe('https://example.test/status');

        expect(sessionLog.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        expect(sessionLog.time).toMatch(/^\d{2}:\d{2}:\d{2}$/);
        expect(sessionLog.clientAddress).toEqual(expect.any(String));
        expect(sessionLog.userIdentifier).toBe('-');
        expect(sessionLog.serverAddress).toEqual(expect.any(String));
        expect(sessionLog.serverPort).toMatch(/^\d+$/);
        expect(sessionLog.method).toBe('POST');
        expect(sessionLog.resourcePath).toBe('/session/start');
        expect(sessionLog.resourceQuery).toBe('-');
        expect(sessionLog.statusCode).toBe('200');
        expect(sessionLog.responseSize).toMatch(/^\d+$/);
        expect(sessionLog.requestSize).toBe('0');
        expect(sessionLog.duration).toMatch(/^\d+$/);
        expect(sessionLog.host).toMatch(/^127\.0\.0\.1:\d+$/);
        expect(sessionLog.userAgent).toBe('session-access-log-test');
        expect(sessionLog.referrer).toBe('https://example.test/session');
    });

    it.each(['GET', 'POST'] as const)('returns the active default-user session from GET /status after %s /session/start', async (method) => {
        const { baseUrl } = await startTestAgent();
        let response = await fetch(`${baseUrl}/status`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({ session: null });

        response = await fetch(`${baseUrl}/session/start`, { method });
        expect(response.status).toBe(200);
        const { session } = await response.json() as { session: string };

        response = await fetch(`${baseUrl}/status`);
        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({ session });
        await expect(fetch('http://[::1]:8050/status')).rejects.toThrow();
    });

    it('logs the actual bound port when configured port is zero', async () => {
        const info = vi.spyOn(LoggerProvider.console, 'info');
        const { baseUrl } = await startTestAgent();

        const message = info.mock.calls.at(-1)?.[0];
        if (!message) {
            throw new Error('Expected a REST startup message.');
        }
        const marker = '__PORT__';
        const template = i18n.t('agent_started', { port: marker });
        const markerIndex = template.indexOf(marker);
        const prefix = template.slice(0, markerIndex);
        const suffix = template.slice(markerIndex + marker.length);
        const portText = message.slice(prefix.length, message.length - suffix.length);

        expect(message.startsWith(prefix)).toBe(true);
        expect(message.endsWith(suffix)).toBe(true);
        expect(portText).toMatch(/^\d+$/);
        expect(Number(portText)).toBeGreaterThan(0);

        const response = await fetch(`${baseUrl}/status`);
        expect(response.status).toBe(200);
    });

    it('returns the effective configuration from GET /config', async () => {
        const { baseUrl } = await startTestAgent({
            settings: '/path/to/agent.jsonc',
            runtimeData: '/path/to/runtime/coverage',
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 0,
            debug: true,
            silentMode: true
        });

        const response = await fetch(`${baseUrl}/config`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({
            settings: '/path/to/agent.jsonc',
            runtimeData: '/path/to/runtime/coverage',
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 0,
            debugOn: true,
            silentModeOn: true
        });
    });

    it('returns absolute paths from relative configuration through GET /config', async () => {
        const settings = join(process.cwd(), 'package.json');
        const runtimeData = join(process.cwd(), 'test');
        const configuration = resolveConfiguration([{
            source: 'ARGS',
            input: {
                settings: relative(process.cwd(), settings),
                runtimeData: relative(process.cwd(), runtimeData),
                sessionAutostart: false,
                restServerEnabled: true,
                restServerPort: 0,
                debug: true,
                silentMode: false
            }
        }]);
        expect(configuration.error).toBeUndefined();

        const { baseUrl } = await startTestAgent(configuration.config!);
        const response = await fetch(`${baseUrl}/config`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({
            settings,
            runtimeData,
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 0,
            debugOn: true,
            silentModeOn: false
        });
    });

    it('returns a settings key when GET /config has unset settings', async () => {
        const { baseUrl } = await startTestAgent({
            settings: undefined,
            runtimeData: '/path/to/runtime/coverage',
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 0,
            debug: true,
            silentMode: false
        });

        const response = await fetch(`${baseUrl}/config`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({
            settings: null,
            runtimeData: '/path/to/runtime/coverage',
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 0,
            debugOn: true,
            silentModeOn: false
        });
    });

    it('returns the agent identity from GET /info', async () => {
        const { baseUrl } = await startTestAgent({
            settings: undefined,
            runtimeData: 'unused-by-server',
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 0,
            debug: false,
            silentMode: false
        });

        const response = await fetch(`${baseUrl}/info`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({
            'agent-mode': 'singleuser',
            'tool-id': 'parasoft-jscov'
        });
    });

    it('does not bind a REST port when disabled', async () => {
        const runtimeData = mkdtempSync(join(tmpdir(), 'jscov-agent-rest-disabled-'));
        temporaryRoots.push(runtimeData);
        const port = await findAvailablePort();
        const agent = await startAgent({
            settings: undefined,
            runtimeData,
            sessionAutostart: true,
            restServerEnabled: false,
            restServerPort: port,
            debug: false,
            silentMode: true
        });
        agents.push(agent);

        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);
        await expect(fetch(`http://127.0.0.1:${port}/status`)).rejects.toThrow();
        await expect(agent.close()).resolves.toBeUndefined();
    });

    it('fails Agent startup before binding when autostart preparation fails', async () => {
        const runtimeData = mkdtempSync(join(tmpdir(), 'jscov-autostart-failure-'));
        temporaryRoots.push(runtimeData);
        writeFileSync(join(runtimeData, '__default__'), 'not a directory');
        const port = await findAvailablePort();

        await expect(startAgent({
            settings: undefined,
            runtimeData,
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: port,
            debug: false,
            silentMode: true
        })).rejects.toThrow();

        await expect(fetch(`http://127.0.0.1:${port}/status`)).rejects.toThrow();
    });

    it('localizes REST service startup failures', () => {
        const error = new RestServiceStartupError(8050, { code: 'EADDRINUSE' });
        const detail = i18n.t('agent_rest_port_unavailable', { port: 8050 });

        expect(error.message).toBe(i18n.t('agent_rest_service_start_failed', { detail }));
    });
    it('retains the configured nonzero server port', async () => {
        const port = await findAvailablePort();
        const { agent } = await startTestAgent({ restServerPort: port });

        expect(agent.port).toBe(port);
    });

    it('preserves the bind error when the configured server port is occupied', async () => {
        const port = await findAvailablePort();
        const occupiedServer = createServer();
        await new Promise<void>((resolve, reject) => {
            occupiedServer.once('error', reject);
            occupiedServer.listen({ port, host: '0.0.0.0' }, () => {
                occupiedServer.off('error', reject);
                resolve();
            });
        });

        try {
            const detail = i18n.t('agent_rest_port_unavailable', { port });
            await expect(startTestAgent({ restServerPort: port })).rejects.toMatchObject({
                name: 'RestServiceStartupError',
                message: i18n.t('agent_rest_service_start_failed', { detail })
            });
        } finally {
            await new Promise<void>((resolve, reject) => {
                occupiedServer.close((error) => (error ? reject(error) : resolve()));
            });
        }
    });

    it.each(['GET', 'POST'] as const)('%s /session/start creates the default-user session', async (method) => {
        const { runtimeData, url } = await startTestAgent();

        const response = await fetch(url, { method });

        expect(response.status).toBe(200);
        expect(await response.json()).toMatchObject({ session: expect.stringMatching(/^runtime_coverage_\d{8}_\d{4}_0$/) });
        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);
    });

    it('logs the started session when debug logging is enabled', async () => {
        await configureLogger(true);
        const { url } = await startTestAgent({ debug: true });

        const response = await fetch(url);

        expect(response.status).toBe(200);
        await LoggerProvider.close();
        const contents = readLoggerOutput();
        expect(contents).toMatch(/Started session runtime_coverage_/);
    });

    it('does not write session-start diagnostics when debug logging is disabled', async () => {
        const { url } = await startTestAgent();

        expect((await fetch(url)).status).toBe(200);
        expect((await fetch(url, { method: 'POST' })).status).toBe(400);
        await LoggerProvider.close();
        const contents = readLoggerOutput();
        expect(contents).not.toContain('Started session runtime_coverage_');
        expect(contents).not.toContain('Session is already started');
    });

    it('returns the duplicate contract without creating another session file', async () => {
        await configureLogger(true);
        const log = vi.spyOn(LoggerProvider.file, 'debug');
        const { runtimeData, url } = await startTestAgent({ debug: true });
        await fetch(url);
        log.mockClear();

        const response = await fetch(url, { method: 'POST' });

        expect(response.status).toBe(400);
        expect(await response.json()).toEqual({ messageCode: 150, message: 'Session is already started' });
        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);
        expect(log).toHaveBeenCalledWith('Session is already started');
    });

    it('localizes the duplicate session-start response', async () => {
        await i18n.changeLanguage('zh');
        const { url } = await startTestAgent();
        await fetch(url);

        const response = await fetch(url, { method: 'POST' });

        expect(response.status).toBe(400);
        expect(await response.json()).toEqual({ messageCode: 150, message: '会话已启动' });
    });

    it('preserves coverage hits on a duplicate session start', async () => {
        const coverageGlobal = globalThis as typeof globalThis & { __coverage__?: unknown };
        const hadCoverage = Object.hasOwn(coverageGlobal, '__coverage__');
        const previousCoverage = coverageGlobal.__coverage__;
        const { url } = await startTestAgent();
        await fetch(url);
        coverageGlobal.__coverage__ = {
            '/app.js': {
                s: { '0': 3 }, f: { '0': 2 },
                b: { '0': [4, 5] }, bT: { '0': [6, 7] }
            }
        };

        try {
            const response = await fetch(url, { method: 'POST' });

            expect(response.status).toBe(400);
            expect(await response.json()).toEqual({ messageCode: 150, message: 'Session is already started' });
            expect(coverageGlobal.__coverage__).toEqual({
                '/app.js': {
                    s: { '0': 3 }, f: { '0': 2 },
                    b: { '0': [4, 5] }, bT: { '0': [6, 7] }
                }
            });
        } finally {
            if (hadCoverage) {
                coverageGlobal.__coverage__ = previousCoverage;
            } else {
                delete coverageGlobal.__coverage__;
            }
        }
    });

    it('allows only one concurrent default-user start', async () => {
        const { runtimeData, url } = await startTestAgent();

        const responses = await Promise.all([fetch(url), fetch(url, { method: 'POST' })]);

        expect((await Promise.all(responses.map((response) => response.status))).sort()).toEqual([200, 400]);
        expect(readdirSync(join(runtimeData, '__default__'))).toHaveLength(1);
    });

    it('returns the internal-error contract and releases the user after preparation fails', async () => {
        const consoleError = vi.spyOn(LoggerProvider.console, 'error');
        const { runtimeData, url } = await startTestAgent();
        const userDirectory = join(runtimeData, '__default__');
        writeFileSync(userDirectory, 'not a directory');

        const failed = await fetch(url);
        expect(failed.status).toBe(500);
        const body = await failed.json() as { messageCode: number; message: string };
        expect(body).toMatchObject({ messageCode: 500, message: expect.stringMatching(/^Failed to start session: /) });
        expect(consoleError).toHaveBeenCalledWith(body.message);

        rmSync(userDirectory);
        expect((await fetch(url, { method: 'POST' })).status).toBe(200);
        await LoggerProvider.close();
        const fileOutput = readLoggerOutput();
        expect(fileOutput).toContain(body.message);
        expect(fileOutput).toMatch(/\nError: /);
    });

    it('starts a session before application coverage is available', async () => {
        const coverageGlobal = globalThis as typeof globalThis & { __coverage__?: unknown };
        const hadCoverage = Object.hasOwn(coverageGlobal, '__coverage__');
        const previousCoverage = coverageGlobal.__coverage__;
        delete coverageGlobal.__coverage__;

        try {
            const { url } = await startTestAgent();
            expect((await fetch(url)).status).toBe(200);
        } finally {
            if (hadCoverage) {
                coverageGlobal.__coverage__ = previousCoverage;
            } else {
                delete coverageGlobal.__coverage__;
            }
        }
    });
});
