import type { Request, Response } from 'express';
import { describe, expect, it } from 'vitest';
import { errorMessage, getResponseLogMessage, isRecord } from '../src/utils.js';

describe('errorMessage', () => {
    it('returns the message from an Error', () => {
        expect(errorMessage(new Error('startup failed'))).toBe('startup failed');
    });

    it('converts non-Error values to strings', () => {
        expect(errorMessage({ reason: 'startup failed' })).toBe('[object Object]');
    });
});

describe('isRecord', () => {
    it('accepts objects and rejects null, arrays, and primitive values', () => {
        expect(isRecord({ reason: 'startup failed' })).toBe(true);
        expect(isRecord(null)).toBe(false);
        expect(isRecord([])).toBe(false);
        expect(isRecord('startup failed')).toBe(false);
    });
});
describe('getResponseLogMessage', () => {
    it.each([
        ['HEAD', 200],
        ['GET', 204],
        ['GET', 304]
    ])('records zero response bytes for %s %i', (method, statusCode) => {
        const request = {
            originalUrl: '/coverage',
            ip: '127.0.0.1',
            socket: { remoteAddress: '127.0.0.1' },
            method,
            path: '/coverage',
            headers: {},
            get: () => undefined
        } as unknown as Request;
        const response = {
            statusCode,
            getHeader: () => '99'
        } as unknown as Response;

        const message = getResponseLogMessage(request, response, new Date(2026, 0, 1), {
            address: '127.0.0.1',
            port: '8050'
        });

        expect(message.split('\t')[10]).toBe('0');
    });

    it('uses safe placeholders for absent access-log fields and a chunked request', () => {
        const request = {
            originalUrl: '/coverage?',
            ip: '',
            socket: { remoteAddress: undefined },
            method: '',
            path: '',
            headers: { 'transfer-encoding': 'chunked' },
            get: () => undefined
        } as unknown as Request;
        const response = {
            statusCode: 200,
            getHeader: () => undefined
        } as unknown as Response;

        const fields = getResponseLogMessage(request, response, new Date(2026, 0, 1), {
            address: '127.0.0.1',
            port: '8050'
        }).split('\t');

        expect(fields.slice(2, 11)).toEqual(['-', '-', '127.0.0.1', '8050', '-', '-', '-', '200', '-']);
        expect(fields[11]).toBe('-');
    });
});
