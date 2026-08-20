import express, { type Express, type NextFunction, type Request, type Response } from 'express';
import { createServer, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import type { AgentConfig } from '../configuration/config.js';
import { createRoutes } from './routes.js';
import { LoggerProvider } from '../logging/logger.js';
import i18n from '../i18n.js';
import { getResponseLogMessage } from '../utils.js';

export interface StartedAgent {
    port: number;
    close(): Promise<void>;
}

export class RestServiceStartupError extends Error {
    readonly underlyingError: unknown;

    constructor(port: number, error: unknown) {
        const code = typeof error === 'object' && error !== null && 'code' in error ? error.code : undefined;
        const detail = code === 'EACCES' || code === 'EADDRINUSE'
            ? i18n.t('agent_rest_port_unavailable', { port })
            : error instanceof Error
                ? error.message
                : String(error);
        super(i18n.t('agent_rest_service_start_failed', { detail }));
        this.name = 'RestServiceStartupError';
        this.underlyingError = error;
    }
}

export async function startAgent(config: AgentConfig): Promise<StartedAgent> {
    if (!config.restServerEnabled) {
        return { port: config.restServerPort, close: async () => undefined };
    }

    const app = express();
    app.use(accessLog);
    for (const register of createRoutes(config)) {
        register(app);
    }

    const server = await listen(app, config.restServerPort);
    const { port } = server.address() as AddressInfo;
    const message = i18n.t('agent_started', { port });
    LoggerProvider.file.info(message);
    LoggerProvider.console.info(message);

    return {
        port,
        close() {
            return new Promise((resolve, reject) => {
                server.close((error) => (error ? reject(error) : resolve()));
            });
        }
    };
}

function accessLog(request: Request, response: Response, next: NextFunction): void {
    const startedAt = new Date();
    const server = {
        address: response.socket?.localAddress ?? '-',
        port: response.socket?.localPort?.toString() ?? '-'
    };
    response.once('finish', () => {
        LoggerProvider.console.info(getResponseLogMessage(request, response, startedAt, server));
    });
    next();
}

function listen(app: Express, port: number): Promise<Server> {
    return new Promise((resolve, reject) => {
        const server = createServer(app);
        function fail(error: unknown): void {
            server.off('listening', succeed);
            server.off('error', fail);
            reject(new RestServiceStartupError(port, error));
        }
        function succeed(): void {
            server.off('error', fail);
            resolve(server);
        }
        server.once('listening', succeed);
        server.once('error', fail);
        try {
            server.listen({ port, host: '0.0.0.0' });
        } catch (error) {
            fail(error);
        }
    });
}
