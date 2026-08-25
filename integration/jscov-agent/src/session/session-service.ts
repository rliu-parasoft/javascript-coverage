import { closeSync, lstatSync, mkdirSync, openSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { isAbsolute, join, relative, resolve, sep } from 'node:path';
import { clearCoverageHits, getCoverage } from '../coverage/runtime-coverage.js';
import i18n from '../i18n.js';
import { LoggerProvider } from '../logging/logger.js';
import { errorMessage } from '../utils.js';

export const DEFAULT_USER_ID = '__default__';

export class SessionAlreadyStartedError extends Error {
    readonly sessionId: string;

    constructor(userId: string, sessionId: string) {
        super(i18n.t('session_already_started', { session: sessionId, userId }));
        this.sessionId = sessionId;
    }
}

export class UserIdNotFoundError extends Error {
    constructor(userId: string) {
        super(i18n.t('session_user_not_found', { userId }));
    }
}

export class CannotStopSessionNotStartedError extends Error {
    constructor(userId: string) {
        super(i18n.t('session_not_started', { userId }));
    }
}

export class CannotStopSessionInProgressError extends Error {
    readonly sessionId: string;

    constructor(userId: string, sessionId: string) {
        super(i18n.t('session_not_started', { userId }));
        this.sessionId = sessionId;
    }
}

export class SessionService {
    private readonly activeSessionForUsers = new Map<string, string>();
    private readonly knownUsers = new Set<string>();
    private readonly startingSessionForUsers = new Map<string, string>();
    private readonly stoppingUsers = new Set<string>();

    constructor(
        private readonly runtimeData: string,
        private readonly now: () => Date = () => new Date()
    ) {}

    getActiveSession(userId = DEFAULT_USER_ID): string | undefined {
        return this.activeSessionForUsers.get(userId);
    }

    startSession(userId = DEFAULT_USER_ID): string {
        const activeSession = this.activeSessionForUsers.get(userId);
        const startingSession = this.startingSessionForUsers.get(userId);
        const sessionId = activeSession ?? startingSession;
        if (sessionId !== undefined) {
            throw new SessionAlreadyStartedError(userId, sessionId);
        }

        let reservation: SessionReservation | undefined;
        try {
            reservation = this.reserveSessionFile(userId);
            // Keep the reserved ID visible while coverage reset runs so reentrant starts report the same session.
            this.startingSessionForUsers.set(userId, reservation.sessionId);
            clearCoverageHits();
            this.activeSessionForUsers.set(userId, reservation.sessionId);
            this.knownUsers.add(userId);
            return reservation.sessionId;
        } catch (error) {
            if (reservation) {
                try {
                    unlinkSync(reservation.filePath);
                } catch (cleanupError) {
                    // The original preparation error must determine the REST 500 response.
                    LoggerProvider.file.debug(i18n.t('session_reservation_cleanup_failed_diagnostic', {
                        error: errorMessage(cleanupError),
                        sessionFilePath: reservation.filePath
                    }));
                }
            }
            throw error;
        } finally {
            this.startingSessionForUsers.delete(userId);
        }
    }

    stopSession(userId = DEFAULT_USER_ID): string {
        const sessionId = this.activeSessionForUsers.get(userId);
        if (!sessionId) {
            if (!this.knownUsers.has(userId)) {
                throw new UserIdNotFoundError(userId);
            }
            throw new CannotStopSessionNotStartedError(userId);
        }
        if (this.stoppingUsers.has(userId)) {
            throw new CannotStopSessionInProgressError(userId, sessionId);
        }

        // Keep the session active until persistence succeeds so later deletion APIs cannot remove it mid-stop.
        this.stoppingUsers.add(userId);
        try {
            this.persistSessionCoverage(userId, sessionId);
            this.activeSessionForUsers.delete(userId);
            return sessionId;
        } finally {
            this.stoppingUsers.delete(userId);
        }
    }

    private reserveSessionFile(userId: string): SessionReservation {
        const userDirectory = this.ensureUserDirectory(userId);
        const timestamp = formatTimestamp(this.now());

        for (let sequence = 0; ; sequence += 1) {
            const sessionId = `runtime_coverage_${timestamp}_${sequence}`;
            const filePath = join(userDirectory, `${sessionId}.json`);
            try {
                // The exclusive write atomically reserves the session ID while initializing valid JSON.
                writeFileSync(filePath, '{}', { encoding: 'utf8', flag: 'wx' });
                return { sessionId, filePath };
            } catch (error) {
                if (getErrorCode(error) === 'EEXIST') {
                    continue;
                }
                throw error;
            }
        }
    }

    private ensureUserDirectory(userId: string): string {
        const userDirectory = this.getUserDirectory(userId);
        mkdirSync(userDirectory, { recursive: true });
        if (lstatSync(userDirectory).isSymbolicLink()) {
            throw new Error(i18n.t('session_user_id_symbolic_link', { userId }));
        }
        return userDirectory;
    }

    private persistSessionCoverage(userId: string, sessionId: string): void {
        const filePath = join(this.ensureUserDirectory(userId), `${sessionId}.json`);
        const sessionFileStat = lstatSync(filePath, { throwIfNoEntry: false });
        // lstat recognizes dangling links, whereas existsSync treats them as absent.
        if (sessionFileStat?.isSymbolicLink()) {
            throw new Error(i18n.t('session_file_symbolic_link', { session: sessionId, userId }));
        }
        if (!sessionFileStat) {
            LoggerProvider.file.debug(i18n.t('session_file_missing_diagnostic', { sessionFilePath: filePath }));
        }
        const temporaryFilePath = `${filePath}.${randomUUID()}.tmp`;
        let temporaryFileCreated = false;
        let temporaryFileDescriptor: number | undefined;
        try {
            temporaryFileDescriptor = openSync(temporaryFilePath, 'wx');
            temporaryFileCreated = true;
            writeFileSync(temporaryFileDescriptor, JSON.stringify(getCoverage()), 'utf8');
            closeSync(temporaryFileDescriptor);
            temporaryFileDescriptor = undefined;
            renameSync(temporaryFilePath, filePath);
            temporaryFileCreated = false;
        } catch (error) {
            if (temporaryFileDescriptor !== undefined) {
                try {
                    closeSync(temporaryFileDescriptor);
                } catch (cleanupError) {
                    LoggerProvider.file.debug(i18n.t('session_persistence_cleanup_failed_diagnostic', {
                        error: errorMessage(cleanupError),
                        temporaryFilePath
                    }));
                }
            }
            if (temporaryFileCreated) {
                try {
                    unlinkSync(temporaryFilePath);
                } catch (cleanupError) {
                    if (getErrorCode(cleanupError) !== 'ENOENT') {
                        LoggerProvider.file.debug(i18n.t('session_persistence_cleanup_failed_diagnostic', {
                            error: errorMessage(cleanupError),
                            temporaryFilePath
                        }));
                    }
                }
            }
            const message = i18n.t('session_write_failed_diagnostic', { sessionFilePath: filePath });
            if (error instanceof Error) {
                LoggerProvider.file.error(message, error);
            } else {
                LoggerProvider.file.error(`${message} ${errorMessage(error)}`);
            }
            throw error;
        }
    }

    private getUserDirectory(userId: string): string {
        if (userId.includes('/') || userId.includes('\\')) {
            throw new Error(i18n.t('session_user_id_must_identify_directory', { userId }));
        }
        const runtimeData = resolve(this.runtimeData);
        const userDirectory = resolve(runtimeData, userId);
        const pathFromRuntimeData = relative(runtimeData, userDirectory);
        if (pathFromRuntimeData === '' || pathFromRuntimeData === '..' || pathFromRuntimeData.startsWith(`..${sep}`) || isAbsolute(pathFromRuntimeData)) {
            throw new Error(i18n.t('session_user_id_outside_runtime_data', { userId }));
        }
        return userDirectory;
    }
}

type SessionReservation = { sessionId: string; filePath: string };

function formatTimestamp(date: Date): string {
    return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}_${pad(date.getHours())}${pad(date.getMinutes())}`;
}

function pad(value: number): string {
    return value.toString().padStart(2, '0');
}

function getErrorCode(error: unknown): unknown {
    return typeof error === 'object' && error !== null ? (error as { code?: unknown }).code : undefined;
}
