import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
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

    async function startTestAgent(debug = false, restServerPort = 0): Promise<{ agent: StartedAgent; runtimeData: string; url: string }> {
        const runtimeData = mkdtempSync(join(tmpdir(), 'jscov-agent-server-'));
        temporaryRoots.push(runtimeData);
        const agent = await startAgent({
            settings: undefined,
            runtimeData,
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort,
            debug,
            silentMode: true
        });
        agents.push(agent);
        return { agent, runtimeData, url: `http://127.0.0.1:${agent.port}/session/start` };
    }

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

    it('exposes temporary status on an OS-assigned port', async () => {
        const { url } = await startTestAgent();
        const response = await fetch(new URL('/status', url));
        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({ status: 'ok', temporary: true });
        await expect(fetch('http://[::1]:8050/status')).rejects.toThrow();
    });

    it('logs the actual bound port when configured port is zero', async () => {
        const info = vi.spyOn(LoggerProvider.console, 'info');
        const agent = await startAgent({
            settings: undefined,
            runtimeData: 'unused-by-server',
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 0,
            debug: false,
            silentMode: true
        });
        agents.push(agent);

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

        const response = await fetch(`http://127.0.0.1:${portText}/status`);
        expect(response.status).toBe(200);
    });

    it('does not bind a REST port when disabled', async () => {
        const agent = await startAgent({
            settings: undefined,
            runtimeData: 'unused-by-server',
            sessionAutostart: true,
            restServerEnabled: false,
            restServerPort: 18050,
            debug: false,
            silentMode: true
        });
        agents.push(agent);

        await expect(fetch('http://127.0.0.1:18050/status')).rejects.toThrow();
        await expect(agent.close()).resolves.toBeUndefined();
    });

    it('localizes REST service startup failures', () => {
        const error = new RestServiceStartupError(8050, { code: 'EADDRINUSE' });
        const detail = i18n.t('agent_rest_port_unavailable', { port: 8050 });

        expect(error.message).toBe(i18n.t('agent_rest_service_start_failed', { detail }));
    });

    it('retains the configured nonzero server port', async () => {
        const port = await findAvailablePort();
        const { agent } = await startTestAgent(false, port);

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
            await expect(startTestAgent(false, port)).rejects.toMatchObject({
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
        const { url } = await startTestAgent(true);

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
        const { runtimeData, url } = await startTestAgent(true);
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
