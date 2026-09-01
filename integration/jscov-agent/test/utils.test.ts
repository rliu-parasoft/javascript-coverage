import { describe, expect, it } from 'vitest';
import { errorMessage, isRecord } from '../src/utils.js';

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
