import { existsSync, linkSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import yauzl from 'yauzl';
import i18n from '../../src/i18n.js';
import { LoggerProvider } from '../../src/logging/logger.js';
import type { DeleteCoverageResponse } from '../../src/server/responses.js';
import {
    CannotStopSessionInProgressError,
    CannotStopSessionNotStartedError,
    DEFAULT_USER_ID,
    SessionAlreadyStartedError,
    SessionIdNotFoundError,
    SessionService,
    UserIdNotFoundError,
    VersionFileNotFoundError
} from '../../src/session/session-service.js';

const unlinkFailure = vi.hoisted(() => ({ enabled: false }));
const cleanupReadFailure = vi.hoisted(() => ({ enabled: false }));
const sessionFileStatFailure = vi.hoisted(() => ({ path: undefined as string | undefined }));
const unsafeSessionIdStatAttempt = vi.hoisted(() => ({ enabled: false }));
const writeFailure = vi.hoisted(() => ({ enabled: false, partial: false }));
const duringCoverageReset = vi.hoisted(() => ({ callback: undefined as (() => void) | undefined }));
const duringCoveragePersistence = vi.hoisted(() => ({ callback: undefined as (() => void) | undefined }));
vi.mock('node:fs', async (importOriginal) => {
    const actual = await importOriginal<typeof import('node:fs')>();
    const actualLstatSync = actual.lstatSync;
    const actualReaddirSync = actual.readdirSync;
    const actualUnlinkSync = actual.unlinkSync;
    const actualWriteFileSync = actual.writeFileSync;
    return {
        ...actual,
        lstatSync: (...args: Parameters<typeof actualLstatSync>) => {
            if (unsafeSessionIdStatAttempt.enabled) {
                throw new Error('unsafe session ID attempted filesystem stat');
            }
            if (sessionFileStatFailure.path === args[0]) {
                throw new Error('session file inspection failed');
            }
            return actualLstatSync(...args);
        },
        readdirSync: (...args: Parameters<typeof actualReaddirSync>) => {
            if (cleanupReadFailure.enabled) {
                throw new Error('cleanup inspection failed');
            }
            return actualReaddirSync(...args);
        },
        unlinkSync: (...args: Parameters<typeof actualUnlinkSync>) => {
            if (unlinkFailure.enabled) {
                throw new Error('cleanup failed');
            }
            return actualUnlinkSync(...args);
        },
        writeFileSync: (...args: Parameters<typeof actualWriteFileSync>) => {
            if (writeFailure.enabled && args[2] === 'utf8') {
                if (writeFailure.partial) {
                    actualWriteFileSync(args[0], '{', 'utf8');
                }
                throw new Error('write failed');
            }
            const result = actualWriteFileSync(...args);
            if (args[2] === 'utf8') {
                duringCoveragePersistence.callback?.();
            }
            return result;
        }
    };
});
vi.mock('../../src/coverage/runtime-coverage.js', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../src/coverage/runtime-coverage.js')>();
    return {
        ...actual,
        clearCoverageHits: () => {
            actual.clearCoverageHits();
            duringCoverageReset.callback?.();
        }
    };
});

const fixedDate = () => new Date(2026, 7, 7, 16, 3);
const coverageGlobal = globalThis as typeof globalThis & { __coverage__?: Record<string, unknown> };
const generatedSourceMapPath = 'C:\\project\\dist\\bundle.js';
const originalSourceMapPath = 'C:\\project\\src\\app.ts';

function mappedCoverage(inputSourceMap: object): Record<string, unknown> {
    const location = {
        start: { line: 1, column: 0 },
        end: { line: 1, column: 5 }
    };
    return {
        path: generatedSourceMapPath,
        statementMap: { '0': location },
        fnMap: { '0': { name: 'run', decl: location, loc: location } },
        branchMap: { '0': { type: 'if', line: 1, loc: location, locations: [location, location] } },
        s: { '0': 3 },
        f: { '0': 2 },
        b: { '0': [4, 5] },
        inputSourceMap
    };
}

interface ZipEntry {
    readonly name: string;
    readonly contents: string;
}

async function collectArchive(archive: ReturnType<SessionService['createSessionArchive']>): Promise<Buffer> {
    const chunks: Buffer[] = [];
    await new Promise<void>((resolve, reject) => {
        archive.output.on('error', reject);
        archive.output.on('data', (chunk: Buffer) => chunks.push(chunk));
        archive.output.on('end', resolve);
    });
    return Buffer.concat(chunks);
}

