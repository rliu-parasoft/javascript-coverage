import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import i18n from '../../src/i18n.js';
import { LoggerProvider } from '../../src/logging/logger.js';
import { RestServiceStartupError, startAgent, type StartedAgent } from '../../src/server/server.js';

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
        vi.restoreAllMocks();
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

});
