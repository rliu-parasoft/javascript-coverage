import { existsSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { LoggerProvider } from '../../src/logging/logger.js';
import { DEFAULT_USER_ID, SessionAlreadyStartedError, SessionService } from '../../src/session/session-service.js';

const unlinkFailure = vi.hoisted(() => ({ enabled: false }));
vi.mock('node:fs', async (importOriginal) => {
    const actual = await importOriginal<typeof import('node:fs')>();
    const actualUnlinkSync = actual.unlinkSync;
    return {
        ...actual,
        unlinkSync: (...args: Parameters<typeof actualUnlinkSync>) => {
            if (unlinkFailure.enabled) {
                throw new Error('cleanup failed');
            }
            return actualUnlinkSync(...args);
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
        expect(log).toHaveBeenCalledWith('Failed to clean up session reservation: cleanup failed');
    });
});
