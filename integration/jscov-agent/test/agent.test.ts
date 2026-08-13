import { spawn, type ChildProcess } from 'node:child_process';
import { copyFileSync, mkdtempSync, rmSync } from 'node:fs';
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

function spawnPreloadedApp(utaFixture = 'uta-server.js'): PreloadedApp {
    const isolatedRoot = mkdtempSync(join(tmpdir(), 'jscov-agent-preload-'));
    copyFileSync(resolve(moduleRoot, 'dist/agent.js'), join(isolatedRoot, 'agent.js'));
    copyFileSync(resolve(moduleRoot, `test/fixtures/${utaFixture}`), join(isolatedRoot, 'uta-server.js'));

    return {
        isolatedRoot,
        child: spawn(process.execPath, [
            '--import', './agent.js',
            'uta-server.js'
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
    it('starts the agent before loading the UTA and exposes temporary status', async () => {
        const app = spawnPreloadedApp();
        const output = collectOutput(app.child);

        try {
            await waitForOutput(output.stdout, output.stderr, 'UTA_SERVER_ENTERED');
            const agentStartIndex = output.stdout().indexOf('Parasoft JavaScript runtime coverage agent started');
            const utaStartIndex = output.stdout().indexOf('UTA_SERVER_ENTERED');
            expect(agentStartIndex).toBeGreaterThanOrEqual(0);
            expect(agentStartIndex).toBeLessThan(utaStartIndex);

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
});
