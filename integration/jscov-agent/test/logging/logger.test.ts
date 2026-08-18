import { mkdtempSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { LoggerProvider } from '../../src/logging/logger.js';

interface WinstonConsole extends Console {
    _stdout: NodeJS.WriteStream;
}

function findAgentLogFile(runtimeData: string): string {
    const [logFile] = readdirSync(runtimeData).filter((file) => /^agent-\d+-\d{10}\.log$/.test(file));
    if (!logFile) {
        throw new Error('Agent log file was not created.');
    }
    return join(runtimeData, logFile);
}
function makeConfig(runtimeData: string, overrides: { debug?: boolean; silentMode?: boolean } = {}) {
    return {
        settings: undefined as string | undefined,
        runtimeData,
        sessionAutostart: true,
        restServerEnabled: true,
        restServerPort: 8050,
        debug: overrides.debug ?? false,
        silentMode: overrides.silentMode ?? false
    };
}

describe('LoggerProvider', () => {
    const temporaryRoots: string[] = [];
    let runtimeData: string;

    beforeEach(() => {
        runtimeData = mkdtempSync(join(tmpdir(), 'jscov-logger-test-'));
        temporaryRoots.push(runtimeData);
    });

    afterEach(async () => {
        await LoggerProvider.close();
        temporaryRoots.splice(0).forEach((root) => rmSync(root, { recursive: true, force: true }));
    });

    it('requires initialization before file or console loggers are retrieved', () => {
        expect(() => LoggerProvider.file).toThrow('LoggerProvider has not been configured.');
        expect(() => LoggerProvider.console).toThrow('LoggerProvider has not been configured.');
    });

    it('rejects a second initialization and clears the singleton on close', async () => {
        LoggerProvider.initialize(makeConfig(runtimeData));
        expect(() => LoggerProvider.initialize(makeConfig(runtimeData))).toThrow('LoggerProvider has already been initialized.');

        await LoggerProvider.close();
        expect(() => LoggerProvider.file).toThrow('LoggerProvider has not been configured.');
    });

    it('provides independent file and console loggers after configuration', () => {
        LoggerProvider.initialize(makeConfig(runtimeData));
        expect(LoggerProvider.file).not.toBe(LoggerProvider.console);
        expect(LoggerProvider.file).toMatchObject({ debug: expect.any(Function), info: expect.any(Function) });
        expect(LoggerProvider.console).toMatchObject({ warn: expect.any(Function), error: expect.any(Function) });
    });

    it('writes only WARN and ERROR to the file when debug=false', async () => {
        LoggerProvider.initialize(makeConfig(runtimeData, { debug: false }));
        const logger = LoggerProvider.file;
        logger.debug('debug detail');
        logger.info('informational');
        logger.warn('warning detail');
        logger.error('failure');
        await LoggerProvider.close();

        const fileContents = readFileSync(findAgentLogFile(runtimeData), 'utf8');
        expect(fileContents).not.toContain('[JSCOV-AGENT][DEBUG]');
        expect(fileContents).not.toContain('[JSCOV-AGENT][INFO]');
        expect(fileContents).toContain('[JSCOV-AGENT][WARN]');
        expect(fileContents).toContain('[JSCOV-AGENT][ERROR]');
    });

    it('writes all levels to the file when debug=true', async () => {
        LoggerProvider.initialize(makeConfig(runtimeData, { debug: true }));
        const logger = LoggerProvider.file;
        logger.debug('debug detail');
        logger.info('informational');
        logger.warn('warning detail');
        logger.error('failure');
        await LoggerProvider.close();

        const fileContents = readFileSync(findAgentLogFile(runtimeData), 'utf8');
        expect(fileContents).toContain('[JSCOV-AGENT][DEBUG]');
        expect(fileContents).toContain('[JSCOV-AGENT][INFO]');
        expect(fileContents).toContain('[JSCOV-AGENT][WARN]');
        expect(fileContents).toContain('[JSCOV-AGENT][ERROR]');
    });

    it('writes an error stack trace to the file', async () => {
        LoggerProvider.initialize(makeConfig(runtimeData));
        LoggerProvider.file.error('operation failed:', new Error('stack failure'));
        await LoggerProvider.close();

        const fileContents = readFileSync(findAgentLogFile(runtimeData), 'utf8');
        expect(fileContents).toContain('operation failed: stack failure');
        expect(fileContents).toMatch(/\nError: stack failure\r?\n\s+at /);
    });

    it.each([false, true])('console shows INFO through ERROR regardless of debug=%s', async (debug) => {
        const writes: string[] = [];
        const stdout = (console as WinstonConsole)._stdout;
        const spy = vi.spyOn(stdout, 'write').mockImplementation((data: string | Uint8Array) => { writes.push(String(data)); return true; });
        try {
            LoggerProvider.initialize(makeConfig(runtimeData, { debug }));
            const logger = LoggerProvider.console;
            logger.debug('debug detail');
            logger.info('informational');
            logger.warn('warning detail');
            logger.error('failure');
            await LoggerProvider.close();

            const out = writes.join('');
            expect(out).not.toContain('[JSCOV-AGENT][DEBUG]');
            expect(out).toContain('[JSCOV-AGENT][INFO]: informational');
            expect(out).toContain('[JSCOV-AGENT][WARN]: warning detail');
            expect(out).toContain('[JSCOV-AGENT][ERROR]: failure');
        } finally {
            spy.mockRestore();
        }
    });

    it.each([
        [false, false],
        [true, false],
        [false, true],
        [true, true]
    ])('routes file, console, and banner output for debug=%s silentMode=%s', async (debug, silentMode) => {
        const writes: string[] = [];
        const stdout = (console as WinstonConsole)._stdout;
        const processStdoutSpy = vi.spyOn(process.stdout, 'write').mockImplementation((data: string | Uint8Array) => { writes.push(String(data)); return true; });
        const consoleStdoutSpy = vi.spyOn(stdout, 'write').mockImplementation((data: string | Uint8Array) => { writes.push(String(data)); return true; });
        try {
            LoggerProvider.initialize(makeConfig(runtimeData, { debug, silentMode }));
            LoggerProvider.writeBanner();
            LoggerProvider.file.debug('file debug');
            LoggerProvider.file.info('file info');
            LoggerProvider.file.warn('file warn');
            LoggerProvider.file.error('file error');
            LoggerProvider.console.debug('console debug');
            LoggerProvider.console.info('console info');
            LoggerProvider.console.warn('console warn');
            LoggerProvider.console.error('console error');
            await LoggerProvider.close();

            const logFiles = readdirSync(runtimeData).filter((file) => /^agent-\d{6}-\d{10}\.log$/.test(file));
            expect(logFiles).toHaveLength(1);
            const fileContents = readFileSync(join(runtimeData, logFiles[0]), 'utf8');
            const output = writes.join('');
            if (debug) {
                expect(fileContents).toContain('[JSCOV-AGENT][DEBUG]');
                expect(fileContents).toContain('file debug');
                expect(fileContents).toContain('[JSCOV-AGENT][INFO]');
                expect(fileContents).toContain('file info');
            } else {
                expect(fileContents).not.toContain('[JSCOV-AGENT][DEBUG]');
                expect(fileContents).not.toContain('[JSCOV-AGENT][INFO]');
            }
            expect(fileContents).toContain('[JSCOV-AGENT][WARN]');
            expect(fileContents).toContain('[JSCOV-AGENT][ERROR]');

            if (silentMode) {
                expect(output).toBe('');
            } else {
                expect(output).toContain('Initializing Parasoft JavaScript runtime coverage agent\n');
                expect(output).toContain('[JSCOV-AGENT][INFO]: console info');
                expect(output).toContain('[JSCOV-AGENT][WARN]: console warn');
                expect(output).toContain('[JSCOV-AGENT][ERROR]: console error');
                expect(output).not.toContain('[JSCOV-AGENT][DEBUG]');
            }
        } finally {
            processStdoutSpy.mockRestore();
            consoleStdoutSpy.mockRestore();
        }
    });

    it('suppresses console and writes file only when silentMode=true', async () => {
        const writes: string[] = [];
        const spy = vi.spyOn(process.stdout, 'write').mockImplementation((data) => { writes.push(String(data)); return true; });
        try {
            LoggerProvider.initialize(makeConfig(runtimeData, { debug: true, silentMode: true }));
            const logger = LoggerProvider.console;
            LoggerProvider.file.debug('debug detail');
            LoggerProvider.file.error('failure');
            logger.debug('debug detail');
            logger.error('failure');
            await LoggerProvider.close();

            expect(writes.join('')).not.toContain('[JSCOV-AGENT]');

            const fileContents = readFileSync(findAgentLogFile(runtimeData), 'utf8');
            expect(fileContents).toContain('[JSCOV-AGENT][DEBUG]');
            expect(fileContents).toContain('[JSCOV-AGENT][ERROR]');
        } finally {
            spy.mockRestore();
        }
    });

    it('writeBanner writes to stdout when silentMode=false', () => {
        const writes: string[] = [];
        const spy = vi.spyOn(process.stdout, 'write').mockImplementation((data) => { writes.push(String(data)); return true; });
        try {
            LoggerProvider.initialize(makeConfig(runtimeData, { silentMode: false }));
            LoggerProvider.writeBanner();
            expect(writes.join('')).toContain('Initializing Parasoft JavaScript runtime coverage agent\n');
        } finally {
            spy.mockRestore();
        }
    });

    it('writeBanner is suppressed when silentMode=true', () => {
        const writes: string[] = [];
        const spy = vi.spyOn(process.stdout, 'write').mockImplementation((data) => { writes.push(String(data)); return true; });
        try {
            LoggerProvider.initialize(makeConfig(runtimeData, { silentMode: true }));
            LoggerProvider.writeBanner();
            expect(writes.join('')).not.toContain('Initializing Parasoft JavaScript runtime coverage agent');
        } finally {
            spy.mockRestore();
        }
    });

    it('settles close when a logger emits an error', async () => {
        const fakeLogger = new EventEmitter() as EventEmitter & { end(): void };
        fakeLogger.end = () => fakeLogger.emit('error', new Error('simulated logger failure'));
        LoggerProvider.initialize(makeConfig(runtimeData, { silentMode: true }));
        const provider = LoggerProvider as unknown as {
            instance: {
                fileLogger: EventEmitter & { end(): void };
                consoleLogger: undefined;
            };
        };
        provider.instance.fileLogger = fakeLogger;
        provider.instance.consoleLogger = undefined;

        await expect(Promise.resolve().then(() => LoggerProvider.close())).resolves.toBeUndefined();
    });

    it('uses the Jtest-style 12-hour timestamp in file output', async () => {
        vi.useFakeTimers();
        vi.setSystemTime(new Date(2026, 7, 14, 13, 5, 6));
        try {
            LoggerProvider.initialize(makeConfig(runtimeData, { debug: true }));
            LoggerProvider.file.info('timestamp check');
            await LoggerProvider.close();

            const fileContents = readFileSync(findAgentLogFile(runtimeData), 'utf8');
            expect(fileContents).toContain('[JSCOV-AGENT][INFO][08-14 01:05:06]: timestamp check');
        } finally {
            vi.useRealTimers();
        }
    });

    it('uses the Jtest-style sequence and random suffix for log files', async () => {
        LoggerProvider.initialize(makeConfig(runtimeData, { debug: true }));
        LoggerProvider.file.info('new message');
        await LoggerProvider.close();

        const [logFile] = readdirSync(runtimeData).filter((file) => file.endsWith('.log'));
        expect(logFile).toMatch(/^agent-000001-\d{10}\.log$/);
        const newLog = readFileSync(join(runtimeData, logFile), 'utf8');
        expect(newLog).toMatch(/\[JSCOV-AGENT\]\[INFO].*new message/);
    });
});
