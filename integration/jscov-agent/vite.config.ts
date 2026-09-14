import { defineConfig } from 'vite';
import { resolve } from 'node:path';
import { createSsrStaticCoveragePlugin } from './vite-static-coverage-plugin.js';

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === 'development';
    const isInstrumented = mode === 'instrument';

    return {
        plugins: isInstrumented
            ? [
                // The Vite SSR build requires the Parasoft instrumenter to transform the agent source directly.
                createSsrStaticCoveragePlugin(resolve(import.meta.dirname, 'src'))
            ]
            : [],
        build: {
            ssr: 'src/agent.ts',
            outDir: isDevelopment ? 'dist-dev' : 'dist',
            minify: isDevelopment ? false : 'oxc',
            // Static coverage uses source maps to restore TypeScript source locations in its snapshots.
            sourcemap: isDevelopment || isInstrumented,
            rollupOptions: {
                output: {
                    format: 'es',
                    entryFileNames: 'agent.js'
                }
            }
        },
        ssr: {
            noExternal: true
        }
    };
});
