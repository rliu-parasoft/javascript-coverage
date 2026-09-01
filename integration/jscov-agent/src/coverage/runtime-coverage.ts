import { isRecord } from '../utils.js';

export function clearCoverageHits(): void {
    const coverage = getCoverage();
    for (const fileCoverage of Object.values(coverage)) {
        if (!isRecord(fileCoverage)) {
            continue;
        }
        resetCounters(fileCoverage.s);
        resetCounters(fileCoverage.f);
        resetBranchCounters(fileCoverage.b);
    }
}

export function getCoverage(): Record<string, unknown> {
    const coverage = (globalThis as { __coverage__?: unknown }).__coverage__;
    return isRecord(coverage) ? coverage : {};
}

function resetCounters(counters: unknown): void {
    if (!isRecord(counters)) {
        return;
    }

    for (const [key, value] of Object.entries(counters)) {
        if (typeof value === 'number') {
            counters[key] = 0;
        }
    }
}

function resetBranchCounters(branchCounters: unknown): void {
    if (!isRecord(branchCounters)) {
        return;
    }

    for (const counters of Object.values(branchCounters)) {
        if (!Array.isArray(counters)) {
            continue;
        }
        for (let index = 0; index < counters.length; index += 1) {
            if (typeof counters[index] === 'number') {
                counters[index] = 0;
            }
        }
    }
}
