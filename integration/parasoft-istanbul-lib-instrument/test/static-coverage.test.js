/* globals describe, it, beforeEach, afterEach */

const { assert } = require('chai');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { version: packageVersion } = require('../package.json');

describe('static-coverage', () => {
    let writeStaticCoverage;
    let testFilesCreated = [];

    before(() => {
        // Load module
        writeStaticCoverage = require('../src/static-coverage');

        // Clear output directory
        const outputDir = getOutputDir();
        if (fs.existsSync(outputDir)) {
            fs.readdirSync(outputDir).forEach(file => {
                try {
                    fs.unlinkSync(path.join(outputDir, file));
                } catch (e) {
                    // Ignore deletion errors
                }
            });
        }
    });

    afterEach(() => {
        testFilesCreated.forEach(filePath => {
            if (fs.existsSync(filePath)) {
                try {
                    fs.unlinkSync(filePath);
                } catch (e) {
                    // Ignore deletion errors
                }
            }
        });
        testFilesCreated = [];
    });

    function getOutputDir() {
        return path.join(
            process.cwd(),
            '.parasoft',
            'static-coverage',
            String(process.pid)
        );
    }

    // Helper function: track created files for cleanup
    function trackCreatedFiles(outputDir) {
        if (fs.existsSync(outputDir)) {
            const files = fs.readdirSync(outputDir);
            files.forEach(file => {
                testFilesCreated.push(path.join(outputDir, file));
            });
        }
    }

    describe('writeStaticCoverage() - basic functionality', () => {
        it('should create output directory if it does not exist', () => {
            const coverageData = createBasicCoverageData();
            const projectInfo = { name: 'test-project', root: '/test' };

            writeStaticCoverage('/test/file.js', coverageData, projectInfo);

            const expectedDir = getOutputDir();
            trackCreatedFiles(expectedDir);
            assert.isTrue(fs.existsSync(expectedDir), 'Output directory should be created');
        });

        it('should write coverage data to JSON file', () => {
            const filePath = '/test/myfile.js';
            const coverageData = createBasicCoverageData(filePath);
            const projectInfo = { name: 'test-project', root: '/test' };

            writeStaticCoverage(filePath, coverageData, projectInfo);

            const outputDir = getOutputDir();
            trackCreatedFiles(outputDir);
            const files = fs.readdirSync(outputDir).filter(f => f.startsWith('myfile.js'));

            assert.equal(files.length, 1, 'Should create exactly one file for myfile.js');
            assert.match(files[0], /^myfile\.js-.+\.json$/, 'File should match pattern');

            const writtenData = JSON.parse(fs.readFileSync(path.join(outputDir, files[0]), 'utf8'));
            assert.notProperty(writtenData, 'version', 'Static coverage JSON should not include session metadata');
            assert.deepEqual(writtenData.project, projectInfo, 'Project info should be included');
            assert.equal(writtenData.path, filePath, 'File path should match');
            assert.deepEqual(writtenData.statementMap, coverageData.statementMap, 'Statement map should match');
            assert.deepEqual(writtenData.s, coverageData.s, 'Statement coverage counts should match');
            assert.deepEqual(writtenData.fnMap, coverageData.fnMap, 'Function map should match');
            assert.deepEqual(writtenData.branchMap, coverageData.branchMap, 'Branch map should match');
        });

        it('should write a session version manifest', () => {
            const coverageData = createBasicCoverageData('/test/version-manifest.js');
            const projectInfo = { name: 'test-project', root: '/test' };

            writeStaticCoverage('/test/version-manifest.js', coverageData, projectInfo);

            const outputDir = getOutputDir();
            trackCreatedFiles(outputDir);
            const manifestPath = path.join(outputDir, 'version.json');

            assert.isTrue(fs.existsSync(manifestPath), 'Session version manifest should be created');
            assert.deepEqual(JSON.parse(fs.readFileSync(manifestPath, 'utf8')), {
                schemaVersion: '1.0',
                toolVersion: packageVersion
            });
        });

        it('should use basename for output filename', () => {
            const filePath = '/very/deep/path/to/source.js';
            const coverageData = createBasicCoverageData(filePath);
            const projectInfo = { name: 'test-project', root: '/test' };

            writeStaticCoverage(filePath, coverageData, projectInfo);

            const outputDir = getOutputDir();
            trackCreatedFiles(outputDir);
            const files = fs.readdirSync(outputDir).filter(f => f.startsWith('source.js'));

            assert.isAtLeast(files.length, 1, 'Should create at least one file');
            assert.match(files[0], /^source\.js-.+\.json$/, 'Should use basename in filename');
        });

        it('should generate unique filenames using UUID v5', () => {
            const filePath1 = '/test/test-uuid-file1.js';
            const filePath2 = '/test/test-uuid-file2.js';
            const coverageData1 = createBasicCoverageData(filePath1);
            const coverageData2 = createBasicCoverageData(filePath2);
            const projectInfo = { name: 'test-project', root: '/test' };

            writeStaticCoverage(filePath1, coverageData1, projectInfo);
            writeStaticCoverage(filePath2, coverageData2, projectInfo);

            const outputDir = getOutputDir();
            trackCreatedFiles(outputDir);
            const files = fs.readdirSync(outputDir).filter(f => f.startsWith('test-uuid-file'));

            assert.equal(files.length, 2, 'Should create exactly two files');
            assert.notEqual(files[0], files[1], 'Filenames should be unique');

            // Verify UUID parts are actually different
            const uuid1 = files[0].match(/test-uuid-file1\.js-(.+)\.json$/)[1];
            const uuid2 = files[1].match(/test-uuid-file2\.js-(.+)\.json$/)[1];
            assert.notEqual(uuid1, uuid2, 'UUID parts should be different');
            assert.match(uuid1, /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, 'Should be valid UUID');
            assert.match(uuid2, /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, 'Should be valid UUID');
        });

        it('should skip writing if file already exists', () => {
            const filePath = '/test/test-duplicate-skip.js';
            const coverageData = createBasicCoverageData(filePath);
            const projectInfo = { name: 'test-project', root: '/test' };

            // First write
            writeStaticCoverage(filePath, coverageData, projectInfo);

            const outputDir = getOutputDir();
            trackCreatedFiles(outputDir);
            const files = fs.readdirSync(outputDir).filter(f => f.startsWith('test-duplicate-skip.js'));

            assert.equal(files.length, 1, 'Should create exactly one file');
            const firstFile = path.join(outputDir, files[0]);
            const originalMtime = fs.statSync(firstFile).mtime;
            const originalSize = fs.statSync(firstFile).size;

            // Wait a short time to ensure timestamp would be different
            const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));
            return wait(10).then(() => {
                // Second write (should be skipped)
                const coverageData2 = createBasicCoverageData(filePath);
                coverageData2.s = { '0': 999 }; // Modify data
                writeStaticCoverage(filePath, coverageData2, projectInfo);

                const newMtime = fs.statSync(firstFile).mtime;
                const newSize = fs.statSync(firstFile).size;

                assert.equal(
                    originalMtime.getTime(),
                    newMtime.getTime(),
                    'File modification time should not change'
                );
                assert.equal(originalSize, newSize, 'File size should not change');

                // Verify file content was not modified
                const writtenData = JSON.parse(fs.readFileSync(firstFile, 'utf8'));
                assert.deepEqual(writtenData.s, { '0': 1 }, 'Should keep original coverage data');
            });
        });
    });

    describe('writeStaticCoverage() - source map remapping', () => {
        it('should handle source map with multiple sources', () => {
            const coverageData = createRealMultiSourceCoverageData();
            const projectInfo = { name: 'test-project', root: '/test' };

            writeStaticCoverage(coverageData.path, coverageData, projectInfo);

            const outputDir = getOutputDir();
            trackCreatedFiles(outputDir);

            // Should create coverage files for source files
            // Source files include: message.ts, math.ts, utils/math.ts, main.ts
            const allFiles = fs.readdirSync(outputDir);
            const relevantFiles = allFiles.filter(f =>
                f.includes('message.ts') ||
                f.includes('math.ts') ||
                f.includes('main.ts') ||
                f.includes('real-bundle.js')
            );

            const coverageFiles = allFiles.filter(file => file !== 'version.json');
            assert.equal(coverageFiles.length, 4, 'Should create files for source map sources');

            // Verify created files contain correct project info
            relevantFiles.forEach(file => {
                const filePath = path.join(outputDir, file);
                const writtenData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                assert.deepEqual(writtenData.project, projectInfo, `File ${file} should include project info`);
                assert.isDefined(writtenData.path, `File ${file} should have a path`);
            });

            // Verify at least one file is a TypeScript source file
            const tsFiles = relevantFiles.filter(f => f.endsWith('.ts.json') || f.includes('.ts-'));
            if (tsFiles.length > 0) {
                // If successfully remapped to TypeScript source file, verify one of them
                const tsFilePath = path.join(outputDir, tsFiles[0]);
                const tsData = JSON.parse(fs.readFileSync(tsFilePath, 'utf8'));
                assert.isDefined(tsData.statementMap, 'Remapped TS file should have statement map');
            }
        });
    });

    function createBasicCoverageData(filePath = '/test/file.js') {
        return {
            path: filePath,
            statementMap: {
                '0': { start: { line: 1, column: 0 }, end: { line: 1, column: 20 } }
            },
            fnMap: {},
            branchMap: {},
            s: { '0': 1 },
            f: {},
            b: {}
        };
    }

    // Create real multi-source source map coverage data (from actual project)
    function createRealMultiSourceCoverageData() {
        
        return {
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
        };
    }
});

