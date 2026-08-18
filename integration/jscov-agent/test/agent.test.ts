import { spawn, type ChildProcess } from 'node:child_process';
import { copyFileSync, mkdtempSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { once } from 'node:events';
import { describe, expect, it } from 'vitest';

const moduleRoot = resolve(import.meta.dirname, '..');
const statusUrl = 'http://127.0.0.1:8050/status';

interface PreloadedApp {
    child: ChildProcess;
    isolatedRoot: string;
}

type AgentArgsFactory = (isolatedRoot: string, runtimeData: string) => string[];

function spawnPreloadedApp(
    utaFixture = 'uta-server.js',
    applicationArgs: string[] = [],
    createAgentArgs: AgentArgsFactory = (_isolatedRoot, runtimeData) => ['--jscov.agent.runtimeData', runtimeData]
): PreloadedApp {
    const isolatedRoot = mkdtempSync(join(tmpdir(), 'jscov-agent-preload-'));
    const runtimeData = join(isolatedRoot, 'runtime-data');
    const agentArgs = createAgentArgs(isolatedRoot, runtimeData);
    copyFileSync(resolve(moduleRoot, 'dist/agent.js'), join(isolatedRoot, 'agent.js'));
    copyFileSync(resolve(moduleRoot, `test/fixtures/${utaFixture}`), join(isolatedRoot, 'uta-server.js'));

    return {
        isolatedRoot,
        child: spawn(process.execPath, [
            '--import', './agent.js',
            'uta-server.js',
            ...agentArgs,
            ...applicationArgs
        ], {
            cwd: isolatedRoot,
            env: { ...process.env, NODE_PATH: isolatedRoot },
            stdio: ['ignore', 'pipe', 'pipe']
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

async function waitForOutput(output: () => string, errorOutput: () => string, expected: string): Promise<void> {
    const deadline = Date.now() + 5_000;
    while (!output().includes(expected)) {
        if (Date.now() >= deadline) {
            throw new Error(`Timed out waiting for ${expected}. stdout: ${output()}. stderr: ${errorOutput()}`);
        }
        await new Promise((resolve) => setTimeout(resolve, 25));
    }
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
    it('preloads for the runtime command and exposes temporary status', async () => {
        const app = spawnPreloadedApp('uta-server.js', ['--target-option', 'target-value']);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ARGS:["--target-option","target-value"]');
            expect(output.stdout().indexOf('Parasoft JavaScript runtime coverage agent started on port 8050'))
                .toBeLessThan(output.stdout().indexOf('UTA_SERVER_ENTERED'));
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
            expect(output.stdout()).toContain('Initializing Parasoft JavaScript runtime coverage agent');

            const deadline = Date.now() + 5_000;
            let response: Response | undefined;
            while (!response && Date.now() < deadline) {
                try {
                    response = await fetch(statusUrl);
                } catch {
                    await new Promise((resolve) => setTimeout(resolve, 25));
                }
            }
            expect(response?.status).toBe(200);
            expect(await response?.json()).toEqual({ status: 'ok', temporary: true });
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('writes debug startup diagnostics to the Jtest-style log file', async () => {
        const app = spawnPreloadedApp(
            'uta-server-sigint.js',
            ['--target-option', 'target-value'],
            (_isolatedRoot, runtimeData) => ['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.debug=true']
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
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
        const app = spawnPreloadedApp('uta-server-sigint.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            expect(await waitForExit(output.closed)).toBe(0);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports missing runtime data without emitting diagnostics to the console', async () => {
        const app = spawnPreloadedApp('uta-server.js', [], () => ['--jscov.agent.debug=true']);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
            expect(output.stderr()).toContain('[JSCOV-AGENT][ERROR]: Agent runtime data directory was not set - parameter "jscov.agent.runtimeData" is missing!');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('reports an invalid settings directory without preventing the target from running', async () => {
        const app = spawnPreloadedApp('uta-server.js', [], (isolatedRoot, runtimeData) => [
            '--jscov.agent.runtimeData', runtimeData,
            '--jscov.agent.settings', isolatedRoot
        ]);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            expect(output.stderr()).toContain(`[JSCOV-AGENT][ERROR]: Value of 'settings' configuration should point to file but points incorrectly to directory: ${app.isolatedRoot}`);
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('does not emit debug diagnostics to the console', async () => {
        const app = spawnPreloadedApp('uta-server.js', ['--jscov.agent.restServerPort=not-a-number', '--jscov.agent.debug=true']);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('does not emit AUT debug arguments to the console', async () => {
        const app = spawnPreloadedApp(
            'uta-server.js',
            ['--target-option', 'target-value'],
            (_isolatedRoot, runtimeData) => ['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.debug=true']
        );
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            expect(output.stdout()).not.toContain('[JSCOV-AGENT][DEBUG]:');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('logs an agent server startup error without preventing the UTA from running', async () => {
        const app = spawnPreloadedApp('uta-server.js', ['--jscov.agent.restServerPort=-1']);
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            await waitForOutput(output.stdout, output.stderr, '[JSCOV-AGENT][ERROR]: Parasoft JavaScript runtime coverage agent startup failed:');
            expect(output.stdout()).toContain('[JSCOV-AGENT][ERROR]: Parasoft JavaScript runtime coverage agent startup failed:');
            expect(output.stderr()).not.toContain('[JSCOV-AGENT][ERROR]:');
            const runtimeData = join(app.isolatedRoot, 'runtime-data');
            const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-000001-\d{10}\.log$/.test(file));
            expect(logFile).toBeDefined();
            const logContents = readFileSync(join(runtimeData, logFile), 'utf8');
            expect(logContents).toContain('Parasoft JavaScript runtime coverage agent startup failed:');
            expect(logContents).toMatch(/\n(?:Error|RangeError|TypeError)[^\r\n]*\r?\n\s+at /);
            await expect(waitForExit(output.closed)).rejects.toThrow('Timed out waiting for the preload process to exit');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

    it('closes the agent only once when it receives multiple signals', async () => {
        const app = spawnPreloadedApp('uta-server-multiple-signals.js');
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            expect(await waitForExit(output.closed)).toBe(0);
            expect(output.stderr()).not.toContain('Parasoft JavaScript runtime coverage agent shutdown failed:');
        } finally {
            await terminate(app.child, output.closed);
            removeIsolatedApp(app.isolatedRoot);
        }
    }, 10_000);

});
