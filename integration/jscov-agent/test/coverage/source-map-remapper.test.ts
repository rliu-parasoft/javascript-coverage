import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { LoggerProvider } from '../../src/logging/logger.js';
import { remapRuntimeCoverage, type IstanbulFileCoverage, type IstanbulLocation, type RuntimeCoverage } from '../../src/coverage/source-map-remapper.js';

type SourceMap = {
    version: 3;
    file: string;
    sources: string[];
    names: string[];
    mappings: string;
};

const sourceMapFixtureRoot = join(tmpdir(), 'jscov-agent-source-map-fixture');
const generatedPath = join(sourceMapFixtureRoot, 'dist', 'bundle.js');
const firstSourcePath = join(sourceMapFixtureRoot, 'src', 'first.ts');
const secondSourcePath = join(sourceMapFixtureRoot, 'src', 'second.ts');

function sourceMap(sources: string[], mappings: string): SourceMap {
    return {
        version: 3,
        file: generatedPath,
        sources,
        names: [],
        mappings
    };
}

function location(line: number, endLine = line, endColumn: number | null = 5): IstanbulLocation {
    return {
        start: { line, column: 0 },
        end: { line: endLine, column: endColumn }
    };
}

function fileCoverage(
    path: string,
    inputSourceMap: SourceMap | object | undefined,
    statementLine = 1,
    hits = 1
): IstanbulFileCoverage {
    const statementLocation = location(statementLine);
    return {
        path,
        statementMap: { '0': statementLocation },
        fnMap: {
            '0': {
                name: 'run',
                decl: statementLocation,
                loc: statementLocation
            }
        },
        branchMap: {
            '0': {
                type: 'if',
                line: statementLine,
                loc: statementLocation,
                locations: [statementLocation, statementLocation]
            }
        },
        s: { '0': hits },
        f: { '0': hits },
        b: { '0': [hits, 0] },
        ...(inputSourceMap === undefined ? {} : { inputSourceMap })
    };
}

