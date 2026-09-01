import { spawn, type ChildProcess } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { once } from 'node:events';
import { describe, expect, it } from 'vitest';
import packageInfo from '../package.json' with { type: 'json' };
import i18n from '../src/i18n.js';
import { DEFAULT_USER_ID } from '../src/session/session-service.js';

const moduleRoot = resolve(import.meta.dirname, '..');

interface PreloadedApp {
    child: ChildProcess;
    isolatedRoot: string;
}

type AgentArgsFactory = (isolatedRoot: string, runtimeData: string) => string[];

function spawnPreloadedApp(
    autFixture = 'aut-server.js',
    applicationArgs: string[] = [],
    createAgentArgs: AgentArgsFactory = (_isolatedRoot, runtimeData) => ['--jscov.agent.runtimeData', runtimeData],
    preloadModule = 'agent.js'
): PreloadedApp {
    const isolatedRoot = mkdtempSync(join(tmpdir(), 'jscov-agent-preload-'));
    const runtimeData = join(isolatedRoot, 'runtime-data');
    const agentArgs = ['--jscov.agent.restServerPort=0', ...createAgentArgs(isolatedRoot, runtimeData)];
    copyFileSync(resolve(moduleRoot, 'dist/agent.js'), join(isolatedRoot, 'agent.js'));
    copyFileSync(resolve(moduleRoot, `test/fixtures/${autFixture}`), join(isolatedRoot, 'aut-server.js'));

    return {
        isolatedRoot,
        child: spawn(process.execPath, [
            '--import', `./${preloadModule}`,
            'aut-server.js',
            ...agentArgs,
            ...applicationArgs
        ], {
            cwd: isolatedRoot,
            env: { ...process.env, NODE_PATH: isolatedRoot },
            stdio: ['pipe', 'pipe', 'pipe']
        })
    };
}

interface CapturedOutput {
    stdout(): string;
    stderr(): string;
    closed: Promise<unknown[]>;
}

function collectOutput(child: ChildProcess): CapturedOutput {
    let stdout = '';
    let stderr = '';
    child.stdout?.on('data', (chunk: Buffer) => { stdout += chunk; });
    child.stderr?.on('data', (chunk: Buffer) => { stderr += chunk; });
    return { stdout: () => stdout, stderr: () => stderr, closed: once(child, 'close') };
}

function removeIsolatedApp(isolatedRoot: string): void {
    rmSync(isolatedRoot, { recursive: true, force: true });
}

async function waitForLogContent(logFilePath: string, expected: string): Promise<string> {
    const deadline = Date.now() + 5_000;
    while (Date.now() < deadline) {
        const contents = readFileSync(logFilePath, 'utf8');
        if (contents.includes(expected)) {
            return contents;
        }
        await new Promise((resolve) => setTimeout(resolve, 25));
    }
    throw new Error(`Timed out waiting for log file to contain "${expected}". File: ${logFilePath}`);
}

async function waitForOutput(output: () => string, errorOutput: () => string, expected: string): Promise<void> {
    const deadline = Date.now() + 5_000;
    while (!output().includes(expected)) {
        if (Date.now() >= deadline) {
            throw new Error(`Timed out waiting for ${expected}. stdout: ${output()}. stderr: ${errorOutput()}`);
        }
        await new Promise((resolve) => setTimeout(resolve, 25));
    }
}

async function waitForAgentUrl(output: () => string, errorOutput: () => string): Promise<string> {
    const portMarker = '__PORT__';
    const startupTemplate = i18n.t('agent_started', { port: portMarker });
    const markerIndex = startupTemplate.indexOf(portMarker);
    const startupLine = new RegExp(
        `${escapeRegex(startupTemplate.slice(0, markerIndex))}(\\d+)${escapeRegex(startupTemplate.slice(markerIndex + portMarker.length))}`
    );
    const deadline = Date.now() + 5_000;
    while (true) {
        const match = output().match(startupLine);
        if (match) {
            return `http://127.0.0.1:${match[1]}`;
        }
        if (Date.now() >= deadline) {
            throw new Error(`Timed out waiting for agent startup. stdout: ${output()}. stderr: ${errorOutput()}`);
        }
        await new Promise((resolve) => setTimeout(resolve, 25));
    }
}

