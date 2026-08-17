import { afterEach, describe, expect, it } from 'vitest';
import { startAgent, type StartedAgent } from '../../src/server/server.js';

describe('startAgent', () => {
    const agents: StartedAgent[] = [];

    afterEach(async () => {
        await Promise.all(agents.splice(0).map((agent) => agent.close()));
    });

    it('starts on the configured port and exposes temporary status', async () => {
        const agent = await startAgent({
            settings: undefined,
            runtimeData: 'unused-by-server',
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 8050,
            debug: false
        });
        agents.push(agent);
        const response = await fetch('http://127.0.0.1:8050/status');
        expect(response.status).toBe(200);
        expect(await response.json()).toEqual({ status: 'ok', temporary: true });
    });
});
