import { execSync } from 'node:child_process';

const vitestArgs = [
    'vitest', 'run',
    '--no-file-parallelism',
    '--reporter=default',
    '--reporter=junit',
    '--outputFile.junit=build/test-results/test/report.xml',
    '--coverage.enabled',
    '--coverage.provider=istanbul',
    '--coverage.reportOnFailure',
    '--coverage.reporter=clover',
    '--coverage.reporter=html',
    '--coverage.reportsDirectory=build/reports/coverage'
].join(' ');

let exitCode = 0;
try {
    execSync(`npx ${vitestArgs}`, { stdio: 'inherit' });
} catch (error) {
    exitCode = error.status || 1;
} finally {
    execSync('node scripts/normalize-junit-times.mjs build/test-results/test/report.xml', { stdio: 'inherit' });
}

process.exit(exitCode);
