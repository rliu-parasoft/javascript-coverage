import express, { type Express } from 'express';
import { createServer, type Server } from 'node:http';
import type { AgentConfig } from '../configuration/config.js';
import { LoggerProvider } from '../logging/logger.js';
import i18n from '../i18n.js';
import { routes } from './routes.js';

export interface StartedAgent {
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
        return { close: async () => undefined };
    }

    const app = express();
    for (const register of routes) {
        register(app);
    }

    const server = await listen(app, config.restServerPort);
    const address = server.address();
    const port = typeof address === 'string' || !address ? config.restServerPort : address.port;
    const message = i18n.t('agent_started', { port });
    LoggerProvider.file.info(message);
    LoggerProvider.console.info(message);

    return {
        close() {
            return new Promise((resolve, reject) => {
                server.close((error) => (error ? reject(error) : resolve()));
            });
        }
    };
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