function escapeRegex(value: string): string {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function terminate(child: ChildProcess, closed: Promise<unknown[]>): Promise<void> {
    if (child.exitCode === null) {
        child.kill();
    }
    await closed;
}

async function waitForExit(closed: Promise<unknown[]>): Promise<number | null> {
    return await Promise.race([
        closed.then(([exitCode]) => exitCode as number | null),
        new Promise<never>((_resolve, reject) => {
            setTimeout(() => reject(new Error('Timed out waiting for the preload process to exit')), 1_000);
        })
    ]);
}

describe('agent preload', () => {
    it('preloads for the runtime command and exposes the autostarted session', async () => {
        const app = spawnPreloadedApp(
            'aut-server.js',
            ['--target-option', 'target-value'],
            (_isolatedRoot, runtimeData) => [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.restServerEnabled=true'
            ]
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ARGS:["--target-option","target-value"]');
            const agentUrl = await waitForAgentUrl(output.stdout, output.stderr);
            const startupMessage = i18n.t('agent_started', { port: Number(new URL(agentUrl).port) });
            expect(output.stdout().indexOf(startupMessage))
                .toBeLessThan(output.stdout().indexOf('AUT_SERVER_ENTERED'));
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
            expect(output.stdout()).toContain(i18n.t('agent_initializing'));
            expect(JSON.parse(readFileSync(join(app.isolatedRoot, 'runtime-data', 'version.json'), 'utf8'))).toEqual({
                schemaVersion: '1.0',
                toolVersion: packageInfo.version
            });

            const deadline = Date.now() + 5_000;
            let response: Response | undefined;
            while (!response && Date.now() < deadline) {
                try {
                    response = await fetch(`${agentUrl}/status`);
                } catch {
                    await new Promise((resolve) => setTimeout(resolve, 25));
                }
            }
            expect(response?.status).toBe(200);
            expect(await response?.json()).toEqual({ session: expect.stringMatching(/^runtime_coverage_\d{8}_\d{4}_0$/) });
            const sessionFiles = readdirSync(join(app.isolatedRoot, 'runtime-data', '__default__'))
                .filter((file) => file.endsWith('.json'));
            expect(sessionFiles).toHaveLength(1);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('overwrites an existing runtime data version file', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (_isolatedRoot, runtimeData) => {
            mkdirSync(runtimeData, { recursive: true });
            writeFileSync(join(runtimeData, 'version.json'), '{"toolVersion":"stale"}');
            return ['--jscov.agent.runtimeData', runtimeData];
        });
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const versionFile = join(app.isolatedRoot, 'runtime-data', 'version.json');
            expect(JSON.parse(readFileSync(versionFile, 'utf8'))).toEqual({
                schemaVersion: '1.0',
                toolVersion: packageInfo.version
            });
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('starts the REST server by default', async () => {
        const app = spawnPreloadedApp();
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const agentUrl = await waitForAgentUrl(output.stdout, output.stderr);
            expect(output.stdout()).toContain(i18n.t('agent_started', { port: Number(new URL(agentUrl).port) }));
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('writes debug startup diagnostics to the Jtest-style log file', async () => {
        const app = spawnPreloadedApp(
            'aut-server-sigint.js',
            ['--target-option', 'target-value'],
            (_isolatedRoot, runtimeData) => [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.debug=true',
                '--jscov.agent.restServerEnabled=true'
            ]
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(await waitForExit(output.closed)).toBe(0);

            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-000001-\d{10}\.log$/.test(file));
            expect(logFile).toBeDefined();
            const fileContents = readFileSync(join(runtimeData, logFile), 'utf8');
            expect(fileContents).toContain('[JSCOV-AGENT][DEBUG]');
            expect(fileContents).toContain('AUT arguments: ["--target-option","target-value"]');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('closes the agent and exits successfully when it receives SIGINT', async () => {
        const app = spawnPreloadedApp(
            'aut-server-sigint.js',
            [],
            (_isolatedRoot, runtimeData) => [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.restServerEnabled=true'
            ]
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(await waitForExit(output.closed)).toBe(0);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports missing runtime data without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], () => ['--jscov.agent.debug=true']);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
            expect(output.stderr()).toContain(`[JSCOV-AGENT][ERROR]: ${i18n.t('runtime_data_missing')}`);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports an lstatSync I/O failure on the version file without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            mkdirSync(runtimeData, { recursive: true });
            const versionFile = join(runtimeData, 'version.json');
            writeFileSync(join(isolatedRoot, 'lstat-failure-agent.js'), `
                import fs from 'node:fs';
                import { syncBuiltinESMExports } from 'node:module';

                const originalLstatSync = fs.lstatSync;
                fs.lstatSync = (path, options) => {
                    if (path === ${JSON.stringify(versionFile)}) {
                        throw Object.assign(new Error('EACCES: permission denied'), { code: 'EACCES' });
                    }
                    return originalLstatSync(path, options);
                };
                syncBuiltinESMExports();
                await import('./agent.js');
            `);
            return ['--jscov.agent.runtimeData', runtimeData];
        }, 'lstat-failure-agent.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData)
                .filter((file) => /^agent-\d{6}-\d{10}\.log$/.test(file));
            const logContents = await waitForLogContent(join(runtimeData, logFile), 'EACCES');
            expect(logContents).toContain('EACCES');
            expect(output.stdout()).toContain('EACCES');
            expect(output.stderr()).not.toContain('EACCES');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports a symbolic-link runtime data version file without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            mkdirSync(runtimeData, { recursive: true });
            const versionFile = join(runtimeData, 'version.json');
            writeFileSync(join(isolatedRoot, 'symbolic-link-agent.js'), `
                import fs from 'node:fs';
                import { syncBuiltinESMExports } from 'node:module';

                const originalLstatSync = fs.lstatSync;
                fs.lstatSync = (path, options) => path === ${JSON.stringify(versionFile)}
                    ? { isSymbolicLink: () => true }
                    : originalLstatSync(path, options);
                syncBuiltinESMExports();
                await import('./agent.js');
            `);
            return ['--jscov.agent.runtimeData', runtimeData];
        }, 'symbolic-link-agent.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const versionFileError = i18n.t('agent_version_file_symbolic_link', {
                path: join(app.isolatedRoot, 'runtime-data', 'version.json')
            });
            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData)
                .filter((file) => /^agent-\d{6}-\d{10}\.log$/.test(file));
            const logContents = await waitForLogContent(join(runtimeData, logFile), versionFileError);
            expect(logContents).toContain(`Error: ${versionFileError}`);
            expect(output.stdout()).toContain(versionFileError);
            expect(output.stderr()).not.toContain(versionFileError);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports an unwritable runtime data version file without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            const versionFile = join(runtimeData, 'version.json');
            writeFileSync(join(isolatedRoot, 'version-file-write-failure-agent.js'), `
                import fs from 'node:fs';
                import { syncBuiltinESMExports } from 'node:module';

                const originalWriteFileSync = fs.writeFileSync;
                fs.writeFileSync = (path, ...args) => {
                    if (path === ${JSON.stringify(versionFile)}) {
                        throw new Error('EACCES');
                    }
                    return originalWriteFileSync(path, ...args);
                };
                syncBuiltinESMExports();
                await import('./agent.js');
            `);
            return ['--jscov.agent.runtimeData', runtimeData];
        }, 'version-file-write-failure-agent.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const versionFileError = i18n.t('agent_version_file_cannot_be_written', {
                path: join(app.isolatedRoot, 'runtime-data', 'version.json')
            });
            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData)
                .filter((file) => /^agent-\d{6}-\d{10}\.log$/.test(file));
            const logContents = await waitForLogContent(join(runtimeData, logFile), versionFileError);
            expect(logContents).toContain(`Error: ${versionFileError}`);
            expect(output.stdout()).toContain(versionFileError);
            expect(output.stderr()).not.toContain(versionFileError);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports logger initialization failure without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            writeFileSync(join(isolatedRoot, 'logger-initialization-failure-agent.js'), `
                import fs from 'node:fs';
                import { syncBuiltinESMExports } from 'node:module';

                const originalOpenSync = fs.openSync;
                fs.openSync = (path, ...args) => {
                    if (typeof path === 'string' && path.startsWith(${JSON.stringify(runtimeData)})) {
                        throw new Error('EACCES');
                    }
                    return originalOpenSync(path, ...args);
                };
                syncBuiltinESMExports();
                await import('./agent.js');
            `);
            return ['--jscov.agent.runtimeData', runtimeData];
        }, 'logger-initialization-failure-agent.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stderr()).toContain('EACCES');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports an invalid settings directory without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => [
            '--jscov.agent.runtimeData', runtimeData,
            '--jscov.agent.settings', isolatedRoot
        ]);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stderr()).toContain(`[JSCOV-AGENT][ERROR]: ${i18n.t('settings_must_be_file', { path: app.isolatedRoot })}`);
            expect(output.stdout()).not.toContain(i18n.t('agent_started', { port: 8050 }));
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reads JSONC settings and gives CLI values precedence', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            const settings = join(isolatedRoot, 'agent.jsonc');
            writeFileSync(settings, `{
                // Values from the file are tagged as SETTINGS_FILE.
                "jscov.agent.runtimeData": "ignored-by-cli",
                "jscov.agent.session.autostart": false,
                "jscov.agent.restServerEnabled": false,
                "jscov.agent.restServerPort": 9010,
                "jscov.agent.debug": true
            }`);
            return [
                '--jscov.agent.settings', settings,
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.restServerPort', '8050'
            ];
        });
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stdout()).not.toContain(i18n.t('agent_started', { port: 8050 }));

            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-000001-\d{10}\.log$/.test(file));
            expect(logFile).toBeDefined();
            const logFilePath = join(runtimeData, logFile);
            const fileContents = await waitForLogContent(logFilePath, `Agent parameter: runtimeData=${runtimeData} (ARGS)`);
            expect(fileContents).toContain('Agent parameter: sessionAutostart=false (SETTINGS_FILE)');
            expect(fileContents).toContain('Agent parameter: restServerEnabled=false (SETTINGS_FILE)');
            expect(fileContents).toContain('Agent parameter: restServerPort=8050 (ARGS)');
            expect(fileContents).toContain('Agent parameter: debug=true (SETTINGS_FILE)');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('uses runtimeData from settings file when not provided on command line', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot) => {
            const runtimeData = join(isolatedRoot, 'runtime-data');
            const settings = join(isolatedRoot, 'agent.jsonc');
            writeFileSync(settings, JSON.stringify({
                'jscov.agent.runtimeData': runtimeData,
                'jscov.agent.debug': true
            }));
            return ['--jscov.agent.settings', settings];
        });
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const agentUrl = await waitForAgentUrl(output.stdout, output.stderr);
            expect(output.stdout()).toContain(i18n.t('agent_started', { port: Number(new URL(agentUrl).port) }));

            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-000001-\d{10}\.log$/.test(file));
            expect(logFile).toBeDefined();
            const logFilePath = join(runtimeData, logFile);
            const fileContents = await waitForLogContent(logFilePath, `Agent parameter: runtimeData=${runtimeData} (SETTINGS_FILE)`);
            expect(fileContents).toContain('Agent parameter: restServerPort=0 (ARGS)');
            expect(fileContents).toContain('Parasoft JavaScript runtime coverage agent configuration:');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports malformed JSONC settings without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            const settings = join(isolatedRoot, 'agent.jsonc');
            writeFileSync(settings, '{ "jscov.agent.debug": }');
            return [
                '--jscov.agent.settings', settings,
                '--jscov.agent.runtimeData', runtimeData
            ];
        });
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stderr()).toContain(`[JSCOV-AGENT][ERROR]: ${i18n.t('settings_file_invalid_jsonc', { path: join(app.isolatedRoot, 'agent.jsonc') })}`);
            expect(output.stdout()).not.toContain(i18n.t('agent_started', { port: 8050 }));
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports unreadable settings without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            const settings = join(isolatedRoot, 'agent.jsonc');
            writeFileSync(settings, '{}');
            writeFileSync(join(isolatedRoot, 'unreadable-agent.js'), `
                import fs from 'node:fs';
                import { syncBuiltinESMExports } from 'node:module';

                const originalReadFileSync = fs.readFileSync;
                fs.readFileSync = (path, ...args) => {
                    if (path === ${JSON.stringify(settings)}) {
                        throw new Error('EACCES');
                    }
                    return originalReadFileSync(path, ...args);
                };
                syncBuiltinESMExports();
                await import('./agent.js');
            `);
            return [
                '--jscov.agent.settings', settings,
                '--jscov.agent.runtimeData', runtimeData
            ];
        }, 'unreadable-agent.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stderr()).toContain(`[JSCOV-AGENT][ERROR]: ${i18n.t('settings_file_cannot_be_read', { path: join(app.isolatedRoot, 'agent.jsonc') })}`);
            expect(output.stdout()).not.toContain(i18n.t('agent_started', { port: 8050 }));
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports non-existent settings without preventing the target from running', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (isolatedRoot, runtimeData) => {
            const missingSettings = join(isolatedRoot, 'nonexistent.jsonc');
            return [
                '--jscov.agent.settings', missingSettings,
                '--jscov.agent.runtimeData', runtimeData
            ];
        });
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stderr()).toContain(`[JSCOV-AGENT][ERROR]: ${i18n.t('settings_file_does_not_exist', { path: join(app.isolatedRoot, 'nonexistent.jsonc') })}`);
            expect(output.stdout()).not.toContain(i18n.t('agent_started', { port: 8050 }));
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('does not emit debug diagnostics to the console', async () => {
        const app = spawnPreloadedApp('aut-server.js', ['--jscov.agent.restServerPort=not-a-number', '--jscov.agent.debug=true']);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('does not emit AUT debug arguments to the console', async () => {
        const app = spawnPreloadedApp(
            'aut-server.js',
            ['--target-option', 'target-value'],
            (_isolatedRoot, runtimeData) => ['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.debug=true']
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports autostart failure without starting the REST server', async () => {
        const app = spawnPreloadedApp('aut-server.js', [], (_isolatedRoot, runtimeData) => {
            mkdirSync(runtimeData, { recursive: true });
            writeFileSync(join(runtimeData, '__default__'), 'not a directory');
            return [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.restServerEnabled=true'
            ];
        });
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            await waitForOutput(output.stdout, output.stderr, `[JSCOV-AGENT][ERROR]: ${i18n.t('session_start_failed', {
                userId: DEFAULT_USER_ID
            })}`);
            const portMarker = '__PORT__';
            const startupTemplate = i18n.t('agent_started', { port: portMarker });
            const markerIndex = startupTemplate.indexOf(portMarker);
            const startupLine = new RegExp(
                `${escapeRegex(startupTemplate.slice(0, markerIndex))}\\d+${escapeRegex(startupTemplate.slice(markerIndex + portMarker.length))}`
            );
            expect(output.stdout()).not.toMatch(startupLine);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('resets live preloaded-process coverage when a session starts', async () => {
        const app = spawnPreloadedApp(
            'aut-server-coverage.js',
            [],
            (_isolatedRoot, runtimeData) => [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.debug=true',
                '--jscov.agent.session.autostart=false'
            ]
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_COVERAGE_READY');

            const agentUrl = await waitForAgentUrl(output.stdout, output.stderr);
            const response = await fetch(`${agentUrl}/session/start`);
            expect(response.status).toBe(200);

            app.child.stdin?.write('REPORT_COVERAGE\n');
            await waitForOutput(
                output.stdout,
                output.stderr,
                'AUT_COVERAGE:{"/fixture.js":{"s":{"0":0},"f":{"0":0},"b":{"0":[0,0]},"bT":{"0":[6,7]}}}'
            );
            await terminate(app.child, output.closed);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('remaps live preloaded-process coverage for every source on session stop', async () => {
        const app = spawnPreloadedApp(
            'aut-server-source-map.js',
            [],
            (_isolatedRoot, runtimeData) => [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.session.autostart=false'
            ]
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SOURCE_MAP_READY');
            const agentUrl = await waitForAgentUrl(output.stdout, output.stderr);
            const startResponse = await fetch(`${agentUrl}/session/start`);
            expect(startResponse.status).toBe(200);
            const { session } = await startResponse.json() as { session: string };

            app.child.stdin?.write('SET_COVERAGE\n');
            await waitForOutput(output.stdout, output.stderr, 'AUT_SOURCE_MAP_UPDATED');

            const stopResponse = await fetch(`${agentUrl}/session/stop`, { method: 'POST' });
            expect(stopResponse.status).toBe(200);
            expect(await stopResponse.json()).toEqual({ session: null });

            const persisted = JSON.parse(readFileSync(
                join(app.isolatedRoot, 'runtime-data', '__default__', `${session}.json`),
                'utf8'
            ));
            expect(Object.keys(persisted)).toEqual([
                'C:\\project\\src\\first.ts',
                'C:\\project\\src\\second.ts'
            ]);
            expect(persisted['C:\\project\\src\\first.ts']).toMatchObject({
                s: { '0': 3 },
                f: { '0': 5 },
                b: { '0': [7, 0] }
            });
            expect(persisted['C:\\project\\src\\second.ts']).toMatchObject({
                s: { '0': 4 },
                f: { '0': 6 },
                b: { '0': [8, 0] }
            });
            expect(persisted['C:\\project\\src\\first.ts']).not.toHaveProperty('inputSourceMap');
            expect(persisted['C:\\project\\src\\second.ts']).not.toHaveProperty('inputSourceMap');
            expect(persisted).not.toHaveProperty('C:\\project\\dist\\bundle.js');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('logs an agent server startup error without preventing the AUT from running', async () => {
        const invalidPort = -1;
        const app = spawnPreloadedApp('aut-server.js', [
            '--jscov.agent.restServerEnabled=true',
            `--jscov.agent.restServerPort=${invalidPort}`
        ]);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const startupFailure = i18n.t('agent_rest_service_start_failed', {
                detail: i18n.t('agent_rest_invalid_port', { port: invalidPort })
            });
            await waitForOutput(output.stdout, output.stderr, `[JSCOV-AGENT][ERROR]: ${startupFailure}`);
            expect(output.stdout()).toContain(`[JSCOV-AGENT][ERROR]: ${startupFailure}`);
            expect(output.stdout()).not.toContain('options.port should be');
            expect(output.stderr()).not.toContain('[JSCOV-AGENT][ERROR]:');
            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-000001-\d{10}\.log$/.test(file));
            expect(logFile).toBeDefined();
            const logContents = readFileSync(join(runtimeData, logFile), 'utf8');
            expect(logContents).toContain(startupFailure);
            expect(logContents).toMatch(/\n(?:Error|RangeError|TypeError)[^\r\n]*\r?\n\s+at /);
            await expect(waitForExit(output.closed)).rejects.toThrow('Timed out waiting for the preload process to exit');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('logs a REST startup ERROR to stdout in silent mode and keeps file diagnostics', async () => {
        const invalidPort = -1;
        const app = spawnPreloadedApp('aut-server.js', [
            '--jscov.agent.restServerEnabled=true',
            `--jscov.agent.restServerPort=${invalidPort}`,
            '--jscov.agent.silentMode=true'
        ]);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            const startupFailure = i18n.t('agent_rest_service_start_failed', {
                detail: i18n.t('agent_rest_invalid_port', { port: invalidPort })
            });
            await waitForOutput(output.stdout, output.stderr, `[JSCOV-AGENT][ERROR]: ${startupFailure}`);

            expect(output.stdout()).toContain(`[JSCOV-AGENT][ERROR]: ${startupFailure}`);
            expect(output.stdout()).not.toContain('options.port should be');
            expect(output.stdout()).not.toContain(i18n.t('agent_initializing'));
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][INFO]');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][WARN]');
            expect(output.stdout()).not.toMatch(/\n(?:Error|RangeError|TypeError)[^\r\n]*\r?\n\s+at /);
            expect(output.stderr()).not.toContain('[JSCOV-AGENT][ERROR]:');

            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-000001-\d{10}\.log$/.test(file));
            expect(logFile).toBeDefined();
            const logContents = await waitForLogContent(join(runtimeData, logFile), startupFailure);
            expect(logContents).toMatch(/\n(?:Error|RangeError|TypeError)[^\r\n]*\r?\n\s+at /);

            await expect(waitForExit(output.closed)).rejects.toThrow('Timed out waiting for the preload process to exit');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('closes the agent only once when it receives multiple signals', async () => {
        const app = spawnPreloadedApp(
            'aut-server-multiple-signals.js',
            [],
            (_isolatedRoot, runtimeData) => [
                '--jscov.agent.runtimeData', runtimeData,
                '--jscov.agent.restServerEnabled=true'
            ]
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'AUT_SERVER_ENTERED');
            expect(await waitForExit(output.closed)).toBe(0);
            expect(output.stderr()).not.toContain(i18n.t('agent_shutdown_failed'));
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

});
