import { execFileSync, execSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
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
});
