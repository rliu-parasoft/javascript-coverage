import { existsSync, linkSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import i18n from '../../src/i18n.js';
import { LoggerProvider } from '../../src/logging/logger.js';
import {
    CannotStopSessionInProgressError,
    CannotStopSessionNotStartedError,
    DEFAULT_USER_ID,
    SessionAlreadyStartedError,
    SessionService,
    UserIdNotFoundError
} from '../../src/session/session-service.js';

const unlinkFailure = vi.hoisted(() => ({ enabled: false }));
const writeFailure = vi.hoisted(() => ({ enabled: false, partial: false }));
const duringCoverageReset = vi.hoisted(() => ({ callback: undefined as (() => void) | undefined }));
vi.mock('node:fs', async (importOriginal) => {
    const actual = await importOriginal<typeof import('node:fs')>();
    const actualUnlinkSync = actual.unlinkSync;
    const actualWriteFileSync = actual.writeFileSync;
    return {
        ...actual,
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
            return actualWriteFileSync(...args);
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

describe('SessionService', () => {
    const temporaryRoots: string[] = [];
    let hadCoverage: boolean;
    let previousCoverage: Record<string, unknown> | undefined;

    beforeEach(() => {
        hadCoverage = Object.hasOwn(coverageGlobal, '__coverage__');
        previousCoverage = coverageGlobal.__coverage__;
        initializeLogger();
    });

    afterEach(async () => {
        unlinkFailure.enabled = false;
        writeFailure.enabled = false;
        writeFailure.partial = false;
        duringCoverageReset.callback = undefined;
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
