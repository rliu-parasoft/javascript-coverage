import type { Request, Response } from 'express';

export function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}

export function getResponseLogMessage(request: Request, response: Response, startedAt: Date, server: ServerInfo): string {
    const completedAt = new Date();
    const queryOffset = request.originalUrl.indexOf('?');
    const query = queryOffset === -1 ? '-' : request.originalUrl.slice(queryOffset + 1) || '-';
    return [
        formatDate(startedAt),
        formatTime(startedAt),
        request.ip || request.socket.remoteAddress || '-',
        '-', // Placeholder for userIdentifier
        server.address,
        server.port,
        request.method || '-',
        request.path || '-',
        query,
        response.statusCode.toString(),
        getResponseSize(request, response),
        getRequestSize(request),
        (completedAt.getTime() - startedAt.getTime()).toString(),
        request.get('host') ?? '-',
        request.get('user-agent') ?? '-',
        request.get('referer') ?? '-'
    ].join('\t');
}

export type ServerInfo = { address: string; port: string };

function getResponseSize(request: Request, response: Response): string {
    if (request.method === 'HEAD' || response.statusCode === 204 || response.statusCode === 304) {
        return '0';
    }
    return headerValue(response.getHeader('content-length')) ?? '-';
}

function getRequestSize(request: Request): string {
    const contentLength = headerValue(request.headers['content-length']);
    if (contentLength) {
        return contentLength;
    }
    return request.headers['transfer-encoding'] ? '-' : '0';
}

function headerValue(value: number | string | readonly string[] | undefined): string | undefined {
    if (value === undefined || Array.isArray(value)) {
        return undefined;
    }
    return value.toString();
}

function formatDate(date: Date): string {
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function formatTime(date: Date): string {
    return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

function pad(value: number): string {
    return value.toString().padStart(2, '0');
}