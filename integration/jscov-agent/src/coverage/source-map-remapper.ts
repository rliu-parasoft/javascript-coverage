import { TraceMap, type SourceMapInput } from '@jridgewell/trace-mapping';
import i18n from '../i18n.js';
import { LoggerProvider } from '../logging/logger.js';
import { errorMessage, isRecord } from '../utils.js';

// Istanbul's CommonJS packages do not ship TypeScript declarations. Keep the
// untyped static imports at this boundary so Vite can bundle them.
// @ts-expect-error -- Istanbul coverage has no bundled TypeScript declarations.
import * as coverageLibraryUntyped from 'istanbul-lib-coverage';
// @ts-expect-error -- Istanbul source-map transformer has no bundled TypeScript declarations.
import * as sourceMapTransformerUntyped from 'istanbul-lib-source-maps/lib/transformer.js';
// @ts-expect-error -- Istanbul mapped coverage has no bundled TypeScript declarations.
import * as mappedCoverageUntyped from 'istanbul-lib-source-maps/lib/mapped.js';

const { createCoverageMap, createFileCoverage } = coverageLibraryUntyped as unknown as IstanbulCoverageLibrary;
const { SourceMapTransformer } = sourceMapTransformerUntyped as unknown as {
    SourceMapTransformer: SourceMapTransformerConstructor;
};
const { MappedCoverage } = mappedCoverageUntyped as unknown as {
    MappedCoverage: MappedCoverageConstructor;
};

export interface IstanbulLocation {
    start: IstanbulPosition;
    end: IstanbulPosition;
}

export interface IstanbulPosition {
    line: number;
    column: number | null;
}

export interface IstanbulFunctionMetadata {
    name: string;
    decl: IstanbulLocation;
    loc: IstanbulLocation;
}

export interface IstanbulBranchMetadata {
    type: string;
    line?: number;
    loc?: IstanbulLocation;
    locations: IstanbulLocation[];
}

export interface IstanbulFileCoverage {
    path: string;
    statementMap: Record<string, IstanbulLocation>;
    fnMap: Record<string, IstanbulFunctionMetadata>;
    branchMap: Record<string, IstanbulBranchMetadata>;
    s: Record<string, number>;
    f: Record<string, number>;
    b: Record<string, number[]>;
    inputSourceMap?: object;
    [property: string]: unknown;}

export type RuntimeCoverage = Record<string, IstanbulFileCoverage>;

interface IstanbulCoverageFile extends IstanbulFileCoverage {
    toJSON(): IstanbulFileCoverage;
}

interface IstanbulCoverageMap {
    addFileCoverage(fileCoverage: IstanbulCoverageFile | IstanbulFileCoverage): void;
    toJSON(): Record<string, IstanbulCoverageFile>;
}

interface IstanbulCoverageLibrary {
    createCoverageMap(coverage: RuntimeCoverage): IstanbulCoverageMap;
    createFileCoverage(coverage: IstanbulFileCoverage): IstanbulCoverageFile;
}

interface MappedCoverageFile extends IstanbulCoverageFile {
    addStatement(location: IstanbulLocation, hits: number): number;
    addFunction(name: string, declaration: IstanbulLocation, location: IstanbulLocation, hits: number): number;
    addBranch(type: string, location: IstanbulLocation, branchLocations: IstanbulLocation[], hits: number[]): number;
}

interface MappedCoverageSink {
    addStatement(location: IstanbulLocation, hits: number): number;
    addFunction(name: string, declaration: IstanbulLocation, location: IstanbulLocation, hits: number): number;
    addBranch(type: string, location: IstanbulLocation, branchLocations: IstanbulLocation[], hits: number[]): number;
}

interface MappedCoverageConstructor {
    new (path: string): MappedCoverageFile;
}

interface SourceMapTransformerInstance {
    processFile(
        fileCoverage: IstanbulCoverageFile,
        sourceMap: TraceMap,
        coverageMapper: (source: string) => MappedCoverageSink
    ): boolean;
}

interface SourceMapTransformerConstructor {
    new (finder: null): SourceMapTransformerInstance;
}

