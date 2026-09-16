import * as fs from 'node:fs';
import { mkdtempSync, mkdirSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import packageInfo from '../package.json' with { type: 'json' };
import { writeAgentVersionFile } from '../src/agent-info.js';
import i18n from '../src/i18n.js';

vi.mock('node:fs', { spy: true });

describe('agent version manifest', () => {
    const temporaryRoots: string[] = [];

    afterEach(() => {
        vi.restoreAllMocks();
        temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true }));
    });

    function createRuntimeData(): string {
        const root = mkdtempSync(join(tmpdir(), 'jscov-agent-info-'));
        temporaryRoots.push(root);
        const runtimeData = join(root, 'runtime-data');
        mkdirSync(runtimeData);
        return runtimeData;
    }

    it('writes the current version manifest to runtime data', () => {
        const runtimeData = createRuntimeData();

        writeAgentVersionFile(runtimeData);

        expect(JSON.parse(readFileSync(join(runtimeData, 'version.json'), 'utf8'))).toEqual({
            schemaVersion: '1.0',
            toolVersion: packageInfo.version
        });
    });

    it('rejects a symbolic version manifest', () => {
        const runtimeData = createRuntimeData();
        const versionFile = join(runtimeData, 'version.json');
        vi.mocked(fs.lstatSync).mockReturnValueOnce({ isSymbolicLink: () => true } as fs.Stats);

        expect(() => writeAgentVersionFile(runtimeData))
            .toThrow(i18n.t('agent_version_file_symbolic_link', { path: versionFile }));
    });

    it('reports an existing version directory as a write failure', () => {
        const runtimeData = createRuntimeData();
        const versionFile = join(runtimeData, 'version.json');
        mkdirSync(versionFile);

        expect(() => writeAgentVersionFile(runtimeData))
            .toThrow(i18n.t('agent_version_file_cannot_be_written', { path: versionFile }));
    });
});
