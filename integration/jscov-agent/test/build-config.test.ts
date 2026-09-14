import { execFileSync, execSync, spawn } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { describe, expect, it } from 'vitest';

const moduleRoot = resolve(import.meta.dirname, '..');
const viteBin = resolve(moduleRoot, 'node_modules/vite/bin/vite.js');
const sourceMapMarker = /sourceMappingURL/;

describe('Vite build output', () => {
    it('cleans stale files and produces only the preload runtime artifact', () => {
        const developmentDir = resolve(moduleRoot, 'dist-dev');
        mkdirSync(developmentDir, { recursive: true });
        writeFileSync(resolve(developmentDir, 'package.json'), '{"stale":true}');

        execFileSync(process.execPath, [viteBin, 'build', '--mode', 'development'], {
            cwd: moduleRoot,
            stdio: 'pipe',
            windowsHide: true
        });

        expect(readdirSync(developmentDir).sort()).toEqual(['agent.js', 'agent.js.map']);
    }, 30_000);

    it('writes a minified production bundle to dist', () => {
        const developmentDir = resolve(moduleRoot, 'dist-dev');
        const productionDir = resolve(moduleRoot, 'dist');
        mkdirSync(developmentDir, { recursive: true });
        writeFileSync(resolve(developmentDir, 'package.json'), '{"stale":true}');

        execFileSync(process.execPath, [viteBin, 'build', '--mode', 'development'], {
            cwd: moduleRoot,
            stdio: 'pipe',
            windowsHide: true
        });

        execFileSync(process.execPath, [viteBin, 'build', '--mode', 'production'], {
            cwd: moduleRoot,
            stdio: 'pipe',
            windowsHide: true
        });

        const productionText = readFileSync(resolve(productionDir, 'agent.js'), 'utf8');
        const developmentText = readFileSync(resolve(developmentDir, 'agent.js'), 'utf8');

        expect(readdirSync(productionDir).sort()).toEqual(['agent.js']);
        expect(productionText).not.toMatch(sourceMapMarker);
        expect(productionText).not.toContain('//#region');
        expect(productionText).not.toContain('//#endregion');
        expect(statSync(resolve(productionDir, 'agent.js')).size).toBeLessThan(statSync(resolve(developmentDir, 'agent.js')).size);
        expect(developmentText).toContain('//#region');
    }, 30_000);

    it('recognizes a block-comment source-map marker as forbidden', () => {
        expect('/*# sourceMappingURL=agent.js.map */').toMatch(sourceMapMarker);
    });

    it('exposes instrumented-build and generated-artifact cleanup scripts', () => {
        const packageConfig = JSON.parse(readFileSync(resolve(moduleRoot, 'package.json'), 'utf8'));
        const packageScripts = packageConfig.scripts;

        expect(packageScripts['build:instrument']).toBe('vite build --mode instrument');
        expect(packageScripts.clean).toBe('rimraf dist dist-dev build reports .parasoft node_modules/.cache');
        expect(packageConfig.devDependencies['vite-plugin-istanbul']).toBeUndefined();
        expect(packageConfig.devDependencies['istanbul-lib-instrument']).toBe('file:vendor/parasoft-istanbul-lib-instrument-6.0.3-1.tgz');
        expect(packageConfig.overrides?.['istanbul-lib-instrument']).toBeUndefined();
    });

    it('resolves the instrumented SSR source relative to the Vite configuration file', () => {
        const viteConfig = readFileSync(resolve(moduleRoot, 'vite.config.ts'), 'utf8');

        expect(viteConfig).toContain("createSsrStaticCoveragePlugin(resolve(import.meta.dirname, 'src'))");
    });

    it('uses the default output directory for the public production npm build command', () => {
        const productionDir = resolve(moduleRoot, 'dist');
        const developmentDir = resolve(moduleRoot, 'dist-dev');
        rmSync(productionDir, { recursive: true, force: true });
        rmSync(developmentDir, { recursive: true, force: true });

        execSync('npm run build', {
            cwd: moduleRoot,
            stdio: 'pipe',
            windowsHide: true
        });

        const productionText = readFileSync(resolve(productionDir, 'agent.js'), 'utf8');

        expect(readdirSync(productionDir).sort()).toEqual(['agent.js']);
        expect(existsSync(resolve(developmentDir, 'agent.js'))).toBe(false);
        expect(productionText).not.toMatch(sourceMapMarker);
        expect(productionText).not.toContain('//#region');
        expect(productionText).not.toContain('//#endregion');
    }, 30_000);

    it('writes static coverage snapshots for the instrumented build', async () => {
        const testRuntimeDirectory = mkdtempSync(join(tmpdir(), 'jscov-agent-static-coverage-'));
        const staticCoverageDir = resolve(testRuntimeDirectory, '.parasoft', 'static-coverage');
        const viteProcess = spawn(process.execPath, [viteBin, 'build', moduleRoot, '--mode', 'instrument', '--config', resolve(moduleRoot, 'vite.config.ts')], {
            cwd: testRuntimeDirectory,
            env: {
                ...process.env,
                PARASOFT_STATIC_COVERAGE_ENABLE: 'true'
            },
            stdio: 'pipe',
            windowsHide: true
        });
        // Static coverage uses the Vite process ID, allowing this test to isolate its runtime data.
        const processDirectory = resolve(staticCoverageDir, String(viteProcess.pid));

        try {
            const exitCode = await new Promise<number | null>((resolve, reject) => {
                viteProcess.once('error', reject);
                viteProcess.once('close', resolve);
            });
            expect(exitCode).toBe(0);

            expect(existsSync(resolve(processDirectory, 'version.json'))).toBe(true);
            expect(readdirSync(processDirectory).some((file) => file.endsWith('.json') && file !== 'version.json')).toBe(true);
            expect(existsSync(resolve(moduleRoot, 'dist', 'agent.js'))).toBe(true);
            expect(existsSync(resolve(moduleRoot, 'dist', 'agent.js.map'))).toBe(true);
        } finally {
            rmSync(testRuntimeDirectory, { recursive: true, force: true });
        }
    }, 30_000);
});
