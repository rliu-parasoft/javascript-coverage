import { join } from 'node:path';
import type { AgentDescriptor } from '../agent-info.js';
import type { AgentConfig } from '../configuration/config.js';

export interface ErrorResponse {
    messageCode: number;
    message: string;
}

export interface SkippedCoverage {
    id: string;
    messageCode: number;
    reason: string;
}

export interface DeleteCoverageResponse {
    skipped: SkippedCoverage[];
    deleted: string[];
}

export interface StatusResponse {
    session: string | null;
}

export interface ConfigResponse {
    settings: string | null;
    runtimeData: string;
    descriptionFile: string;
    sessionAutostart: boolean;
    restServerEnabled: boolean;
    restServerPort: number;
    debugOn: boolean;
    silentModeOn: boolean;
}

export interface InfoResponse {
    'agent-mode': AgentDescriptor['mode'];
    'tool-id': AgentDescriptor['toolId'];
}

export function toStatusResponse(session: string | undefined): StatusResponse {
    return { session: session ?? null };
}

export function toConfigResponse(config: AgentConfig): ConfigResponse {
    return {
        settings: config.settings ?? null,
        runtimeData: config.runtimeData,
        // The manifest path follows the effective runtime-data directory before the file is generated.
        descriptionFile: join(config.runtimeData, 'version.json'),
        sessionAutostart: config.sessionAutostart,
        restServerEnabled: config.restServerEnabled,
        restServerPort: config.restServerPort,
        debugOn: config.debug,
        silentModeOn: config.silentMode
    };
}

export function toInfoResponse(descriptor: AgentDescriptor): InfoResponse {
    return {
        'agent-mode': descriptor.mode,
        'tool-id': descriptor.toolId
    };
}
