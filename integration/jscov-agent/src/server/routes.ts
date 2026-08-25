import type { Express, Request, Response } from 'express';
import { currentAgentDescriptor } from '../agent-info.js';
import type { AgentConfig } from '../configuration/config.js';
import { toConfigResponse, toInfoResponse, toStatusResponse } from './responses.js';
import type { ErrorResponse } from './responses.js';
import i18n from '../i18n.js';
import { LoggerProvider } from '../logging/logger.js';
import {
    CannotStopSessionInProgressError,
    CannotStopSessionNotStartedError,
    DEFAULT_USER_ID,
    SessionAlreadyStartedError,
    SessionService,
    UserIdNotFoundError
} from '../session/session-service.js';
import { errorMessage } from '../utils.js';

type RouteRegistrar = (app: Express) => void;
type SessionLogContext = { session?: string; userId: string };

function respondError(response: Response, status: number, body: ErrorResponse): void {
    response.status(status).json(body);
}

function respondInternalError(response: Response, diagnosticMessage: string, error: unknown): void {
    const detailedMessage = `${diagnosticMessage} ${errorMessage(error)}`;
    if (error instanceof Error) {
        LoggerProvider.file.error(diagnosticMessage, error);
    } else {
        LoggerProvider.file.error(detailedMessage);
    }
    const body: ErrorResponse = { messageCode: 500, message: detailedMessage };
    respondError(response, 500, body);
}

function respondExpectedError(response: Response, status: number, messageCode: number, message: string, diagnosticMessage = message): void {
    LoggerProvider.file.debug(diagnosticMessage);
    respondError(response, status, { messageCode, message });
}

function sessionLogContext(sessions: SessionService, userId = DEFAULT_USER_ID): SessionLogContext {
    return { session: sessions.getActiveSession(userId), userId };
}

function statusRoute(sessions: SessionService): RouteRegistrar {
    return (app) => {
        app.get('/status', (_request, response) => {
            response.json(toStatusResponse(sessions.getActiveSession()));
        });
    };
}

function configRoute(config: AgentConfig): RouteRegistrar {
    return (app) => {
        app.get('/config', (_request, response) => {
            response.json(toConfigResponse(config));
        });
    };
}

function infoRoute(): RouteRegistrar {
    return (app) => {
        app.get('/info', (_request, response) => {
            response.json(toInfoResponse(currentAgentDescriptor));
        });
    };
}

function sessionStart(sessions: SessionService): RouteRegistrar {
    return (app) => {
        const start = (_request: Request, response: Response) => {
            const context = sessionLogContext(sessions);
            try {
                const session = sessions.startSession();
                LoggerProvider.file.debug(i18n.t('session_started_diagnostic', { ...context, session }));
                response.json({ session });
            } catch (error) {
                if (error instanceof SessionAlreadyStartedError) {
                    respondExpectedError(response, 400, 150, error.message, i18n.t('session_already_started', {
                        session: error.sessionId,
                        userId: context.userId
                    }));
                    return;
                }
                respondInternalError(response, i18n.t('session_start_failed', context), error);
            }
        };
        app.get('/session/start', start);
        app.post('/session/start', start);
    };
}

function sessionStop(sessions: SessionService): RouteRegistrar {
    return (app) => {
        const stop = (_request: Request, response: Response) => {
            const context = sessionLogContext(sessions);
            try {
                const session = sessions.stopSession();
                LoggerProvider.file.debug(i18n.t('session_stopped_diagnostic', { ...context, session }));
                response.json({ session: null });
            } catch (error) {
                if (error instanceof CannotStopSessionInProgressError) {
                    respondExpectedError(response, 404, 200, error.message, i18n.t('session_stop_in_progress_diagnostic', context));
                    return;
                }
                if (error instanceof UserIdNotFoundError) {
                    respondExpectedError(response, 404, 103, error.message);
                    return;
                }
                if (error instanceof CannotStopSessionNotStartedError) {
                    respondExpectedError(response, 404, 200, error.message);
                    return;
                }
                respondInternalError(response, i18n.t('session_stop_failed', context), error);
            }
        };
        app.get('/session/stop', stop);
        app.post('/session/stop', stop);
    };
}

export function createRoutes(config: AgentConfig, sessions: SessionService): readonly RouteRegistrar[] {
    return [statusRoute(sessions), configRoute(config), infoRoute(), sessionStart(sessions), sessionStop(sessions)];
}
