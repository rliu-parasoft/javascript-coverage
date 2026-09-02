import { closeSync, lstatSync, mkdirSync, openSync, readdirSync, renameSync, rmdirSync, unlinkSync, writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { basename, isAbsolute, join, parse, relative, resolve, sep } from 'node:path';
import type { PassThrough } from 'node:stream';
import { ZipFile } from 'yazl';
import { clearCoverageHits, getCoverage } from '../coverage/runtime-coverage.js';
import { remapRuntimeCoverage } from '../coverage/source-map-remapper.js';
import i18n from '../i18n.js';
import { LoggerProvider } from '../logging/logger.js';
import { errorMessage } from '../utils.js';
import type { DeleteCoverageResponse, SkippedCoverage } from '../server/responses.js';

export const DEFAULT_USER_ID = '__default__';
const SESSION_ID_PREFIX = 'runtime_coverage_';
const SESSION_ID = /^runtime_coverage_\d{8}_\d{4}_\d+$/;

export interface SessionArchive {
    readonly filename: string;
    readonly errorSource: ZipFile;
    readonly output: PassThrough;
}

type CoverageDeletion =
    | { readonly kind: 'all' }
    | { readonly kind: 'session'; readonly sessionId: string };

export class SessionAlreadyStartedError extends Error {
    readonly sessionId: string;

    constructor(userId: string, sessionId: string) {
        super(i18n.t('session_already_started', { session: sessionId, userId }));
        this.sessionId = sessionId;
    }
}

export class UserIdNotFoundError extends Error {
    constructor(message: string) {
        super(message);
    }
}

export class SessionIdNotFoundError extends Error {
    constructor(sessionId: string) {
        super(i18n.t('coverage_session_not_found', { sessionId }));
    }
}

export class VersionFileNotFoundError extends Error {
    constructor(versionFile: string) {
        super(i18n.t('version_file_not_found', { path: versionFile }));
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

    createSessionArchive(sessionId: string, userId = DEFAULT_USER_ID): SessionArchive {
        if (!this.knownUsers.has(userId)) {
            throw new UserIdNotFoundError(i18n.t('coverage_user_not_found', { userId }));
        }
        const userDirectory = this.getUserDirectory(userId);
        const userDirectoryStat = lstatSync(userDirectory, { throwIfNoEntry: false });
        if (!userDirectoryStat) {
            throw new UserIdNotFoundError(i18n.t('coverage_user_not_found', { userId }));
        }
        if (userDirectoryStat.isSymbolicLink()) {
            throw new Error(i18n.t('session_user_id_symbolic_link', { userId }));
        }
        if (!SESSION_ID.test(sessionId)) {
            throw new SessionIdNotFoundError(sessionId);
        }

        const sessionFile = join(userDirectory, `${sessionId}.json`);
        const sessionFileStat = lstatSync(sessionFile, { throwIfNoEntry: false });
        if (sessionFileStat?.isSymbolicLink()) {
            throw new Error(i18n.t('session_file_symbolic_link', { session: sessionId, userId }));
        }
        if (!sessionFileStat?.isFile()) {
            throw new SessionIdNotFoundError(sessionId);
        }

        const resolvedRuntimeData = resolve(this.runtimeData);
        const versionFile = join(resolvedRuntimeData, 'version.json');
        const versionFileStat = lstatSync(versionFile, { throwIfNoEntry: false });
        if (versionFileStat?.isSymbolicLink()) {
            throw new Error(i18n.t('agent_version_file_symbolic_link', { path: versionFile }));
        }
        if (!versionFileStat?.isFile()) {
            throw new VersionFileNotFoundError(versionFile);
        }

        const archive = new ZipFile();
        const runtimeDataName = basename(resolvedRuntimeData);
        archive.addFile(versionFile, `${runtimeDataName}/version.json`);
        archive.addFile(sessionFile, `${runtimeDataName}/${userId}/${sessionId}.json`);
        archive.end();

        return {
            filename: `${sessionId}.zip`,
            errorSource: archive,
            output: archive.outputStream as PassThrough
        };
    }

    getLocalSessionNames(userId = DEFAULT_USER_ID): string[] {
        if (!this.knownUsers.has(userId)) {
            throw new UserIdNotFoundError(i18n.t('coverage_user_not_found', { userId }));
        }
        const userDirectory = this.getUserDirectory(userId);
        try {
            if (lstatSync(userDirectory).isSymbolicLink()) {
                throw new Error(i18n.t('session_user_id_symbolic_link', { userId }));
            }
            return readdirSync(userDirectory, { withFileTypes: true })
                .filter((entry) => entry.isFile())
                .map((entry) => parse(entry.name).name)
                .sort();
        } catch (error) {
            if (getErrorCode(error) === 'ENOENT') {
                throw new UserIdNotFoundError(i18n.t('coverage_user_not_found', { userId }));
            }
            throw error;
        }
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
                throw new UserIdNotFoundError(i18n.t('session_user_not_found', { userId }));
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

    deleteCoverageSession(sessionId: string, userId = DEFAULT_USER_ID): DeleteCoverageResponse {
        if (!this.isSessionIdSafe(sessionId) || !this.isSessionFileName(`${sessionId}.json`)) {
            return { skipped: [this.toSkipped(sessionId, 350, 'coverage_delete_session_not_found')], deleted: [] };
        }
        return this.deleteCoverage({ kind: 'session', sessionId }, userId);
    }

    deleteAllCoverageSessions(userId = DEFAULT_USER_ID): DeleteCoverageResponse {
        return this.deleteCoverage({ kind: 'all' }, userId);
    }

    private deleteCoverage(operation: CoverageDeletion, userId: string): DeleteCoverageResponse {
        const isCollectionDelete = operation.kind === 'all';
        const inProgressMessageCode = isCollectionDelete ? 300 : 301;
        const removalFailureMessageCode = isCollectionDelete ? 302 : 303;
        const userDirectory = this.getExistingUserDirectory(userId);
        const selectedSessionIds = isCollectionDelete
            ? readdirSync(userDirectory, { withFileTypes: true })
                .filter((entry) => entry.isFile() && this.isSessionFileName(entry.name))
                .map((entry) => parse(entry.name).name)
            : [operation.sessionId];
        const skipped: SkippedCoverage[] = [];
        const deleted: string[] = [];
        const inProgressSession = this.getInProgressSession(userId);

        if (!this.knownUsers.has(userId)) {
            if (inProgressSession !== undefined && selectedSessionIds.every((sessionId) => sessionId === inProgressSession)) {
                return {
                    skipped: selectedSessionIds.map((sessionId) => this.toSkipped(sessionId, inProgressMessageCode, 'coverage_delete_session_in_progress')),
                    deleted: []
                };
            }
            throw new UserIdNotFoundError(i18n.t('coverage_delete_user_not_found', { userId }));
        }

        for (const sessionId of selectedSessionIds) {
            if (!this.isSessionIdSafe(sessionId)) {
                skipped.push(this.toSkipped(sessionId, 350, 'coverage_delete_session_not_found'));
                continue;
            }
            // A reservation stays visible during reset so lifecycle operations cannot delete its file.
            if (inProgressSession === sessionId) {
                skipped.push(this.toSkipped(sessionId, inProgressMessageCode, 'coverage_delete_session_in_progress'));
                continue;
            }
            const sessionFilePath = join(userDirectory, `${sessionId}.json`);
            try {
                if (!lstatSync(sessionFilePath, { throwIfNoEntry: false })) {
                    skipped.push(this.toSkipped(sessionId, 350, 'coverage_delete_session_not_found'));
                    continue;
                }
                unlinkSync(sessionFilePath);
            } catch (error) {
                LoggerProvider.file.debug(i18n.t('coverage_delete_session_remove_failed_diagnostic', {
                    error: errorMessage(error),
                    session: sessionId,
                    sessionFilePath,
                    userId
                }));
                // The REST contracts distinguish collection and single-session removal failures.
                skipped.push(this.toSkipped(sessionId, removalFailureMessageCode, 'coverage_delete_session_remove_failed', { sessionFilePath }));
                continue;
            }
            LoggerProvider.file.debug(i18n.t('coverage_delete_session_removed_diagnostic', { session: sessionId, userId }));
            deleted.push(sessionId);
        }

        if (isCollectionDelete || deleted.length > 0) {
            this.removeUserIfNoSessionFilesRemain(userId, userDirectory);
        }
        return { skipped, deleted };
    }

    private getExistingUserDirectory(userId: string): string {
        const userDirectory = this.getUserDirectory(userId);
        const stat = lstatSync(userDirectory, { throwIfNoEntry: false });
        if (!stat?.isDirectory()) {
            throw new UserIdNotFoundError(i18n.t('coverage_delete_user_not_found', { userId }));
        }
        return userDirectory;
    }

    private getInProgressSession(userId: string): string | undefined {
        return this.activeSessionForUsers.get(userId) ?? this.startingSessionForUsers.get(userId);
    }

    private isSessionIdSafe(sessionId: string): boolean {
        return !sessionId.includes('/') && !sessionId.includes('\\') && !sessionId.includes('\0');
    }

    private isSessionFileName(fileName: string): boolean {
        return fileName.startsWith(SESSION_ID_PREFIX) && parse(fileName).ext === '.json';
    }

    private toSkipped(sessionId: string, messageCode: number, reasonKey: string, variables?: Record<string, string>): SkippedCoverage {
        return { id: sessionId, messageCode, reason: i18n.t(reasonKey, variables) };
    }

    private removeUserIfNoSessionFilesRemain(userId: string, userDirectory: string): void {
        try {
            const entries = readdirSync(userDirectory);
            if (entries.some((entry) => this.isSessionFileName(entry))) {
                return;
            }
            this.knownUsers.delete(userId);
            // Keep unrelated runtime-data files intact after the coverage user becomes inactive.
            if (entries.length === 0) {
                rmdirSync(userDirectory);
            }
        } catch (error) {
            LoggerProvider.file.debug(i18n.t('coverage_delete_user_cleanup_failed_diagnostic', {
                error: errorMessage(error),
                userDirectory,
                userId
            }));
        }
    }

    private reserveSessionFile(userId: string): SessionReservation {
        const userDirectory = this.ensureUserDirectory(userId);
        const timestamp = formatTimestamp(this.now());

        for (let sequence = 0; ; sequence += 1) {
            const sessionId = `${SESSION_ID_PREFIX}${timestamp}_${sequence}`;
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
            writeFileSync(temporaryFileDescriptor, JSON.stringify(remapRuntimeCoverage(getCoverage())), 'utf8');
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
