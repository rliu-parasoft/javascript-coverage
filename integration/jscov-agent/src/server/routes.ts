import type { Express, Request, Response } from 'express';
import type { AgentConfig } from '../configuration/config.js';
import i18n from '../i18n.js';
import { LoggerProvider } from '../logging/logger.js';
import { SessionAlreadyStartedError, SessionService } from '../session/session-service.js';
import { errorMessage as getErrorMessage } from '../utils.js';

type RouteRegistrar = (app: Express) => void;

// Todo: placeholder
const status: RouteRegistrar = (app) => {
    app.get('/status', (_request, response) => {
        response.json({ status: 'ok', temporary: true });
    });
};

export function createRoutes(config: AgentConfig): readonly RouteRegistrar[] {
    const sessions = new SessionService(config.runtimeData);
    return [status, sessionStart(sessions)];
}
function sessionStart(sessions: SessionService): RouteRegistrar {
    return (app) => {
        const start = (_request: Request, response: Response) => {
            try {
                const session = sessions.startSession();
                LoggerProvider.file.debug(i18n.t('session_started', { session }));
                response.json({ session });
            } catch (error) {
                if (error instanceof SessionAlreadyStartedError) {
                    LoggerProvider.file.debug(error.message);
                    response.status(400).json({ messageCode: 150, message: error.message });
                    return;
                }
                const baseErrorMessage = i18n.t('session_start_failed');
                const errorMessage = `${baseErrorMessage} ${getErrorMessage(error)}`;
                LoggerProvider.console.error(errorMessage);
                if (error instanceof Error) {
                    LoggerProvider.file.error(baseErrorMessage, error);
                } else {
                    LoggerProvider.file.error(errorMessage);
                }
                response.status(500).json({ messageCode: 500, message: errorMessage });
            }
        };
        app.get('/session/start', start);
        app.post('/session/start', start);
    };
}
