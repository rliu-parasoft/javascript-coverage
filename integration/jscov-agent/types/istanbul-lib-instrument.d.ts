declare module 'istanbul-lib-instrument' {
    export interface SourceMap {
        version: number;
        sources: string[];
        names: string[];
        mappings: string;
        file?: string;
        sourceRoot?: string;
        sourcesContent?: string[];
    }

    export interface Instrumenter {
        instrumentSync(code: string, filename: string, inputSourceMap?: SourceMap): string;
        lastSourceMap(): SourceMap | null;
    }

    export function createInstrumenter(options?: Record<string, unknown>): Instrumenter;
}
