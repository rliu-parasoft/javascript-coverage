import { defineConfig } from 'vite';

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === 'development';

    return {
        build: {
            ssr: 'src/agent.ts',
            outDir: isDevelopment ? 'dist-dev' : 'dist',
            minify: isDevelopment ? false : 'oxc',
            sourcemap: isDevelopment,
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
