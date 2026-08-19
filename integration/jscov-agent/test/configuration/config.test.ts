import { existsSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import * as fs from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import i18n from '../../src/i18n.js';
import { parseCommandLine, readSettingsFile, resolveConfiguration, type AgentConfig, type AgentConfigInput, type ConfigurationInput } from '../../src/configuration/config.js';

vi.mock('node:fs', { spy: true });

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
    afterEach(() => {
        vi.restoreAllMocks();
        temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true }));
    });

    it('creates runtime data and returns documented defaults', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        expect(resolveArguments(['--jscov.agent.runtimeData', runtimeData])).toMatchObject({
            settings: undefined, runtimeData, sessionAutostart: true, restServerEnabled: true, restServerPort: 8050, debug: false, silentMode: false
        });
        expect(existsSync(runtimeData)).toBe(true);
    });

    it('reads only supported values from a JSONC settings file', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        const runtimeData = join(root, 'runtime-data-from-settings');
        writeFileSync(settings, `{
            // JSONC comments are supported.
            "jscov.agent.runtimeData": ${JSON.stringify(runtimeData)},
            "jscov.agent.session.autostart": false,
            "jscov.agent.restServerEnabled": false,
            "jscov.agent.restServerPort": 9010,
            "jscov.agent.debug": true,
            "jscov.agent.silentMode": true,
            "jscov.agent.include": "ignored",
            "jscov.agent.settings": "ignored.jsonc"
        }`);

        expect(readSettingsFile(settings)).toEqual({
            input: {
                runtimeData,
                sessionAutostart: false,
                restServerEnabled: false,
                restServerPort: 9010,
                debug: true,
                silentMode: true
            },
            error: undefined
        });
    });

    it('returns an error when a settings file contains malformed JSONC', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, '{ "jscov.agent.debug": }');

        const result = readSettingsFile(settings);
        expect(result.input).toEqual({});
        expect(result.error).toBe(i18n.t('settings_file_invalid_jsonc', { path: settings }));
    });

    it('returns an error when a settings file cannot be read', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, '{}');
        vi.mocked(fs.readFileSync).mockImplementationOnce(() => {
            throw new Error('EACCES');
        });

        const result = readSettingsFile(settings);
        expect(result.input).toEqual({});
        expect(result.error).toBe(i18n.t('settings_file_cannot_be_read', { path: settings }));
    });

    it('returns an error when a settings file does not exist', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const missingSettings = join(root, 'missing.jsonc');

        const result = readSettingsFile(missingSettings);
        expect(result.input).toEqual({});
        expect(result.error).toBe(`Agent settings file does not exist: ${missingSettings}`);
    });

    it('returns an error when a settings path points to a directory', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);

        const result = readSettingsFile(root);
        expect(result.input).toEqual({});
        expect(result.error).toBe(`Value of 'settings' configuration should point to file but points incorrectly to directory: ${root}`);
    });

    it('returns an error when settings file contains a top-level array', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, '[1, 2, 3]');

        const result = readSettingsFile(settings);
        expect(result.input).toEqual({});
        expect(result.error).toBe(i18n.t('settings_file_not_json_object', { path: settings }));
    });

    it.each(['"hello"', '42', 'true'])('returns an error when settings file contains a top-level primitive: %s', (content) => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, content);

        const result = readSettingsFile(settings);
        expect(result.input).toEqual({});
        expect(result.error).toBe(i18n.t('settings_file_not_json_object', { path: settings }));
    });

    it('returns empty input without error for an empty settings file', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, '');

        expect(readSettingsFile(settings)).toEqual({ input: {}, error: undefined });
    });

    it('returns empty input without error for a comments-only settings file', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, '// This file only has comments\n/* block comment */');

        expect(readSettingsFile(settings)).toEqual({ input: {}, error: undefined });
    });

    it('returns empty input without error when settings file contains null', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const settings = join(root, 'agent.jsonc');
        writeFileSync(settings, 'null');

        expect(readSettingsFile(settings)).toEqual({ input: {}, error: undefined });
    });

    it('returns empty input without error when settings is not provided', () => {
        expect(readSettingsFile(undefined)).toEqual({ input: {}, error: undefined });
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

    it('parses silentMode and defaults it to false', () => {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        expect(resolveArguments(['--jscov.agent.runtimeData', runtimeData])).toMatchObject({ silentMode: false });
        expect(resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.silentMode=true'])).toMatchObject({ silentMode: true });
        expect(resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.silentMode'])).toMatchObject({ silentMode: true });
        expect(parseCommandLine(['--jscov.agent.silentMode', '--target-option']).input).toMatchObject({ silentMode: true });
        expect(parseCommandLine(['--jscov.agent.silentMode', '--target-option']).targetArgs).toEqual(['--target-option']);
    });

    it('rejects invalid required paths and ignores invalid reusable input values', () => {
        expect(() => resolveArguments([])).toThrow(i18n.t('runtime_data_missing'));
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-config-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        expect(resolveInput({ runtimeData, restServerPort: '9010' } as AgentConfigInput)).toMatchObject({ restServerPort: 9010 });

        expect(() => resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.settings', root]))
            .toThrow(i18n.t('settings_must_be_file', { path: root }));
        const missingSettings = join(root, 'missing.jsonc');
        expect(() => resolveArguments(['--jscov.agent.runtimeData', runtimeData, '--jscov.agent.settings', missingSettings]))
            .toThrow(i18n.t('settings_file_does_not_exist', { path: missingSettings }));

        const runtimeFile = join(root, 'runtime-file');
        writeFileSync(runtimeFile, '');
        expect(() => resolveArguments(['--jscov.agent.runtimeData', runtimeFile]))
            .toThrow(i18n.t('runtime_data_not_directory', { path: runtimeFile }));
        const blockedRuntimeData = join(runtimeFile, 'runtime-data');
        expect(() => resolveArguments(['--jscov.agent.runtimeData', blockedRuntimeData]))
            .toThrow(i18n.t('runtime_data_cannot_be_created', { path: blockedRuntimeData }));
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
                debug: true,
                silentMode: false
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
