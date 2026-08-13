import type { Express } from 'express';

type RouteRegistrar = (app: Express) => void;

// Todo: placeholder
const status: RouteRegistrar = (app) => {
    app.get('/status', (_request, response) => {
        response.json({ status: 'ok', temporary: true });
    });
};

export const routes: RouteRegistrar[] = [status];
