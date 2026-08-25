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

const MANIFEST_FILENAME = 'version.json';
const MANIFEST_SCHEMA_VERSION = '1.0' as const;

interface AgentVersion {
    readonly schemaVersion: typeof MANIFEST_SCHEMA_VERSION;
    readonly toolVersion: string;
}

export function writeAgentVersionManifest(runtimeData: string): void {
    const manifestPath = join(runtimeData, MANIFEST_FILENAME);

    if (lstatSync(manifestPath, { throwIfNoEntry: false })?.isSymbolicLink()) {
        throw new Error(
            i18n.t('agent_version_manifest_symbolic_link', { path: manifestPath })
        );
    }

    const manifest: AgentVersion = {
        schemaVersion: MANIFEST_SCHEMA_VERSION,
        toolVersion: packageInfo.version
    };

    try {
        writeFileSync(manifestPath, `${JSON.stringify(manifest)}\n`);
    } catch (error) {
        throw new Error(
            i18n.t('agent_version_manifest_cannot_be_written', { path: manifestPath }),
            { cause: error }
        );
    }
}
