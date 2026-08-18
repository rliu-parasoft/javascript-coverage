import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { LoggerProvider } from '../../src/logging/logger.js';
import { startAgent, type StartedAgent } from '../../src/server/server.js';

describe('startAgent', () => {
    const agents: StartedAgent[] = [];
    const temporaryRoots: string[] = [];

    beforeEach(() => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-server-test-'));
        temporaryRoots.push(root);
        LoggerProvider.initialize({
            settings: undefined,
            runtimeData: root,
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 8050,
            debug: false,
            silentMode: true
        });
    });

    afterEach(async () => {
        await Promise.all(agents.splice(0).map((agent) => agent.close()));
        await LoggerProvider.close();
        temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true }));
    });

    it('starts on the configured port and exposes temporary status', async () => {
        const agent = await startAgent({
            settings: undefined,
            runtimeData: 'unused-by-server',
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 8050,
            debug: false,
            silentMode: false
        });
        agents.push(agent);
        const response = await fetch('http://127.0.0.1:8050/status');
        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({ status: 'ok', temporary: true });
    });
});
