import { lstatSync, mkdirSync, unlinkSync, writeFileSync } from 'node:fs';
import { isAbsolute, join, relative, resolve, sep } from 'node:path';
import { clearCoverageHits } from '../coverage/runtime-coverage.js';
import i18n from '../i18n.js';
import { LoggerProvider } from '../logging/logger.js';
import { errorMessage } from '../utils.js';

export const DEFAULT_USER_ID = '__default__';

export class SessionAlreadyStartedError extends Error {
    constructor() {
        super(i18n.t('session_already_started'));
    }
}

export class SessionService {
    private readonly activeSessionForUsers = new Map<string, string>();
    private readonly startingUsers = new Set<string>();

    constructor(
        private readonly runtimeData: string,
        private readonly now: () => Date = () => new Date()
    ) {}

    getActiveSession(userId = DEFAULT_USER_ID): string | undefined {
        return this.activeSessionForUsers.get(userId);
    }

    startSession(userId = DEFAULT_USER_ID): string {
        if (this.activeSessionForUsers.has(userId) || this.startingUsers.has(userId)) {
            throw new SessionAlreadyStartedError();
        }

        // Reserve before filesystem work so concurrent starts for one user cannot both create sessions.
        this.startingUsers.add(userId);
        let reservation: SessionReservation | undefined;
        try {
            reservation = this.reserveSessionFile(userId);
            clearCoverageHits();
            this.activeSessionForUsers.set(userId, reservation.sessionId);
            return reservation.sessionId;
        } catch (error) {
            if (reservation) {
                try {
                    unlinkSync(reservation.filePath);
                } catch (cleanupError) {
                    // The original preparation error must determine the REST 500 response.
                    LoggerProvider.file.debug(i18n.t('session_reservation_cleanup_failed', { error: errorMessage(cleanupError) }));
                }
            }
            throw error;
        } finally {
            this.startingUsers.delete(userId);
        }
    }

    private reserveSessionFile(userId: string): SessionReservation {
        const userDirectory = this.getUserDirectory(userId);
        mkdirSync(userDirectory, { recursive: true });
        if (lstatSync(userDirectory).isSymbolicLink()) {
            throw new Error(i18n.t('session_user_id_symbolic_link'));
        }
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

    private getUserDirectory(userId: string): string {
        if (userId.includes('/') || userId.includes('\\')) {
            throw new Error(i18n.t('session_user_id_must_identify_directory'));
        }
        const runtimeData = resolve(this.runtimeData);
        const userDirectory = resolve(runtimeData, userId);
        const pathFromRuntimeData = relative(runtimeData, userDirectory);
        if (pathFromRuntimeData === '' || pathFromRuntimeData === '..' || pathFromRuntimeData.startsWith(`..${sep}`) || isAbsolute(pathFromRuntimeData)) {
            throw new Error(i18n.t('session_user_id_outside_runtime_data'));
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