export function remapRuntimeCoverage(coverage: RuntimeCoverage): RuntimeCoverage;
export function remapRuntimeCoverage(coverage: Record<string, unknown>): Record<string, unknown>;
export function remapRuntimeCoverage(coverage: Record<string, unknown>): Record<string, unknown> {
    const mappedCoverage = createCoverageMap({});
    const preservedCoverage: Record<string, unknown> = {};
    let hasMappedCoverage = false;

    for (const [key, candidate] of Object.entries(coverage)) {
        if (!isRecord(candidate) || !candidate.inputSourceMap) {
            preservedCoverage[key] = candidate;
            continue;
        }

        const fileCoverage = candidate as unknown as IstanbulFileCoverage;
        for (const remappedFile of remapFileCoverage(fileCoverage)) {
            if (remappedFile === fileCoverage) {
                preservedCoverage[key] = candidate;
            } else {
                mappedCoverage.addFileCoverage(remappedFile);
                hasMappedCoverage = true;
            }
        }
    }

    if (!hasMappedCoverage) {
        return preservedCoverage;
    }

    try {
        return {
            ...preservedCoverage,
            ...mergeMappedCoverage(preservedCoverage, mappedCoverage)
        };
    } catch (error) {
        // A merge failure cancels this remap so no mapped coverage is lost.
        logRemapFailure(undefined, error);
        return coverage;
    }
}

function remapFileCoverage(fileCoverage: IstanbulFileCoverage): IstanbulFileCoverage[] {
    if (!fileCoverage.inputSourceMap) {
        return [fileCoverage];
    }

    try {
        const sourceMap = new TraceMap(fileCoverage.inputSourceMap as unknown as SourceMapInput);
        const transformer = new SourceMapTransformer(null);
        const mappedFiles = new Map<string, MappedCoverageFile>();
        const getMappedCoverage = (path: string): MappedCoverageSink => {
            let mappedCoverage = mappedFiles.get(path);
            if (!mappedCoverage) {
                mappedCoverage = new MappedCoverage(path);
                mappedFiles.set(path, mappedCoverage);
            }
            return mappedCoverage;
        };

        transformer.processFile(createFileCoverage(fileCoverage), sourceMap, getMappedCoverage);

        if (mappedFiles.size > 0) {
            return [...mappedFiles.values()].map((mappedCoverage) => mappedCoverage.toJSON());
        }
        logRemapFailure(fileCoverage.path, i18n.t('coverage_remap_no_entries_diagnostic'));
    } catch (error) {
        // Source-map processing is best effort; preserve generated coverage on failure.
        logRemapFailure(fileCoverage.path, error);
    }

    return [fileCoverage];
}

function logRemapFailure(path: string | undefined, error: unknown): void {
    let message = '';
    if (!path) {
        message = i18n.t('coverage_remap_failed_diagnostic', {
            error: errorMessage(error)
        });
    } else {
        message = i18n.t('coverage_remap_failed_with_path_diagnostic', {
            path,
            error: errorMessage(error)
        });
    }
    LoggerProvider.file.warn(message);
}

function mergeMappedCoverage(
    preservedCoverage: Record<string, unknown>,
    mappedCoverage: IstanbulCoverageMap
): Record<string, IstanbulFileCoverage> {
    const merged: Record<string, IstanbulFileCoverage> = {};
    for (const [path, fileCoverage] of Object.entries(mappedCoverage.toJSON())) {
        const mapped = fileCoverage.toJSON();
        const preserved = preservedCoverage[path];
        if (isCompleteFileCoverage(preserved)) {
            const combined = createCoverageMap({});
            combined.addFileCoverage(preserved);
            combined.addFileCoverage(mapped);
            merged[path] = combined.toJSON()[path].toJSON();
        } else {
            // Preserve an existing no-map entry when it cannot be safely merged.
            if (preserved === undefined) {
                merged[path] = mapped;
            } else {
                throw new Error(i18n.t('coverage_remap_merge_conflict_diagnostic', { path }));
            }
        }
    }
    return merged;
}

function isCompleteFileCoverage(value: unknown): value is IstanbulFileCoverage {
    return isRecord(value)
        && typeof value.path === 'string'
        && isRecord(value.statementMap)
        && isRecord(value.fnMap)
        && isRecord(value.branchMap)
        && isRecord(value.s)
        && isRecord(value.f)
        && isRecord(value.b);
}