function readZip(buffer: Buffer): Promise<readonly ZipEntry[]> {
    return new Promise((resolve, reject) => {
        yauzl.fromBuffer(buffer, { lazyEntries: true }, (openError, zipFile) => {
            if (openError || !zipFile) {
                reject(openError ?? new Error('Expected ZIP file.'));
                return;
            }

            const entries: ZipEntry[] = [];
            zipFile.on('error', reject);
            zipFile.on('end', () => resolve(entries));
            zipFile.on('entry', (entry) => {
                zipFile.openReadStream(entry, (streamError, stream) => {
                    if (streamError || !stream) {
                        reject(streamError ?? new Error(`Expected stream for ${entry.fileName}.`));
                        return;
                    }

                    const chunks: Buffer[] = [];
                    stream.on('error', reject);
                    stream.on('data', (chunk: Buffer) => chunks.push(chunk));
                    stream.on('end', () => {
                        entries.push({ name: entry.fileName, contents: Buffer.concat(chunks).toString('utf8') });
                        zipFile.readEntry();
                    });
                });
            });
            zipFile.readEntry();
        });
    });
}

describe('SessionService', () => {
    const temporaryRoots: string[] = [];
    let hadCoverage: boolean;
    let previousCoverage: Record<string, unknown> | undefined;

    beforeEach(async () => {
        await i18n.changeLanguage('en');
        hadCoverage = Object.hasOwn(coverageGlobal, '__coverage__');
        previousCoverage = coverageGlobal.__coverage__;
        initializeLogger();
    });

    afterEach(async () => {
        unlinkFailure.enabled = false;
        cleanupReadFailure.enabled = false;
        sessionFileStatFailure.path = undefined;
        unsafeSessionIdStatAttempt.enabled = false;
        writeFailure.enabled = false;
        writeFailure.partial = false;
        duringCoverageReset.callback = undefined;
        duringCoveragePersistence.callback = undefined;
        await LoggerProvider.close();
        temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true }));
        if (hadCoverage) {
            coverageGlobal.__coverage__ = previousCoverage;
        } else {
            delete coverageGlobal.__coverage__;
        }
    });

    function createRuntimeData(): string {
        const runtimeData = mkdtempSync(join(tmpdir(), 'jscov-agent-session-'));
        temporaryRoots.push(runtimeData);
        return runtimeData;
    }

    function initializeLogger(debug = true): void {
        const runtimeData = createRuntimeData();
        LoggerProvider.initialize({
            settings: undefined,
            runtimeData,
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 8050,
            debug,
            silentMode: true
        });
    }

    it('lists sorted direct coverage file names without their final extensions', () => {
        const runtimeData = createRuntimeData();
        const userDirectory = join(runtimeData, DEFAULT_USER_ID);
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        mkdirSync(join(userDirectory, 'nested'), { recursive: true });
        writeFileSync(join(userDirectory, 'zeta.json'), '{}');
        writeFileSync(join(userDirectory, 'beta.json'), '{}');
        writeFileSync(join(userDirectory, 'alpha.json'), '{}');

        expect(service.getLocalSessionNames()).toEqual(['alpha', 'beta', sessionId, 'zeta']);
    });

    it('returns an empty list for an empty default-user directory', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });
        mkdirSync(join(runtimeData, DEFAULT_USER_ID));

        expect(service.getLocalSessionNames()).toEqual([]);
    });

    it('uses the provided message for a user-not-found error', () => {
        expect(new UserIdNotFoundError('provided message').message).toBe('provided message');
    });

    it('exports archive route-contract errors from the session service', () => {
        expect(SessionIdNotFoundError).toBeDefined();
        expect(VersionFileNotFoundError).toBeDefined();
    });

    it('reports an unknown user when getting local session names before a session starts', () => {
        const service = new SessionService(createRuntimeData(), fixedDate);

        let thrown: unknown;
        try {
            service.getLocalSessionNames();
        } catch (error) {
            thrown = error;
        }

        expect(thrown).toBeInstanceOf(UserIdNotFoundError);
        expect((thrown as Error).message).toBe(i18n.t('coverage_user_not_found', { userId: DEFAULT_USER_ID }));
    });

    it('reports an unknown user when the local session directory is deleted', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });

        let thrown: unknown;
        try {
            service.getLocalSessionNames();
        } catch (error) {
            thrown = error;
        }

        expect(thrown).toBeInstanceOf(UserIdNotFoundError);
        expect((thrown as Error).message).toBe(i18n.t('coverage_user_not_found', { userId: DEFAULT_USER_ID }));
    });

    it('rejects a default-user directory that is a symbolic link', () => {
        const runtimeData = createRuntimeData();
        const outsideRuntimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });
        symlinkSync(outsideRuntimeData, join(runtimeData, DEFAULT_USER_ID), 'junction');

        expect(() => service.getLocalSessionNames())
            .toThrow(i18n.t('session_user_id_symbolic_link', { userId: DEFAULT_USER_ID }));
    });

    it('rejects creating a session archive when the default-user directory is a symbolic link', () => {
        const runtimeData = createRuntimeData();
        const outsideRuntimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });
        symlinkSync(outsideRuntimeData, join(runtimeData, DEFAULT_USER_ID), 'junction');

        expect(() => service.createSessionArchive(sessionId))
            .toThrow(i18n.t('session_user_id_symbolic_link', { userId: DEFAULT_USER_ID }));
    });

    it('packages only the requested session and version file in the runtime-data layout', async () => {
        const root = createRuntimeData();
        const runtimeData = join(root, 'jscov-coverage-runtime');
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        writeFileSync(join(runtimeData, 'version.json'), '{"schemaVersion":"1.0"}\n');
        writeFileSync(join(runtimeData, 'agent-000001.log'), 'agent diagnostic');
        writeFileSync(join(runtimeData, DEFAULT_USER_ID, 'runtime_coverage_20260826_1201_0.json'), '{"/other.js":{}}');

        const archive = service.createSessionArchive(sessionId);
        expect(archive.filename).toBe(`${sessionId}.zip`);

        const entries = await readZip(await collectArchive(archive));

        expect(entries).toEqual([
            { name: 'jscov-coverage-runtime/version.json', contents: '{"schemaVersion":"1.0"}\n' },
            { name: `jscov-coverage-runtime/__default__/${sessionId}.json`, contents: '{}' }
        ]);
        expect(entries.map((entry) => entry.name)).not.toContain('jscov-coverage-runtime/agent-000001.log');
        expect(entries.map((entry) => entry.name)).not.toContain('jscov-coverage-runtime/__default__/runtime_coverage_20260826_1201_0.json');
    });

    it('reports missing and traversal-shaped session IDs without reading outside the user directory', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        writeFileSync(join(runtimeData, 'version.json'), '{}');
        const missingSessionId = 'runtime_coverage_20260826_1201_0';

        expect(() => service.createSessionArchive(missingSessionId)).toThrowError(
            i18n.t('coverage_session_not_found', { sessionId: missingSessionId })
        );
        expect(() => service.createSessionArchive(missingSessionId)).toThrow(SessionIdNotFoundError);
        expect(() => service.createSessionArchive('../outside-session')).toThrow(SessionIdNotFoundError);
    });

    it('rejects a requested session file that is a symbolic link', () => {
        const runtimeData = createRuntimeData();
        const linkedDirectory = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        writeFileSync(join(runtimeData, 'version.json'), '{}');
        rmSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`));
        symlinkSync(linkedDirectory, join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'junction');

        expect(() => service.createSessionArchive(sessionId)).toThrowError(
            i18n.t('session_file_symbolic_link', { session: sessionId, userId: DEFAULT_USER_ID })
        );
    });

    it('reports an archive read error when a session file disappears after validation', async () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const sessionFile = join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`);
        writeFileSync(join(runtimeData, 'version.json'), '{}');
        const archive = service.createSessionArchive(sessionId);
        const error = new Promise<unknown>((resolve) => archive.errorSource.once('error', resolve));

        rmSync(sessionFile);

        await expect(error).resolves.toMatchObject({ code: 'ENOENT' });
    });

    it('reports a missing version file with its resolved absolute path', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();

        expect(() => service.createSessionArchive(sessionId)).toThrowError(
            i18n.t('version_file_not_found', { path: join(runtimeData, 'version.json') })
        );
        expect(() => service.createSessionArchive(sessionId)).toThrow(VersionFileNotFoundError);
    });

    it('treats a version-file directory as missing', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        mkdirSync(join(runtimeData, 'version.json'));

        expect(() => service.createSessionArchive(sessionId)).toThrowError(
            i18n.t('version_file_not_found', { path: join(runtimeData, 'version.json') })
        );
        expect(() => service.createSessionArchive(sessionId)).toThrow(VersionFileNotFoundError);
    });

    it('treats a requested session directory as missing', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        const sessionFile = join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`);
        rmSync(sessionFile);
        mkdirSync(sessionFile);
        writeFileSync(join(runtimeData, 'version.json'), '{}');

        expect(() => service.createSessionArchive(sessionId)).toThrowError(
            i18n.t('coverage_session_not_found', { sessionId })
        );
        expect(() => service.createSessionArchive(sessionId)).toThrow(SessionIdNotFoundError);
    });
    it('rejects a version file that is a symbolic link', () => {
        const runtimeData = createRuntimeData();
        const linkedDirectory = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        symlinkSync(linkedDirectory, join(runtimeData, 'version.json'), 'junction');

        expect(() => service.createSessionArchive(sessionId)).toThrowError(
            i18n.t('agent_version_file_symbolic_link', { path: join(runtimeData, 'version.json') })
        );
    });

    it('reports a registered user whose directory was deleted while creating an archive', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });

        expect(() => service.createSessionArchive(sessionId)).toThrowError(
            i18n.t('coverage_user_not_found', { userId: DEFAULT_USER_ID })
        );
        expect(() => service.createSessionArchive(sessionId)).toThrow(UserIdNotFoundError);
    });

    it('clears supported Istanbul hit counters', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        coverageGlobal.__coverage__ = {
            '/app.js': {
                s: { '0': 3 },
                f: { '0': 2 },
                b: { '0': [4, 5] },
                bT: { '0': [6, 7] },
                statementMap: { '0': { start: { line: 1 } } }
            }
        };

        const sessionFile = join(runtimeData, DEFAULT_USER_ID, 'runtime_coverage_20260807_1603_0.json');
        expect(service.startSession()).toBe('runtime_coverage_20260807_1603_0');
        expect(existsSync(sessionFile)).toBe(true);
        expect(JSON.parse(readFileSync(sessionFile, 'utf8'))).toEqual({});
        expect(coverageGlobal.__coverage__?.['/app.js']).toMatchObject({ s: { '0': 0 }, f: { '0': 0 }, b: { '0': [0, 0] }, bT: { '0': [6, 7] } });
    });

    it('skips a persisted filename collision', () => {
        const runtimeData = createRuntimeData();
        mkdirSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });
        writeFileSync(join(runtimeData, DEFAULT_USER_ID, 'runtime_coverage_20260807_1603_0.json'), '{}');

        expect(new SessionService(runtimeData, fixedDate).startSession()).toBe('runtime_coverage_20260807_1603_1');
    });

    it('rejects a second start for an active user without creating another file', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();

        expect(() => service.startSession()).toThrow(SessionAlreadyStartedError);
        expect(readdirSync(join(runtimeData, DEFAULT_USER_ID))).toHaveLength(1);
    });

    it('releases a user reservation when session-file preparation fails', () => {
        const runtimeData = createRuntimeData();
        const userDirectory = join(runtimeData, DEFAULT_USER_ID);
        writeFileSync(userDirectory, 'blocked');
        const service = new SessionService(runtimeData, fixedDate);

        expect(() => service.startSession()).toThrow();
        rmSync(userDirectory);

        expect(service.startSession()).toBe('runtime_coverage_20260807_1603_0');
    });

    it('rejects a user ID that escapes the runtime data directory', () => {
        const runtimeData = createRuntimeData();
        const escapedDirectoryName = `jscov-agent-escaped-${Date.now()}-${Math.random()}`;
        const escapedDirectory = join(runtimeData, '..', escapedDirectoryName);
        temporaryRoots.push(escapedDirectory);

        expect(() => new SessionService(runtimeData, fixedDate).startSession(`../${escapedDirectoryName}`)).toThrow();
        expect(existsSync(escapedDirectory)).toBe(false);
    });

    it('rejects a user directory that is a symlink outside runtime data', () => {
        const runtimeData = createRuntimeData();
        const outsideRuntimeData = createRuntimeData();
        symlinkSync(outsideRuntimeData, join(runtimeData, 'linked-user'), 'junction');

        expect(() => new SessionService(runtimeData, fixedDate).startSession('linked-user')).toThrow();
        expect(readdirSync(outsideRuntimeData)).toHaveLength(0);
    });

    it('removes a reserved file when clearing coverage hits fails', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionFile = join(runtimeData, DEFAULT_USER_ID, 'runtime_coverage_20260807_1603_0.json');
        coverageGlobal.__coverage__ = { '/app.js': { s: Object.freeze({ '0': 3 }) } };

        expect(() => service.startSession()).toThrow(TypeError);
        expect(existsSync(sessionFile)).toBe(false);

        coverageGlobal.__coverage__ = undefined;
        expect(service.startSession()).toBe('runtime_coverage_20260807_1603_0');
    });

    it('preserves the reset failure when reservation cleanup fails', () => {
        const runtimeData = createRuntimeData();
        const log = vi.spyOn(LoggerProvider.file, 'debug');
        const service = new SessionService(runtimeData, fixedDate);
        coverageGlobal.__coverage__ = { '/app.js': { s: Object.freeze({ '0': 3 }) } };
        unlinkFailure.enabled = true;

        let thrown: unknown;
        try {
            service.startSession();
        } catch (error) {
            thrown = error;
        }

        expect(thrown).toBeInstanceOf(TypeError);
        expect((thrown as Error).message).toMatch(/Cannot assign to read only property/);
        expect((thrown as Error).message).not.toBe('cleanup failed');
        expect(log).toHaveBeenCalledWith(
            i18n.t('session_reservation_cleanup_failed_diagnostic', {
                error: 'cleanup failed',
                sessionFilePath: join(runtimeData, DEFAULT_USER_ID, 'runtime_coverage_20260807_1603_0.json')
            })
        );
    });

    it('persists coverage before closing the active session', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        coverageGlobal.__coverage__ = { '/app.js': { s: { '0': 3 }, f: { '0': 2 }, b: { '0': [4, 5] } } };

        expect(service.stopSession()).toBe(sessionId);
        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8')))
            .toEqual({ '/app.js': { s: { '0': 3 }, f: { '0': 2 }, b: { '0': [4, 5] } } });
        expect(service.startSession()).toBe('runtime_coverage_20260807_1603_1');
    });

    it('remaps coverage before persisting the stopped session', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        coverageGlobal.__coverage__ = {
            [generatedSourceMapPath]: mappedCoverage({
                version: 3,
                file: generatedSourceMapPath,
                sources: [originalSourceMapPath],
                names: [],
                mappings: 'AAAA'
            })
        };

        service.stopSession();

        const persisted = JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8'));
        expect(persisted[originalSourceMapPath]).toMatchObject({
            path: originalSourceMapPath,
            statementMap: { '0': { start: { line: 1, column: 0 } } },
            fnMap: { '0': { loc: { start: { line: 1, column: 0 } } } },
            s: { '0': 3 },
            f: { '0': 2 },
            b: { '0': [4, 5] }
        });
        expect(persisted[originalSourceMapPath].branchMap['0'].locations[0].start)
            .toEqual({ line: 1, column: 0 });
        expect(persisted[originalSourceMapPath]).not.toHaveProperty('inputSourceMap');
        expect(persisted).not.toHaveProperty(generatedSourceMapPath);
    });

    it('keeps generated coverage when the source map cannot be applied', () => {
        const runtimeData = createRuntimeData();
        const log = vi.spyOn(LoggerProvider.file, 'warn');
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const coverage = mappedCoverage({ version: 3, mappings: 'not-valid' });
        coverageGlobal.__coverage__ = { [generatedSourceMapPath]: coverage };

        service.stopSession();

        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8')))
            .toEqual({ [generatedSourceMapPath]: coverage });
        expect(log).toHaveBeenCalledWith(expect.stringContaining(i18n.t('coverage_remap_failed_with_path_diagnostic', {
            path: generatedSourceMapPath,
            error: ''
        }).trimEnd()));
    });

    it('logs and preserves generated coverage when a valid source map has no mappings', () => {
        const runtimeData = createRuntimeData();
        const log = vi.spyOn(LoggerProvider.file, 'warn');
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const coverage = mappedCoverage({
            version: 3,
            file: generatedSourceMapPath,
            sources: [originalSourceMapPath],
            names: [],
            mappings: ''
        });
        coverageGlobal.__coverage__ = { [generatedSourceMapPath]: coverage };

        service.stopSession();

        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8')))
            .toEqual({ [generatedSourceMapPath]: coverage });
        expect(log).toHaveBeenCalledWith(i18n.t('coverage_remap_failed_with_path_diagnostic', {
            path: generatedSourceMapPath,
            error: i18n.t('coverage_remap_no_entries_diagnostic')
        }));
    });

    it('logs and preserves generated coverage when a mapped position has a null column', () => {
        const runtimeData = createRuntimeData();
        const log = vi.spyOn(LoggerProvider.file, 'warn');
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const coverage = mappedCoverage({
            version: 3,
            file: generatedSourceMapPath,
            sources: [originalSourceMapPath],
            names: [],
            mappings: 'AAAA'
        });
        const statementMap = coverage.statementMap as {
            '0': { start: { column: number | null } };
        };
        statementMap['0'].start.column = null;
        coverageGlobal.__coverage__ = { [generatedSourceMapPath]: coverage };

        service.stopSession();

        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8')))
            .toEqual({ [generatedSourceMapPath]: coverage });
        expect(log).toHaveBeenCalledWith(expect.stringContaining(i18n.t('coverage_remap_failed_with_path_diagnostic', {
            path: generatedSourceMapPath,
            error: ''
        }).trimEnd()));
    });

    it('deletes a finished session and unregisters its final user', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();

        expect(service.deleteCoverageSession(sessionId)).toEqual({ skipped: [], deleted: [sessionId] });
        expect(existsSync(join(runtimeData, DEFAULT_USER_ID))).toBe(false);
        expect(() => service.stopSession()).toThrow(UserIdNotFoundError);
    });

    it('deletes all persisted coverage sessions and skips the active session', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const completedSessionId = service.startSession();
        service.stopSession();
        const activeSessionId = service.startSession();

        expect(service.deleteAllCoverageSessions()).toEqual({
            skipped: [{
                id: activeSessionId,
                messageCode: 300,
                reason: i18n.t('coverage_delete_session_in_progress')
            }],
            deleted: [completedSessionId]
        });
    });

    it('retains unrelated JSON files while deleting all coverage sessions', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        const unrelatedFile = join(runtimeData, DEFAULT_USER_ID, 'metadata.json');
        writeFileSync(unrelatedFile, '{}');
        const log = vi.spyOn(LoggerProvider.file, 'debug');

        expect(service.deleteAllCoverageSessions()).toEqual({ skipped: [], deleted: [sessionId] });
        expect(existsSync(unrelatedFile)).toBe(true);
        expect(() => service.stopSession()).toThrow(UserIdNotFoundError);
        expect(log).toHaveBeenCalledTimes(1);
        expect(log).toHaveBeenCalledWith(i18n.t('coverage_delete_session_removed_diagnostic', {
            session: sessionId,
            userId: DEFAULT_USER_ID
        }));
    });

    it('unregisters a user whose final session is deleted while unrelated files remain', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        const unrelatedFile = join(runtimeData, DEFAULT_USER_ID, 'metadata.json');
        writeFileSync(unrelatedFile, '{}');

        expect(service.deleteCoverageSession(sessionId)).toEqual({ skipped: [], deleted: [sessionId] });
        expect(existsSync(unrelatedFile)).toBe(true);
        expect(() => service.stopSession()).toThrow(UserIdNotFoundError);
    });

    it('unregisters an already-empty user during collection deletion', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`));

        expect(service.deleteAllCoverageSessions()).toEqual({ skipped: [], deleted: [] });
        expect(existsSync(join(runtimeData, DEFAULT_USER_ID))).toBe(false);
        expect(() => service.stopSession()).toThrow(UserIdNotFoundError);
    });

    it('returns skipped code 301 when deleting a starting session', () => {
        const service = new SessionService(createRuntimeData(), fixedDate);
        let response: DeleteCoverageResponse | undefined;
        duringCoverageReset.callback = () => {
            response = service.deleteCoverageSession('runtime_coverage_20260807_1603_0');
        };

        service.startSession();

        expect(Object.keys(response!)).toEqual(['skipped', 'deleted']);
        expect(response).toEqual({
            deleted: [],
            skipped: [{
                id: 'runtime_coverage_20260807_1603_0',
                messageCode: 301,
                reason: i18n.t('coverage_delete_session_in_progress')
            }]
        });
    });

    it('returns skipped code 301 when deleting an active session', () => {
        const service = new SessionService(createRuntimeData(), fixedDate);
        const sessionId = service.startSession();
        const response = service.deleteCoverageSession(sessionId);

        expect(Object.keys(response)).toEqual(['skipped', 'deleted']);
        expect(response).toEqual({
            deleted: [],
            skipped: [{
                id: sessionId,
                messageCode: 301,
                reason: i18n.t('coverage_delete_session_in_progress')
            }]
        });
    });

    it('returns skipped code 350 when a finished session file does not exist', () => {
        const service = new SessionService(createRuntimeData(), fixedDate);
        service.startSession();
        service.stopSession();

        expect(service.deleteCoverageSession('runtime_coverage_20260807_1603_1')).toEqual({
            deleted: [],
            skipped: [{
                id: 'runtime_coverage_20260807_1603_1',
                messageCode: 350,
                reason: i18n.t('coverage_delete_session_not_found')
            }]
        });
    });

    it('reports an unknown user while deleting coverage', () => {
        const service = new SessionService(createRuntimeData(), fixedDate);

        expect(() => service.deleteCoverageSession('runtime_coverage_20260807_1603_0', 'unknown-user'))
            .toThrow(UserIdNotFoundError);
    });

    it('reports a user whose runtime directory was externally removed while deleting coverage', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        service.stopSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });

        expect(() => service.deleteCoverageSession('runtime_coverage_20260807_1603_0'))
            .toThrow(UserIdNotFoundError);
    });

    it('returns skipped code 303 when removing a finished session file fails', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        unlinkFailure.enabled = true;

        expect(service.deleteCoverageSession(sessionId)).toEqual({
            deleted: [],
            skipped: [{
                id: sessionId,
                messageCode: 303,
                reason: i18n.t('coverage_delete_session_remove_failed', {
                    sessionFilePath: join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`)
                })
            }]
        });
    });

    it('returns skipped code 302 when removing a persisted session during collection deletion fails', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        unlinkFailure.enabled = true;

        expect(service.deleteAllCoverageSessions()).toEqual({
            deleted: [],
            skipped: [{
                id: sessionId,
                messageCode: 302,
                reason: i18n.t('coverage_delete_session_remove_failed', {
                    sessionFilePath: join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`)
                })
            }]
        });
    });

    it('returns skipped code 303 when inspecting a finished session file fails', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        const sessionFilePath = join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`);
        const log = vi.spyOn(LoggerProvider.file, 'debug');
        sessionFileStatFailure.path = sessionFilePath;

        expect(service.deleteCoverageSession(sessionId)).toEqual({
            skipped: [{
                id: sessionId,
                messageCode: 303,
                reason: i18n.t('coverage_delete_session_remove_failed', { sessionFilePath })
            }],
            deleted: []
        });
        expect(log).toHaveBeenCalledWith(i18n.t('coverage_delete_session_remove_failed_diagnostic', {
            error: 'session file inspection failed',
            session: sessionId,
            sessionFilePath,
            userId: DEFAULT_USER_ID
        }));
    });

    it('retains a completed session file while another session is active', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const completedSessionId = service.startSession();
        service.stopSession();
        const activeSessionId = service.startSession();

        expect(service.deleteCoverageSession(completedSessionId)).toEqual({
            deleted: [completedSessionId],
            skipped: []
        });
        expect(existsSync(join(runtimeData, DEFAULT_USER_ID, `${activeSessionId}.json`))).toBe(true);
        expect(service.getActiveSession()).toBe(activeSessionId);
    });

    it('does not delete a file outside the user directory when the session ID traverses', () => {
        const runtimeData = createRuntimeData();
        const sentinelFilePath = join(runtimeData, 'outside.json');
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        service.stopSession();
        writeFileSync(sentinelFilePath, '{"preserve":true}');
        unsafeSessionIdStatAttempt.enabled = true;

        expect(service.deleteCoverageSession('../outside')).toEqual({
            deleted: [],
            skipped: [{
                id: '../outside',
                messageCode: 350,
                reason: i18n.t('coverage_delete_session_not_found')
            }]
        });
        expect(readFileSync(sentinelFilePath, 'utf8')).toBe('{"preserve":true}');
    });

    it('does not delete a non-session JSON file requested as a coverage session', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        service.stopSession();
        const unrelatedFile = join(runtimeData, DEFAULT_USER_ID, 'metadata.json');
        writeFileSync(unrelatedFile, '{}');
        unsafeSessionIdStatAttempt.enabled = true;
        const response = service.deleteCoverageSession('metadata');

        expect(Object.keys(response)).toEqual(['skipped', 'deleted']);
        expect(response).toEqual({
            deleted: [],
            skipped: [{
                id: 'metadata',
                messageCode: 350,
                reason: i18n.t('coverage_delete_session_not_found')
            }]
        });
        expect(readFileSync(unrelatedFile, 'utf8')).toBe('{}');
    });

    it('rejects a NUL session ID before filesystem access', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        service.stopSession();
        unsafeSessionIdStatAttempt.enabled = true;
        const sessionId = 'runtime_coverage_20260807_1603_0\0invalid';

        expect(service.deleteCoverageSession(sessionId)).toEqual({
            deleted: [],
            skipped: [{
                id: sessionId,
                messageCode: 350,
                reason: i18n.t('coverage_delete_session_not_found')
            }]
        });
    });

    it('preserves a successful delete when user cleanup inspection fails', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        service.stopSession();
        const log = vi.spyOn(LoggerProvider.file, 'debug');
        cleanupReadFailure.enabled = true;

        expect(service.deleteCoverageSession(sessionId)).toEqual({ deleted: [sessionId], skipped: [] });
        expect(existsSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`))).toBe(false);
        expect(() => service.stopSession()).toThrow(CannotStopSessionNotStartedError);
        expect(log).toHaveBeenCalledWith(i18n.t('coverage_delete_user_cleanup_failed_diagnostic', {
            error: 'cleanup inspection failed',
            userDirectory: join(runtimeData, DEFAULT_USER_ID),
            userId: DEFAULT_USER_ID
        }));
    });

    it('returns skipped code 301 and keeps the file while a session is stopping', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        let response: DeleteCoverageResponse | undefined;
        duringCoveragePersistence.callback = () => {
            response = service.deleteCoverageSession(sessionId);
        };

        service.stopSession();

        expect(response).toEqual({
            deleted: [],
            skipped: [{
                id: sessionId,
                messageCode: 301,
                reason: i18n.t('coverage_delete_session_in_progress')
            }]
        });
        expect(existsSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`))).toBe(true);
    });

    it('logs a missing session file and recreates it while stopping', () => {
        const runtimeData = createRuntimeData();
        const log = vi.spyOn(LoggerProvider.file, 'debug');
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`));

        service.stopSession();

        expect(log).toHaveBeenCalledWith(i18n.t('session_file_missing_diagnostic', {
            sessionFilePath: join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`)
        }));
        expect(log).toHaveBeenCalledWith(expect.stringContaining(DEFAULT_USER_ID));
        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8'))).toEqual({});
    });

    it('recreates a removed user directory before writing coverage', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        rmSync(join(runtimeData, DEFAULT_USER_ID), { recursive: true });
        coverageGlobal.__coverage__ = { '/app.js': { s: { '0': 3 } } };

        service.stopSession();

        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8')))
            .toEqual({ '/app.js': { s: { '0': 3 } } });
    });

    it('keeps the session active when coverage persistence fails', () => {
        const runtimeData = createRuntimeData();
        const log = vi.spyOn(LoggerProvider.file, 'error');
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        writeFailure.enabled = true;

        expect(() => service.stopSession()).toThrow('write failed');
        writeFailure.enabled = false;
        expect(() => service.startSession()).toThrow(SessionAlreadyStartedError);
        expect(log).toHaveBeenCalledWith(i18n.t('session_write_failed_diagnostic', {
            sessionFilePath: join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`)
        }), expect.any(Error));
        expect(log).toHaveBeenCalledWith(expect.stringContaining(DEFAULT_USER_ID), expect.any(Error));
        expect(service.stopSession()).toBe('runtime_coverage_20260807_1603_0');
    });

    it('uses the reserved session ID for a concurrent start response', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        let duplicateStartError: unknown;
        duringCoverageReset.callback = () => {
            try {
                service.startSession();
            } catch (error) {
                duplicateStartError = error;
            }
        };

        const sessionId = service.startSession();

        expect(duplicateStartError).toBeInstanceOf(SessionAlreadyStartedError);
        expect((duplicateStartError as SessionAlreadyStartedError).message)
            .toBe(i18n.t('session_already_started', { session: sessionId, userId: DEFAULT_USER_ID }));
    });

    it('uses the not-started response message while a session is stopping', () => {
        expect(new CannotStopSessionInProgressError(DEFAULT_USER_ID, 'runtime_coverage_20260807_1603_0').message)
            .toBe(i18n.t('session_not_started', { userId: DEFAULT_USER_ID }));
    });

    it('preserves the valid reserved session file when coverage persistence writes partially', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const sessionDirectory = join(runtimeData, DEFAULT_USER_ID);
        writeFailure.enabled = true;
        writeFailure.partial = true;

        expect(() => service.stopSession()).toThrow('write failed');
        expect(JSON.parse(readFileSync(join(sessionDirectory, `${sessionId}.json`), 'utf8'))).toEqual({});
        expect(readdirSync(sessionDirectory)).not.toContain(expect.stringMatching(/\.tmp$/));
    });

    it('reports an unknown user when stopping a session that was never started', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);

        let thrown: unknown;
        try {
            service.stopSession();
        } catch (error) {
            thrown = error;
        }

        expect((thrown as Error).message).toBe(i18n.t('session_user_not_found', { userId: DEFAULT_USER_ID }));
        expect(thrown).toBeInstanceOf(UserIdNotFoundError);
    });

    it('reports that a known user has no active session after it is stopped', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession();
        service.stopSession();

        expect(() => service.stopSession()).toThrow(CannotStopSessionNotStartedError);
    });

    it('tracks known users independently when stopping sessions', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession('known-user');
        service.stopSession('known-user');

        expect(() => service.stopSession('known-user')).toThrow(CannotStopSessionNotStartedError);
        expect(() => service.stopSession('unknown-user')).toThrow(UserIdNotFoundError);
    });

    it('persists an empty object when runtime coverage is malformed', () => {
        const runtimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        // The runtime global is deliberately malformed here to verify the persistence fallback.
        coverageGlobal.__coverage__ = [] as unknown as Record<string, unknown>;

        service.stopSession();

        expect(JSON.parse(readFileSync(join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`), 'utf8'))).toEqual({});
    });

    it('rejects stopping when an active user directory is replaced by a symlink', () => {
        const runtimeData = createRuntimeData();
        const outsideRuntimeData = createRuntimeData();
        const userId = 'linked-user';
        const userDirectory = join(runtimeData, userId);
        const service = new SessionService(runtimeData, fixedDate);
        service.startSession(userId);
        rmSync(userDirectory, { recursive: true });
        symlinkSync(outsideRuntimeData, userDirectory, 'junction');

        expect(() => service.stopSession(userId)).toThrow(i18n.t('session_user_id_symbolic_link', { userId }));
        expect(readdirSync(outsideRuntimeData)).toHaveLength(0);
    });

    it('rejects stopping when the session file is replaced by a broken symbolic link', () => {
        const runtimeData = createRuntimeData();
        const outsideRuntimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const filePath = join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`);
        const linkTarget = join(outsideRuntimeData, 'deleted-target');
        mkdirSync(linkTarget);
        rmSync(filePath);
        symlinkSync(linkTarget, filePath, 'junction');
        rmSync(linkTarget, { recursive: true });

        expect(() => service.stopSession()).toThrow(i18n.t('session_file_symbolic_link', {
            session: sessionId,
            userId: DEFAULT_USER_ID
        }));
    });

    it('replaces a session-file hard link without modifying its linked target', () => {
        const runtimeData = createRuntimeData();
        const outsideRuntimeData = createRuntimeData();
        const service = new SessionService(runtimeData, fixedDate);
        const sessionId = service.startSession();
        const sessionFile = join(runtimeData, DEFAULT_USER_ID, `${sessionId}.json`);
        const linkedTarget = join(outsideRuntimeData, 'linked-target.json');
        writeFileSync(linkedTarget, '{"preserve":true}');
        rmSync(sessionFile);
        linkSync(linkedTarget, sessionFile);
        coverageGlobal.__coverage__ = { '/app.js': { s: { '0': 3 } } };

        service.stopSession();

        expect(JSON.parse(readFileSync(linkedTarget, 'utf8'))).toEqual({ preserve: true });
        expect(JSON.parse(readFileSync(sessionFile, 'utf8'))).toEqual({ '/app.js': { s: { '0': 3 } } });
    });
});
