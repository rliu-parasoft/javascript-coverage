import { defineConfig } from 'vite';

const outDir = 'dist';

export default defineConfig({
    build: {
        ssr: 'src/agent.ts',
        outDir,
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
});
