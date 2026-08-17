import { existsSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import { parseCommandLine, resolveConfiguration, type AgentConfig, type AgentConfigInput, type ConfigurationInput } from '../../src/configuration/config.js';

function resolveInput(input: AgentConfigInput): AgentConfig {
    const resolution = resolveConfiguration([{ source: 'ARGS', input }]);
    if (resolution.error) {
        throw new Error(resolution.error);
    }
    return resolution.config!;
}

function resolveArguments(args: string[]): AgentConfig {
    return resolveInput(parseCommandLine(args).input);
}

describe('configuration', () => {
    const temporaryRoots: string[] = [];
    afterEach(() => temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true })));

    it('creates runtime data and returns documented defaults', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        expect(resolveArguments(['--jscov.agent.runtimeData', runtimeData])).toMatchObject({
            settings: undefined, runtimeData, sessionAutostart: true, restServerEnabled: true, restServerPort: 8050, debug: false
        });
        expect(existsSync(runtimeData)).toBe(true);
    });

    it('uses explicit values and defaults non-numeric ports', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, '{}');
        expect(resolveArguments([
            '--jscov.agent.runtimeData', runtimeData, '--jscov.agent.settings', settings,
            '--jscov.agent.session.autostart=false', '--jscov.agent.restServerEnabled=false',
            '--jscov.agent.restServerPort=9010', '--jscov.agent.debug=true'
        ])).toMatchObject({ settings, runtimeData, sessionAutostart: false, restServerEnabled: false, restServerPort: 9010, debug: true });
        expect(resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.restServerPort=not-a-number'])).toMatchObject({ restServerPort: 8050 });
    });

    it('rejects invalid required paths and ignores invalid reusable input values', () => {
        expect(() => resolveArguments([])).toThrow('Agent runtime data directory was not set - parameter "jscov.agent.runtimeData" is missing!');
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        expect(resolveInput({ runtimeData, restServerPort: '9010' } as AgentConfigInput)).toMatchObject({ restServerPort: 9010 });

        expect(() => resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.settings', root]))
            .toThrow(`Value of 'settings' configuration should point to file but points incorrectly to directory: ${root}`);
        const missingSettings = join(root, 'missing.jsonc');
        expect(() => resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.settings', missingSettings]))
            .toThrow(`Agent settings file does not exist: ${missingSettings}`);

        const runtimeFile = join(root, 'runtime-file');
        writeFileSync(runtimeFile, '');
        expect(() => resolveArguments(['--jscov.agent.runtimeData', runtimeFile]))
            .toThrow(`Agent runtime data configuration is not a directory: ${runtimeFile}`);
        const blockedRuntimeData = join(runtimeFile, 'runtime-data');
        expect(() => resolveArguments(['--jscov.agent.runtimeData', blockedRuntimeData]))
            .toThrow(`Agent runtime data directory: ${blockedRuntimeData} cannot be created.`);
    });

    it('strips agent options throughout the command line', () => {
        expect(parseCommandLine([
            '--jscov.agent.runtimeData', 'runtime-data', '--jscov.agent.debug',
            '--target-option', 'value', '--', '--jscov.agent.debug'
        ])).toEqual({
            input: { settings: undefined, runtimeData: 'runtime-data', sessionAutostart: undefined, restServerEnabled: undefined, restServerPort: undefined, debug: true },
            targetArgs: ['--target-option', 'value', '--']
        });
    });

    it('resolves command line values before settings values and reports their source when debug is enabled', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        const inputs: ConfigurationInput[] = [
            {
                source: 'SETTINGS_FILE',
                input: { runtimeData, sessionAutostart: false, restServerEnabled: false, restServerPort: 9010, debug: true }
            },
            {
                source: 'ARGS',
                input: { restServerEnabled: 'invalid', restServerPort: 'not-a-number', debug: true }
            }
        ];

        expect(resolveConfiguration(inputs)).toEqual({
            config: {
                settings: undefined,
                runtimeData,
                sessionAutostart: false,
                restServerEnabled: true,
                restServerPort: 8050,
                debug: true
            },
            error: undefined,
            diagnostics: [
                `Agent parameter: runtimeData=${runtimeData} (SETTINGS_FILE)`,
                'Agent parameter: sessionAutostart=false (SETTINGS_FILE)',
                'Agent parameter: restServerEnabled=invalid (ARGS)',
                'Parameter "restServerEnabled" has an invalid value "invalid". Default value "true" will be used.',
                'Agent parameter: restServerPort=not-a-number (ARGS)',
                'Parameter "restServerPort" has an invalid value "not-a-number". Default value "8050" will be used.',
                'Agent parameter: debug=true (ARGS)'
            ]
        });
    });

    it('uses finite numeric ports without restricting their range', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        for (const port of [-1, 0, 65_536, 3.5]) {
            expect(resolveInput({ runtimeData, restServerPort: port })).toMatchObject({ restServerPort: port });
        }
        for (const port of ['Infinity', '-Infinity', 'NaN']) {
            expect(resolveInput({ runtimeData, restServerPort: port })).toMatchObject({ restServerPort: 8050 });
        }
    });
});
