import { mkdirSync, statSync } from 'node:fs';
import parse from 'yargs-parser';

const DEFAULT_CONFIG = {
    sessionAutostart: true,
    restServerEnabled: true,
    restServerPort: 8050,
    debug: false
};

export interface AgentConfigInput {
    settings?: unknown;
    runtimeData?: unknown;
    sessionAutostart?: unknown;
    restServerEnabled?: unknown;
    restServerPort?: unknown;
    debug?: unknown;
}

export interface AgentConfig {
    settings: string | undefined;
    runtimeData: string;
    sessionAutostart: boolean;
    restServerEnabled: boolean;
    restServerPort: number;
    debug: boolean;
}

export type ParameterSource = 'ARGS' | 'SETTINGS_FILE';

export interface ConfigurationInput {
    source: ParameterSource;
    input: AgentConfigInput;
}

export interface ConfigurationResolution {
    config: AgentConfig | undefined;
    diagnostics: string[];
    error: string | undefined;
}

export interface CommandLineConfig {
    input: AgentConfigInput;
    targetArgs: string[];
}

type ConfigField = keyof AgentConfigInput;
type EffectiveValues = Partial<Record<ConfigField, EffectiveValue>>;

interface EffectiveValue {
    value: unknown;
    source: ParameterSource;
}

interface ValueConfigurationDefinition {
    field: ConfigField;
    name: string;
    kind: 'value';
}

interface BooleanConfigurationDefinition {
    field: ConfigField;
    name: string;
    kind: 'boolean';
    setBareBoolean(input: AgentConfigInput): void;
}

type ConfigurationDefinition = ValueConfigurationDefinition | BooleanConfigurationDefinition;

const configurations: readonly ConfigurationDefinition[] = [
    { field: 'settings', name: 'jscov.agent.settings', kind: 'value' },
    { field: 'runtimeData', name: 'jscov.agent.runtimeData', kind: 'value' },
    { field: 'sessionAutostart', name: 'jscov.agent.session.autostart', kind: 'boolean', setBareBoolean: (input) => { input.sessionAutostart = true; } },
    { field: 'restServerEnabled', name: 'jscov.agent.restServerEnabled', kind: 'boolean', setBareBoolean: (input) => { input.restServerEnabled = true; } },
    { field: 'restServerPort', name: 'jscov.agent.restServerPort', kind: 'value' },
    { field: 'debug', name: 'jscov.agent.debug', kind: 'boolean', setBareBoolean: (input) => { input.debug = true; } }
];

const configurationByName = new Map(configurations.map((configuration) => [configuration.name, configuration]));

export function parseCommandLine(args: string[]): CommandLineConfig {
    const parsed = parse(args, {
        string: configurations.map((configuration) => configuration.name),
        configuration: {
            'boolean-negation': false,
            'camel-case-expansion': false,
            'dot-notation': false
        }
    });
    const input = getRawInput(parsed);
    const { targetArgs, bareBooleanConfigurations } = stripAgentConfigurations(args);
    for (const configuration of bareBooleanConfigurations) {
        configuration.setBareBoolean(input);
    }

    return { input, targetArgs };
}

export function resolveConfiguration(inputs: readonly ConfigurationInput[]): ConfigurationResolution {
    const values = getEffectiveValues(inputs);
    const debug = resolveBoolean(values.debug?.value, DEFAULT_CONFIG.debug);
    const diagnostics = debug ? getDiagnostics(values) : [];

    try {
        return {
            config: {
                settings: resolveSettings(values.settings?.value),
                runtimeData: resolveRuntimeData(values.runtimeData?.value),
                sessionAutostart: resolveBoolean(values.sessionAutostart?.value, DEFAULT_CONFIG.sessionAutostart),
                restServerEnabled: resolveBoolean(values.restServerEnabled?.value, DEFAULT_CONFIG.restServerEnabled),
                restServerPort: resolvePort(values.restServerPort?.value),
                debug
            },
            diagnostics,
            error: undefined
        };
    } catch (error) {
        return {
            config: undefined,
            diagnostics,
            error: error instanceof Error ? error.message : String(error)
        };
    }
}

function getRawInput(parsed: Record<string, unknown>): AgentConfigInput {
    const input: AgentConfigInput = {};
    for (const configuration of configurations) {
        const value = getLastValue(parsed[configuration.name]);
        if (value !== undefined) {
            input[configuration.field] = value;
        }
    }
    return input;
}

function getEffectiveValues(inputs: readonly ConfigurationInput[]): EffectiveValues {
    const values: EffectiveValues = {};
    for (const configuration of configurations) {
        const value = getEffectiveValue(configuration.field, inputs);
        if (value) {
            values[configuration.field] = value;
        }
    }
    return values;
}