describe('remapRuntimeCoverage', () => {
    let loggerRuntimeData: string | undefined;

    beforeEach(() => {
        loggerRuntimeData = mkdtempSync(join(tmpdir(), 'jscov-agent-remap-'));
        LoggerProvider.initialize({
            settings: undefined,
            runtimeData: loggerRuntimeData,
            sessionAutostart: true,
            restServerEnabled: true,
            restServerPort: 8050,
            debug: false,
            silentMode: false
        });
    });

    afterEach(async () => {
        await LoggerProvider.close();
        if (loggerRuntimeData !== undefined) {
            rmSync(loggerRuntimeData, { recursive: true, force: true });
            loggerRuntimeData = undefined;
        }
    });

    it('preserves file coverage unchanged when inputSourceMap is absent', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: fileCoverage(generatedPath, undefined)
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(remapped).toEqual(coverage);
        expect(remapped[generatedPath]).toBe(coverage[generatedPath]);
    });

    it('preserves a file when its source map disappears during remapping', () => {
        const file = fileCoverage(generatedPath, { version: 3, mappings: 'AAAA' });
        let reads = 0;
        Object.defineProperty(file, 'inputSourceMap', {
            enumerable: true,
            get: () => {
                reads += 1;
                return reads === 1 ? { version: 3, mappings: 'AAAA' } : undefined;
            }
        });

        const remapped = remapRuntimeCoverage({ [generatedPath]: file });

        expect(remapped[generatedPath]).toBe(file);
    });

    it('accepts legal null columns in preserved coverage locations', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: {
                ...fileCoverage(generatedPath, undefined),
                statementMap: { '0': location(1, 1, null) }
            }
        };

        expect(remapRuntimeCoverage(coverage)).toEqual(coverage);
    });

    it('remaps statements, functions, and branches to the original source location', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: fileCoverage(
                generatedPath,
                sourceMap([firstSourcePath], 'AAAA')
            )
        };

        const remapped = remapRuntimeCoverage(coverage);
        const mapped = remapped[firstSourcePath];

        expect(mapped).toBeDefined();
        expect(mapped.path).toBe(firstSourcePath);
        expect(mapped.statementMap['0'].start).toEqual({ line: 1, column: 0 });
        expect(mapped.fnMap['0'].loc.start).toEqual({ line: 1, column: 0 });
        expect(mapped.branchMap['0'].locations[0].start).toEqual({ line: 1, column: 0 });
        expect(mapped).not.toHaveProperty('inputSourceMap');
    });

    it('retains mapped coverage for every source in a multi-source map', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: {
                ...fileCoverage(generatedPath, sourceMap([firstSourcePath, secondSourcePath], 'AAAA;ACAA'), 1),
                statementMap: {
                    '0': location(1),
                    '1': location(2)
                },
                fnMap: {
                    '0': { name: 'first', decl: location(1), loc: location(1) },
                    '1': { name: 'second', decl: location(2), loc: location(2) }
                },
                branchMap: {
                    '0': { type: 'if', line: 1, loc: location(1), locations: [location(1), location(1)] },
                    '1': { type: 'if', line: 2, loc: location(2), locations: [location(2), location(2)] }
                },
                s: { '0': 1, '1': 2 },
                f: { '0': 1, '1': 2 },
                b: { '0': [1, 0], '1': [2, 0] }
            }
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(Object.keys(remapped)).toEqual([firstSourcePath, secondSourcePath]);
        expect(remapped[firstSourcePath].s).toEqual({ '0': 1 });
        expect(remapped[secondSourcePath].s).toEqual({ '0': 2 });
        expect(remapped[firstSourcePath].fnMap['0'].loc.start).toEqual({ line: 1, column: 0 });
        expect(remapped[secondSourcePath].fnMap['0'].loc.start).toEqual({ line: 1, column: 0 });
        expect(remapped[firstSourcePath].branchMap['0'].locations[0].start).toEqual({ line: 1, column: 0 });
        expect(remapped[secondSourcePath].branchMap['0'].locations[0].start).toEqual({ line: 1, column: 0 });
    });

    it('keeps generated coverage and does not throw when the source map is invalid', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: fileCoverage(generatedPath, { version: 3, mappings: 'not-valid' })
        };

        expect(() => remapRuntimeCoverage(coverage)).not.toThrow();
        expect(remapRuntimeCoverage(coverage)).toEqual(coverage);
    });

    it('logs remap failures to the file but not the console when debug is disabled', () => {
        const fileWarn = vi.spyOn(LoggerProvider.file, 'warn').mockImplementation(() => undefined);
        const consoleWarn = vi.spyOn(LoggerProvider.console, 'warn').mockImplementation(() => undefined);

        remapRuntimeCoverage({
            [generatedPath]: fileCoverage(generatedPath, { version: 3, mappings: 'not-valid' })
        });

        expect(fileWarn).toHaveBeenCalledWith(expect.stringContaining(generatedPath));
        expect(consoleWarn).not.toHaveBeenCalled();
    });

    it('keeps generated coverage when a valid source map has no mappings', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: fileCoverage(generatedPath, sourceMap([firstSourcePath], ''))
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(remapped).toEqual(coverage);
        expect(remapped[generatedPath]).toBe(coverage[generatedPath]);
    });

    it('processes mapped, unmapped, and invalid files independently', () => {
        const unmappedPath = join(sourceMapFixtureRoot, 'src', 'plain.ts');
        const invalidGeneratedPath = join(sourceMapFixtureRoot, 'dist', 'invalid.js');
        const coverage: RuntimeCoverage = {
            [generatedPath]: fileCoverage(generatedPath, sourceMap([firstSourcePath], 'AAAA'), 1, 2),
            [unmappedPath]: fileCoverage(unmappedPath, undefined, 2, 3),
            [invalidGeneratedPath]: fileCoverage(invalidGeneratedPath, { version: 3, mappings: 'not-valid' }, 3, 4)
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(remapped[firstSourcePath].s).toEqual({ '0': 2 });
        expect(remapped[unmappedPath]).toBe(coverage[unmappedPath]);
        expect(remapped[invalidGeneratedPath]).toBe(coverage[invalidGeneratedPath]);
        expect(remapped[generatedPath]).toBeUndefined();
    });

    it('uses Istanbul best-effort mapping when only part of the coverage maps', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: {
                ...fileCoverage(generatedPath, sourceMap([firstSourcePath], 'AAAA')),
                statementMap: {
                    '0': location(1),
                    '1': location(2)
                },
                s: { '0': 1, '1': 0 }
            }
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(remapped[generatedPath]).toBeUndefined();
        expect(remapped[firstSourcePath].s).toEqual({ '0': 1 });
        expect(Object.values(remapped[firstSourcePath].statementMap).map(({ start }) => start.line)).toEqual([1]);
    });

    it('uses Istanbul best-effort mapping when only part of a branch maps', () => {
        const coverage: RuntimeCoverage = {
            [generatedPath]: {
                ...fileCoverage(generatedPath, sourceMap([firstSourcePath], 'AAAA')),
                branchMap: {
                    '0': {
                        type: 'if',
                        line: 1,
                        loc: location(1),
                        locations: [location(1), location(2)]
                    }
                },
                b: { '0': [1, 0] }
            }
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(remapped[generatedPath]).toBeUndefined();
        expect(remapped[firstSourcePath].b).toEqual({ '0': [1] });
        expect(remapped[firstSourcePath].branchMap['0'].locations).toHaveLength(1);
    });

    it('merges counters and location maps when mapped inputs target one source path', () => {
        const otherGeneratedPath = join(sourceMapFixtureRoot, 'dist', 'other.js');
        const coverage: RuntimeCoverage = {
            [generatedPath]: fileCoverage(
                generatedPath,
                sourceMap([firstSourcePath], 'AAAA'),
                1,
                2
            ),
            [otherGeneratedPath]: fileCoverage(
                otherGeneratedPath,
                sourceMap([firstSourcePath], 'AACA'),
                1,
                3
            )
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(Object.keys(remapped)).toEqual([firstSourcePath]);
        expect(Object.values(remapped[firstSourcePath].statementMap).map(({ start }) => start.line)).toEqual([1, 2]);
        expect(remapped[firstSourcePath].s).toEqual({ '0': 2, '1': 3 });
        expect(remapped[firstSourcePath].f).toEqual({ '0': 2, '1': 3 });
        expect(remapped[firstSourcePath].b).toEqual({ '0': [2, 0], '1': [3, 0] });
        expect(Object.values(remapped[firstSourcePath].s).reduce((total, hits) => total + hits, 0)).toBe(5);
    });

    it('merges a mapped result with an existing preserved file at the same path', () => {
        const coverage: RuntimeCoverage = {
            [firstSourcePath]: fileCoverage(firstSourcePath, undefined, 1, 10),
            [generatedPath]: fileCoverage(
                generatedPath,
                sourceMap([firstSourcePath], 'AACA'),
                1,
                3
            )
        };

        const remapped = remapRuntimeCoverage(coverage);

        expect(Object.keys(remapped)).toEqual([firstSourcePath]);
        expect(Object.values(remapped[firstSourcePath].statementMap).map(({ start }) => start.line)).toEqual([1, 2]);
        expect(remapped[firstSourcePath].s).toEqual({ '0': 10, '1': 3 });
        expect(remapped[firstSourcePath].f).toEqual({ '0': 10, '1': 3 });
        expect(remapped[firstSourcePath].b).toEqual({ '0': [10, 0], '1': [3, 0] });
    });

    it('preserves malformed no-map coverage when a mapped result has the same path', () => {
        const malformedCoverage: Record<string, unknown> = {
            path: firstSourcePath,
            statementMap: { '0': undefined },
            fnMap: {},
            branchMap: {},
            s: {},
            f: {},
            b: {}
        };
        const coverage = {
            [firstSourcePath]: malformedCoverage,
            [generatedPath]: fileCoverage(generatedPath, sourceMap([firstSourcePath], 'AAAA'))
        };

        expect(() => remapRuntimeCoverage(coverage)).not.toThrow();
        expect(remapRuntimeCoverage(coverage)).toEqual(coverage);
    });

    it('falls back to original coverage when an incomplete preserved entry conflicts with a mapped result', () => {
        const incompleteCoverage: Record<string, unknown> = {
            path: firstSourcePath,
            statementMap: {},
            branchMap: {},
            s: {},
            f: {},
            b: {}
        };
        const coverage = {
            [firstSourcePath]: incompleteCoverage,
            [generatedPath]: fileCoverage(generatedPath, sourceMap([firstSourcePath], 'AAAA'))
        };

        expect(remapRuntimeCoverage(coverage)).toEqual(coverage);
    });

    it('remaps with multiple sources', () => {
        const multiSourceFixtureRoot = join(tmpdir(), 'jscov-agent-multi-source-fixture');
        const generatedMultiSourcePath = join(multiSourceFixtureRoot, 'dist', 'assets', 'index-UrVP7Pu3.js');
        const windowsGeneratedPath = 'E:\\ts-vite-npm-esm\\dist\\assets\\index-UrVP7Pu3.js';
        const coverage = structuredClone(createRealMultiSourceCoverageData);
        const generatedCoverage = coverage[windowsGeneratedPath] as Record<string, unknown>;
        delete coverage[windowsGeneratedPath];
        coverage[generatedMultiSourcePath] = {
            ...generatedCoverage,
            path: generatedMultiSourcePath
        };
        const inputKeys = Object.keys(coverage);
        const remapped = remapRuntimeCoverage(coverage);
        const expectedOutputPaths = [
            join(multiSourceFixtureRoot, 'src', 'message.ts'),
            join(multiSourceFixtureRoot, 'src', 'math.ts'),
            join(multiSourceFixtureRoot, 'src', 'utils', 'math.ts'),
            join(multiSourceFixtureRoot, 'src', 'main.ts')
        ];

        expect(inputKeys).toEqual([generatedMultiSourcePath]);
        expect(Object.keys(remapped)).toEqual(expectedOutputPaths);
        expect(remapped).not.toHaveProperty(inputKeys[0]);
        expect(remapped[expectedOutputPaths[0]]).toMatchObject({
            s: { '0': 1, '1': 1 },
            statementMap: {
                '0': { start: { line: 2, column: 17 } },
                '1': { start: { line: 4, column: 2 } }
            }
        });
        for (const path of expectedOutputPaths) {
            expect(remapped[path]).toMatchObject({ path });
            expect(remapped[path]).not.toHaveProperty('inputSourceMap');
        }
    });

    // Create real multi-source source map coverage data (from actual project)
    const createRealMultiSourceCoverageData: Record<string, unknown> = {
	"E:\\ts-vite-npm-esm\\dist\\assets\\index-UrVP7Pu3.js": {
		"path": "E:\\ts-vite-npm-esm\\dist\\assets\\index-UrVP7Pu3.js",
		"statementMap": {
			"0": {
				"start": {
					"line": 1,
					"column": 0
				},
				"end": {
					"line": 29,
					"column": 5
				}
			},
			"1": {
				"start": {
					"line": 2,
					"column": 18
				},
				"end": {
					"line": 2,
					"column": 56
				}
			},
			"2": {
				"start": {
					"line": 3,
					"column": 2
				},
				"end": {
					"line": 3,
					"column": 79
				}
			},
			"3": {
				"start": {
					"line": 3,
					"column": 72
				},
				"end": {
					"line": 3,
					"column": 79
				}
			},
			"4": {
				"start": {
					"line": 4,
					"column": 2
				},
				"end": {
					"line": 4,
					"column": 98
				}
			},
			"5": {
				"start": {
					"line": 4,
					"column": 77
				},
				"end": {
					"line": 4,
					"column": 98
				}
			},
			"6": {
				"start": {
					"line": 5,
					"column": 2
				},
				"end": {
					"line": 13,
					"column": 5
				}
			},
			"7": {
				"start": {
					"line": 6,
					"column": 4
				},
				"end": {
					"line": 9,
					"column": 5
				}
			},
			"8": {
				"start": {
					"line": 7,
					"column": 6
				},
				"end": {
					"line": 7,
					"column": 50
				}
			},
			"9": {
				"start": {
					"line": 7,
					"column": 41
				},
				"end": {
					"line": 7,
					"column": 50
				}
			},
			"10": {
				"start": {
					"line": 8,
					"column": 6
				},
				"end": {
					"line": 8,
					"column": 128
				}
			},
			"11": {
				"start": {
					"line": 8,
					"column": 46
				},
				"end": {
					"line": 8,
					"column": 128
				}
			},
			"12": {
				"start": {
					"line": 8,
					"column": 107
				},
				"end": {
					"line": 8,
					"column": 128
				}
			},
			"13": {
				"start": {
					"line": 15,
					"column": 22
				},
				"end": {
					"line": 15,
					"column": 24
				}
			},
			"14": {
				"start": {
					"line": 16,
					"column": 4
				},
				"end": {
					"line": 16,
					"column": 61
				}
			},
			"15": {
				"start": {
					"line": 16,
					"column": 24
				},
				"end": {
					"line": 16,
					"column": 61
				}
			},
			"16": {
				"start": {
					"line": 17,
					"column": 4
				},
				"end": {
					"line": 17,
					"column": 76
				}
			},
			"17": {
				"start": {
					"line": 17,
					"column": 29
				},
				"end": {
					"line": 17,
					"column": 76
				}
			},
			"18": {
				"start": {
					"line": 18,
					"column": 4
				},
				"end": {
					"line": 20,
					"column": 47
				}
			},
			"19": {
				"start": {
					"line": 18,
					"column": 48
				},
				"end": {
					"line": 18,
					"column": 82
				}
			},
			"20": {
				"start": {
					"line": 19,
					"column": 9
				},
				"end": {
					"line": 20,
					"column": 47
				}
			},
			"21": {
				"start": {
					"line": 19,
					"column": 47
				},
				"end": {
					"line": 19,
					"column": 78
				}
			},
			"22": {
				"start": {
					"line": 20,
					"column": 9
				},
				"end": {
					"line": 20,
					"column": 47
				}
			},
			"23": {
				"start": {
					"line": 21,
					"column": 4
				},
				"end": {
					"line": 21,
					"column": 21
				}
			},
			"24": {
				"start": {
					"line": 24,
					"column": 4
				},
				"end": {
					"line": 24,
					"column": 24
				}
			},
			"25": {
				"start": {
					"line": 24,
					"column": 17
				},
				"end": {
					"line": 24,
					"column": 24
				}
			},
			"26": {
				"start": {
					"line": 25,
					"column": 4
				},
				"end": {
					"line": 25,
					"column": 19
				}
			},
			"27": {
				"start": {
					"line": 26,
					"column": 22
				},
				"end": {
					"line": 26,
					"column": 40
				}
			},
			"28": {
				"start": {
					"line": 27,
					"column": 4
				},
				"end": {
					"line": 27,
					"column": 32
				}
			},
			"29": {
				"start": {
					"line": 31,
					"column": 17
				},
				"end": {
					"line": 31,
					"column": 64
				}
			},
			"30": {
				"start": {
					"line": 32,
					"column": 2
				},
				"end": {
					"line": 32,
					"column": 56
				}
			},
			"31": {
				"start": {
					"line": 35,
					"column": 15
				},
				"end": {
					"line": 35,
					"column": 38
				}
			},
			"32": {
				"start": {
					"line": 35,
					"column": 33
				},
				"end": {
					"line": 35,
					"column": 38
				}
			},
			"33": {
				"start": {
					"line": 37,
					"column": 19
				},
				"end": {
					"line": 37,
					"column": 40
				}
			},
			"34": {
				"start": {
					"line": 38,
					"column": 4
				},
				"end": {
					"line": 38,
					"column": 18
				}
			},
			"35": {
				"start": {
					"line": 42,
					"column": 2
				},
				"end": {
					"line": 42,
					"column": 15
				}
			},
			"36": {
				"start": {
					"line": 45,
					"column": 2
				},
				"end": {
					"line": 45,
					"column": 15
				}
			},
			"37": {
				"start": {
					"line": 47,
					"column": 12
				},
				"end": {
					"line": 47,
					"column": 33
				}
			},
			"38": {
				"start": {
					"line": 48,
					"column": 0
				},
				"end": {
					"line": 48,
					"column": 37
				}
			},
			"39": {
				"start": {
					"line": 49,
					"column": 0
				},
				"end": {
					"line": 49,
					"column": 27
				}
			},
			"40": {
				"start": {
					"line": 50,
					"column": 0
				},
				"end": {
					"line": 50,
					"column": 25
				}
			},
			"41": {
				"start": {
					"line": 51,
					"column": 12
				},
				"end": {
					"line": 51,
					"column": 42
				}
			},
			"42": {
				"start": {
					"line": 52,
					"column": 0
				},
				"end": {
					"line": 54,
					"column": 1
				}
			},
			"43": {
				"start": {
					"line": 53,
					"column": 2
				},
				"end": {
					"line": 53,
					"column": 55
				}
			}
		},
		"fnMap": {
			"0": {
				"name": "polyfill",
				"decl": {
					"start": {
						"line": 1,
						"column": 10
					},
					"end": {
						"line": 1,
						"column": 18
					}
				},
				"loc": {
					"start": {
						"line": 1,
						"column": 21
					},
					"end": {
						"line": 29,
						"column": 1
					}
				},
				"line": 1
			},
			"1": {
				"name": "(anonymous_1)",
				"decl": {
					"start": {
						"line": 5,
						"column": 23
					},
					"end": {
						"line": 5,
						"column": 24
					}
				},
				"loc": {
					"start": {
						"line": 5,
						"column": 38
					},
					"end": {
						"line": 10,
						"column": 3
					}
				},
				"line": 5
			},
			"2": {
				"name": "getFetchOpts",
				"decl": {
					"start": {
						"line": 14,
						"column": 11
					},
					"end": {
						"line": 14,
						"column": 23
					}
				},
				"loc": {
					"start": {
						"line": 14,
						"column": 30
					},
					"end": {
						"line": 22,
						"column": 3
					}
				},
				"line": 14
			},
			"3": {
				"name": "processPreload",
				"decl": {
					"start": {
						"line": 23,
						"column": 11
					},
					"end": {
						"line": 23,
						"column": 25
					}
				},
				"loc": {
					"start": {
						"line": 23,
						"column": 32
					},
					"end": {
						"line": 28,
						"column": 3
					}
				},
				"line": 23
			},
			"4": {
				"name": "createMessage",
				"decl": {
					"start": {
						"line": 30,
						"column": 9
					},
					"end": {
						"line": 30,
						"column": 22
					}
				},
				"loc": {
					"start": {
						"line": 30,
						"column": 37
					},
					"end": {
						"line": 33,
						"column": 1
					}
				},
				"line": 30
			},
			"5": {
				"name": "(anonymous_5)",
				"decl": {
					"start": {
						"line": 35,
						"column": 15
					},
					"end": {
						"line": 35,
						"column": 16
					}
				},
				"loc": {
					"start": {
						"line": 35,
						"column": 33
					},
					"end": {
						"line": 35,
						"column": 38
					}
				},
				"line": 35
			},
			"6": {
				"name": "(anonymous_6)",
				"decl": {
					"start": {
						"line": 36,
						"column": 2
					},
					"end": {
						"line": 36,
						"column": 3
					}
				},
				"loc": {
					"start": {
						"line": 36,
						"column": 24
					},
					"end": {
						"line": 39,
						"column": 3
					}
				},
				"line": 36
			},
			"7": {
				"name": "multiply",
				"decl": {
					"start": {
						"line": 41,
						"column": 9
					},
					"end": {
						"line": 41,
						"column": 17
					}
				},
				"loc": {
					"start": {
						"line": 41,
						"column": 24
					},
					"end": {
						"line": 43,
						"column": 1
					}
				},
				"line": 41
			},
			"8": {
				"name": "divide",
				"decl": {
					"start": {
						"line": 44,
						"column": 9
					},
					"end": {
						"line": 44,
						"column": 15
					}
				},
				"loc": {
					"start": {
						"line": 44,
						"column": 22
					},
					"end": {
						"line": 46,
						"column": 1
					}
				},
				"line": 44
			}
		},
		"branchMap": {
			"0": {
				"loc": {
					"start": {
						"line": 3,
						"column": 2
					},
					"end": {
						"line": 3,
						"column": 79
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 3,
							"column": 2
						},
						"end": {
							"line": 3,
							"column": 79
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 3
			},
			"1": {
				"loc": {
					"start": {
						"line": 3,
						"column": 6
					},
					"end": {
						"line": 3,
						"column": 70
					}
				},
				"type": "binary-expr",
				"locations": [
					{
						"start": {
							"line": 3,
							"column": 6
						},
						"end": {
							"line": 3,
							"column": 13
						}
					},
					{
						"start": {
							"line": 3,
							"column": 17
						},
						"end": {
							"line": 3,
							"column": 33
						}
					},
					{
						"start": {
							"line": 3,
							"column": 37
						},
						"end": {
							"line": 3,
							"column": 70
						}
					}
				],
				"line": 3
			},
			"2": {
				"loc": {
					"start": {
						"line": 7,
						"column": 6
					},
					"end": {
						"line": 7,
						"column": 50
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 7,
							"column": 6
						},
						"end": {
							"line": 7,
							"column": 50
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 7
			},
			"3": {
				"loc": {
					"start": {
						"line": 8,
						"column": 46
					},
					"end": {
						"line": 8,
						"column": 128
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 8,
							"column": 46
						},
						"end": {
							"line": 8,
							"column": 128
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 8
			},
			"4": {
				"loc": {
					"start": {
						"line": 8,
						"column": 50
					},
					"end": {
						"line": 8,
						"column": 105
					}
				},
				"type": "binary-expr",
				"locations": [
					{
						"start": {
							"line": 8,
							"column": 50
						},
						"end": {
							"line": 8,
							"column": 73
						}
					},
					{
						"start": {
							"line": 8,
							"column": 77
						},
						"end": {
							"line": 8,
							"column": 105
						}
					}
				],
				"line": 8
			},
			"5": {
				"loc": {
					"start": {
						"line": 16,
						"column": 4
					},
					"end": {
						"line": 16,
						"column": 61
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 16,
							"column": 4
						},
						"end": {
							"line": 16,
							"column": 61
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 16
			},
			"6": {
				"loc": {
					"start": {
						"line": 17,
						"column": 4
					},
					"end": {
						"line": 17,
						"column": 76
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 17,
							"column": 4
						},
						"end": {
							"line": 17,
							"column": 76
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 17
			},
			"7": {
				"loc": {
					"start": {
						"line": 18,
						"column": 4
					},
					"end": {
						"line": 20,
						"column": 47
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 18,
							"column": 4
						},
						"end": {
							"line": 20,
							"column": 47
						}
					},
					{
						"start": {
							"line": 19,
							"column": 9
						},
						"end": {
							"line": 20,
							"column": 47
						}
					}
				],
				"line": 18
			},
			"8": {
				"loc": {
					"start": {
						"line": 19,
						"column": 9
					},
					"end": {
						"line": 20,
						"column": 47
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 19,
							"column": 9
						},
						"end": {
							"line": 20,
							"column": 47
						}
					},
					{
						"start": {
							"line": 20,
							"column": 9
						},
						"end": {
							"line": 20,
							"column": 47
						}
					}
				],
				"line": 19
			},
			"9": {
				"loc": {
					"start": {
						"line": 24,
						"column": 4
					},
					"end": {
						"line": 24,
						"column": 24
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 24,
							"column": 4
						},
						"end": {
							"line": 24,
							"column": 24
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 24
			},
			"10": {
				"loc": {
					"start": {
						"line": 31,
						"column": 17
					},
					"end": {
						"line": 31,
						"column": 64
					}
				},
				"type": "cond-expr",
				"locations": [
					{
						"start": {
							"line": 31,
							"column": 32
						},
						"end": {
							"line": 31,
							"column": 40
						}
					},
					{
						"start": {
							"line": 31,
							"column": 43
						},
						"end": {
							"line": 31,
							"column": 64
						}
					}
				],
				"line": 31
			},
			"11": {
				"loc": {
					"start": {
						"line": 35,
						"column": 16
					},
					"end": {
						"line": 35,
						"column": 21
					}
				},
				"type": "default-arg",
				"locations": [
					{
						"start": {
							"line": 35,
							"column": 20
						},
						"end": {
							"line": 35,
							"column": 21
						}
					}
				],
				"line": 35
			},
			"12": {
				"loc": {
					"start": {
						"line": 35,
						"column": 23
					},
					"end": {
						"line": 35,
						"column": 28
					}
				},
				"type": "default-arg",
				"locations": [
					{
						"start": {
							"line": 35,
							"column": 27
						},
						"end": {
							"line": 35,
							"column": 28
						}
					}
				],
				"line": 35
			},
			"13": {
				"loc": {
					"start": {
						"line": 37,
						"column": 19
					},
					"end": {
						"line": 37,
						"column": 40
					}
				},
				"type": "cond-expr",
				"locations": [
					{
						"start": {
							"line": 37,
							"column": 27
						},
						"end": {
							"line": 37,
							"column": 32
						}
					},
					{
						"start": {
							"line": 37,
							"column": 35
						},
						"end": {
							"line": 37,
							"column": 40
						}
					}
				],
				"line": 37
			},
			"14": {
				"loc": {
					"start": {
						"line": 52,
						"column": 0
					},
					"end": {
						"line": 54,
						"column": 1
					}
				},
				"type": "if",
				"locations": [
					{
						"start": {
							"line": 52,
							"column": 0
						},
						"end": {
							"line": 54,
							"column": 1
						}
					},
					{
						"start": {},
						"end": {}
					}
				],
				"line": 52
			}
		},
		"s": {
			"0": 1,
			"1": 1,
			"2": 1,
			"3": 0,
			"4": 1,
			"5": 0,
			"6": 1,
			"7": 0,
			"8": 0,
			"9": 0,
			"10": 0,
			"11": 0,
			"12": 0,
			"13": 0,
			"14": 0,
			"15": 0,
			"16": 0,
			"17": 0,
			"18": 0,
			"19": 0,
			"20": 0,
			"21": 0,
			"22": 0,
			"23": 0,
			"24": 0,
			"25": 0,
			"26": 0,
			"27": 0,
			"28": 0,
			"29": 1,
			"30": 1,
			"31": 1,
			"32": 1,
			"33": 1,
			"34": 1,
			"35": 1,
			"36": 1,
			"37": 1,
			"38": 1,
			"39": 1,
			"40": 1,
			"41": 1,
			"42": 1,
			"43": 1
		},
		"f": {
			"0": 1,
			"1": 0,
			"2": 0,
			"3": 0,
			"4": 1,
			"5": 1,
			"6": 1,
			"7": 1,
			"8": 1
		},
		"b": {
			"0": [
				0,
				1
			],
			"1": [
				1,
				1,
				1
			],
			"2": [
				0,
				0
			],
			"3": [
				0,
				0
			],
			"4": [
				0,
				0
			],
			"5": [
				0,
				0
			],
			"6": [
				0,
				0
			],
			"7": [
				0,
				0
			],
			"8": [
				0,
				0
			],
			"9": [
				0,
				0
			],
			"10": [
				0,
				1
			],
			"11": [
				0
			],
			"12": [
				0
			],
			"13": [
				1,
				0
			],
			"14": [
				1,
				0
			]
		},
		"inputSourceMap": {
			"version": 3,
			"file": "index-UrVP7Pu3.js",
			"sources": [
				"../../src/message.ts",
				"../../src/math.ts",
				"../../src/utils/math.ts",
				"../../src/main.ts"
			],
			"names": [
				"score"
			],
			"mappings": ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAAO,SAAS,cAAc,MAAcA,QAAuB;AACjE,QAAM,SAASA,UAAS,KAAK,WAAW;AAExC,SAAO,GAAG,IAAI,IAAI,MAAM,oBAAoBA,MAAK;AACnD;ACJO,MAAM,UAAU;AAAA,EACrB,OAAO,MAAM,CAAC,IAAI,GAAG,IAAI,MAAM,IAAI;AAAA,EAEnC,OAAO,SAAS,GAAW,GAAmB;AAE5C,UAAM,SAAS,IAAI,IAAI,IAAI,IAAI,IAAI;AAEnC,WAAO;AAAA,EACT;AACF;ACTO,SAAS,SAAS,GAAW,GAAmB;AACrD,SAAO,IAAI;AACb;AAEO,SAAS,OAAO,GAAW,GAAmB;AACnD,SAAO,IAAI;AACb;ACDA,IAAI,QAAQ,UAAU,IAAI,IAAI,EAAE;AAChC,QAAQ,UAAU,SAAS,OAAO,CAAC;AACnC,QAAQ,SAAS,OAAO,CAAC;AACzB,QAAQ,OAAO,OAAO,CAAC;AACvB,MAAM,MAAM,SAAS,cAA2B,MAAM;AAEtD,IAAI,KAAK;AACP,MAAI,cAAc,cAAc,cAAc,KAAK;AACrD;"
		},
		"_coverageSchema": "40f62e0a3f979d0f1d953ad638baf3cd6b2efd49",
		"hash": "cd65be6d7de718b4c73b565ff01149c1abdfeaf7"
	}
};
});
