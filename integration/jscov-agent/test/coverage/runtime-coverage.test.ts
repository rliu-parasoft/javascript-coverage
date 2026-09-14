import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { clearCoverageHits, getCoverage } from '../../src/coverage/runtime-coverage.js';

const coverageGlobal = globalThis as typeof globalThis & { __coverage__?: Record<string, unknown> };

describe('runtime coverage', () => {
    let hadCoverage: boolean;
    let previousCoverage: Record<string, unknown> | undefined;

    beforeEach(() => {
        hadCoverage = Object.hasOwn(coverageGlobal, '__coverage__');
        previousCoverage = coverageGlobal.__coverage__;
    });

    afterEach(() => {
        if (hadCoverage) {
            coverageGlobal.__coverage__ = previousCoverage;
        } else {
            delete coverageGlobal.__coverage__;
        }
    });

    it('clears supported Istanbul hit counters but leaves bT untouched', () => {
        coverageGlobal.__coverage__ = {
            '/app.js': {
                s: { '0': 3 },
                f: { '0': 2 },
                b: { '0': [4, 5] },
                bT: { '0': [6, 7] },
                statementMap: { '0': { start: { line: 1 } } }
            }
        };

        clearCoverageHits();

        expect(coverageGlobal.__coverage__?.['/app.js']).toMatchObject({
            s: { '0': 0 },
            f: { '0': 0 },
            b: { '0': [0, 0] },
            bT: { '0': [6, 7] }
        });
    });

    it('handles an absent coverage global without throwing', () => {
        delete coverageGlobal.__coverage__;

        expect(() => clearCoverageHits()).not.toThrow();
    });

    it('ignores malformed coverage records and counter structures', () => {
        coverageGlobal.__coverage__ = {
            '/valid.js': {
                s: { '0': 3, '1': 'invalid' },
                f: null,
                b: { '0': [4, 'invalid'], '1': 'invalid' }
            },
            '/invalid.js': 'not file coverage',
            '/invalid-branch-counters.js': { b: 'not counter records' }
        };

        clearCoverageHits();

        expect(coverageGlobal.__coverage__?.['/valid.js']).toMatchObject({
            s: { '0': 0, '1': 'invalid' },
            f: null,
            b: { '0': [0, 'invalid'], '1': 'invalid' }
        });
        expect(coverageGlobal.__coverage__?.['/invalid.js']).toBe('not file coverage');
        expect(coverageGlobal.__coverage__?.['/invalid-branch-counters.js']).toEqual({ b: 'not counter records' });
    });

    it('preserves coverage objects with custom prototypes', () => {
        const customPrototype = { inherited: 'ignored' };
        const coverage = Object.create(customPrototype) as Record<string, unknown>;
        coverage['/app.js'] = { s: { '0': 3 } };
        coverageGlobal.__coverage__ = coverage;

        expect(getCoverage()).toBe(coverage);
    });
});