function getEffectiveValue(field: ConfigField, inputs: readonly ConfigurationInput[]): EffectiveValue | undefined {
    for (const source of ['ARGS', 'SETTINGS_FILE'] as const) {
        const input = inputs.find((candidate) => candidate.source === source)?.input;
        const value = input?.[field];
        if (value !== undefined) {
            return { value, source };
        }
    }
    return undefined;
}

function getDiagnostics(values: EffectiveValues): string[] {
    const diagnostics: string[] = [];
    for (const configuration of configurations) {
        const effectiveValue = values[configuration.field];
        if (!effectiveValue) {
            if (configuration.field === 'runtimeData') {
                diagnostics.push('Parameter "runtimeData" has not been set.');
            }
            continue;
        }

        const value = formatValue(effectiveValue.value);
        diagnostics.push(`Agent parameter: ${configuration.field}=${value} (${effectiveValue.source})`);
        if (isOptionalDefaultField(configuration.field) && !isValidOptionalValue(configuration.field, effectiveValue.value)) {
            diagnostics.push(`Parameter "${configuration.field}" has an invalid value "${value}". Default value "${DEFAULT_CONFIG[configuration.field]}" will be used.`);
        }
        if (configuration.field === 'runtimeData' && (typeof effectiveValue.value !== 'string' || effectiveValue.value.trim() === '')) {
            diagnostics.push('Parameter "runtimeData" has not been set.');
        }
    }
    return diagnostics;
}

function formatValue(value: unknown): string {
    return String(value);
}

function isOptionalDefaultField(field: ConfigField): field is keyof typeof DEFAULT_CONFIG {
    return field in DEFAULT_CONFIG;
}

function isValidOptionalValue(field: keyof typeof DEFAULT_CONFIG, value: unknown): boolean {
    return field === 'restServerPort'
        ? normalizePort(value) !== undefined
        : normalizeBoolean(value) !== undefined;
}

function stripAgentConfigurations(args: string[]): { targetArgs: string[]; bareBooleanConfigurations: Set<BooleanConfigurationDefinition> } {
    const targetArgs: string[] = [];
    const bareBooleanConfigurations = new Set<BooleanConfigurationDefinition>();

    for (let index = 0; index < args.length; index += 1) {
        const argument = args[index];
        const match = /^--([^=]+)(?:=(.*))?$/.exec(argument);
        const configuration = match?.[1] ? configurationByName.get(match[1]) : undefined;
        if (!configuration) {
            targetArgs.push(argument);
            continue;
        }
        if (match?.[2] !== undefined) {
            if (configuration.kind === 'boolean') {
                bareBooleanConfigurations.delete(configuration);
            }
            continue;
        }

        const nextArgument = args[index + 1];
        if (configuration.kind === 'boolean') {
            if (nextArgument === 'true' || nextArgument === 'false') {
                bareBooleanConfigurations.delete(configuration);
                index += 1;
            } else {
                bareBooleanConfigurations.add(configuration);
            }
        } else if (nextArgument !== undefined && !nextArgument.startsWith('--')) {
            index += 1;
        }
    }

    return { targetArgs, bareBooleanConfigurations };
}

function normalizeBoolean(value: unknown): boolean | undefined {
    return value === true || value === 'true' ? true : value === false || value === 'false' ? false : undefined;
}

function normalizePort(value: unknown): number | undefined {
    const port = typeof value === 'number'
        ? value
        : typeof value === 'string' && value.trim() !== '' ? Number(value) : undefined;
    return typeof port === 'number' && Number.isFinite(port) ? port : undefined;
}

function getLastValue(value: unknown): unknown {
    return Array.isArray(value) ? value.at(-1) : value;
}

function resolveBoolean(value: unknown, defaultValue: boolean): boolean {
    return normalizeBoolean(value) ?? defaultValue;
}

function resolvePort(value: unknown): number {
    return normalizePort(value) ?? DEFAULT_CONFIG.restServerPort;
}

function resolveSettings(value: unknown): string | undefined {
    if (value === undefined) {
        return undefined;
    }

    const path = String(value);
    let stats;
    try {
        stats = statSync(path);
    } catch {
        throw new Error(`Agent settings file does not exist: ${path}`);
    }
    if (!stats.isFile()) {
        throw new Error(`Value of 'settings' configuration should point to file but points incorrectly to directory: ${path}`);
    }
    return path;
}

function resolveRuntimeData(value: unknown): string {
    if (typeof value !== 'string' || value.trim() === '') {
        throw new Error('Agent runtime data directory was not set - parameter "jscov.agent.runtimeData" is missing!');
    }

    let stats;
    try {
        stats = statSync(value, { throwIfNoEntry: false });
    } catch {
        // Let mkdirSync report whether the path can be created.
    }
    if (stats && !stats.isDirectory()) {
        throw new Error(`Agent runtime data configuration is not a directory: ${value}`);
    }
    try {
        mkdirSync(value, { recursive: true });
    } catch {
        throw new Error(`Agent runtime data directory: ${value} cannot be created.`);
    }
    return value;
}
