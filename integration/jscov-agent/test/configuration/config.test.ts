import { describe, expect, it } from 'vitest';
import { getConfig } from '../../src/configuration/config.js';

describe('getConfig', () => {
    it('returns default port 8050', () => {
        expect(getConfig()).toEqual({ port: 8050 });
    });
});
