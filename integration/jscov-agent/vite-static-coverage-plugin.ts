import { createInstrumenter } from 'istanbul-lib-instrument';
import { extname, relative } from 'node:path';
import type { Plugin } from 'vite';

function isSourceFile(fileName: string, sourceDirectory: string): boolean {
    const sourcePath = relative(sourceDirectory, fileName.split('?', 1)[0]);
    return extname(fileName) === '.ts' && sourcePath.length > 0 && !sourcePath.startsWith('..');
}

/**
 * Instruments the SSR agent bundle because vite-plugin-istanbul intentionally skips SSR transforms.
 */
export function createSsrStaticCoveragePlugin(sourceDirectory: string): Plugin {
    const instrumenter = createInstrumenter({
        coverageGlobalScopeFunc: false,
        coverageGlobalScope: 'globalThis',
        preserveComments: true,
        produceSourceMap: true,
        autoWrap: true,
        esModules: true,
        compact: false
    });

    return {
        name: 'parasoft:ssr-static-coverage',
        enforce: 'post',
        transform(source, id, options) {
            if (!options?.ssr || !isSourceFile(id, sourceDirectory)) {
                return null;
            }

            const instrumentedSource = instrumenter.instrumentSync(source, id, this.getCombinedSourcemap());
            return {
                code: instrumentedSource,
                map: instrumenter.lastSourceMap()
            };
        }
    };
}
