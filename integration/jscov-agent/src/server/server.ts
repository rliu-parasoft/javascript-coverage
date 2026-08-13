import express, { type Express } from 'express';
import type { Server } from 'node:http';
import type { AgentConfig } from '../configuration/config.js';
import { routes } from './routes.js';

export interface StartedAgent {
    close(): Promise<void>;
}

export async function startAgent(config: AgentConfig): Promise<StartedAgent> {
    const app = express();
    for (const register of routes) {
        register(app);
    }

    const server = await listen(app, config.port);
    console.log(`Parasoft JavaScript runtime coverage agent started on port ${config.port}`);

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
        const server = app.listen(port, () => {
            server.off('error', reject);
            resolve(server);
        });
        server.once('error', reject);
    });
}
