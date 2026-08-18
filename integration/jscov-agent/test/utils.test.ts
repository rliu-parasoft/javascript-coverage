import { describe, expect, it } from 'vitest';
import { errorMessage } from '../src/utils.js';

describe('errorMessage', () => {
    it('returns the message from an Error', () => {
        expect(errorMessage(new Error('startup failed'))).toBe('startup failed');
    });

    it('converts non-Error values to strings', () => {
        expect(errorMessage({ reason: 'startup failed' })).toBe('[object Object]');
    });
});
