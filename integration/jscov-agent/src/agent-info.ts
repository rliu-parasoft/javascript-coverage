import { lstatSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import packageInfo from '../package.json' with { type: 'json' };
import i18n from './i18n.js';

export type AgentMode = 'singleuser';

export interface AgentDescriptor {
    readonly mode: AgentMode;
    readonly toolId: 'parasoft-jscov';
}

export const currentAgentDescriptor: AgentDescriptor = {
    mode: 'singleuser',
    toolId: 'parasoft-jscov'
};

const VERSION_FILE_NAME = 'version.json';
const VERSION_FILE_SCHEMA_VERSION = '1.0' as const;

interface AgentVersion {
    readonly schemaVersion: typeof VERSION_FILE_SCHEMA_VERSION;
    readonly toolVersion: string;
}

export function writeAgentVersionFile(runtimeData: string): void {
    const versionFile = join(runtimeData, VERSION_FILE_NAME);

    if (lstatSync(versionFile, { throwIfNoEntry: false })?.isSymbolicLink()) {
        throw new Error(
            i18n.t('agent_version_file_symbolic_link', { path: versionFile })
        );
    }

    const agentVersion: AgentVersion = {
        schemaVersion: VERSION_FILE_SCHEMA_VERSION,
        toolVersion: packageInfo.version
    };

    try {
        writeFileSync(versionFile, `${JSON.stringify(agentVersion)}\n`);
    } catch (error) {
        throw new Error(
            i18n.t('agent_version_file_cannot_be_written', { path: versionFile }),
            { cause: error }
        );
    }
}
