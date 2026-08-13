import { execFileSync } from 'node:child_process';
import { mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const moduleRoot = resolve(import.meta.dirname, '..');

describe('Vite build output', () => {
    it('cleans stale files and produces only the preload runtime artifact', () => {
        const distDir = resolve(moduleRoot, 'dist');
        mkdirSync(distDir, { recursive: true });
        writeFileSync(resolve(distDir, 'package.json'), '{"stale":true}');

        execFileSync(process.execPath, [resolve(moduleRoot, 'node_modules/vite/bin/vite.js'), 'build'], {
            cwd: moduleRoot,
            stdio: 'pipe',
            windowsHide: true
        });

        expect(readdirSync(distDir).sort()).toEqual(['agent.js']);
    }, 30_000);
});
