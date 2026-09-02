import { sep } from 'node:path';
import { describe, expect, it } from 'vitest';
import { currentAgentDescriptor } from '../../src/agent-info.js';
import { toConfigResponse, toInfoResponse, toStatusResponse } from '../../src/server/responses.js';

describe('REST response mappers', () => {
    it('maps an absent or active session to the status response contract', () => {
        expect(toStatusResponse(undefined)).toEqual({ session: null });
        expect(toStatusResponse('runtime_coverage_20260820_1603_0')).toEqual({
            session: 'runtime_coverage_20260820_1603_0'
        });
    });

    it('maps the current agent descriptor to the info response contract', () => {
        expect(toInfoResponse(currentAgentDescriptor)).toEqual({
            'agent-mode': 'singleuser',
            'tool-id': 'parasoft-jscov'
        });
    });

    it('maps configuration with configured settings to the config response contract', () => {
        expect(toConfigResponse({
            settings: '/path/to/agent.jsonc',
            runtimeData: '/path/to/runtime/coverage',
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 8050,
            debug: true,
            silentMode: false
        })).toEqual({
            settings: '/path/to/agent.jsonc',
            runtimeData: '/path/to/runtime/coverage',
            descriptionFile: `${sep}path${sep}to${sep}runtime${sep}coverage${sep}version.json`,
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 8050,
            debugOn: true,
            silentModeOn: false
        });
    });

    it('maps configuration with unset settings to the config response contract', () => {
        expect(toConfigResponse({
            settings: undefined,
            runtimeData: '/path/to/runtime/coverage',
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 8050,
            debug: true,
            silentMode: false
        })).toEqual({
            settings: null,
            runtimeData: '/path/to/runtime/coverage',
            descriptionFile: `${sep}path${sep}to${sep}runtime${sep}coverage${sep}version.json`,
            sessionAutostart: false,
            restServerEnabled: true,
            restServerPort: 8050,
            debugOn: true,
            silentModeOn: false
        });
    });
});
