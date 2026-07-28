/* globals describe, it, beforeEach, afterEach */

const { assert } = require('chai');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { map } = require('../src/project-path-mapper');

describe('project-path-mapper', () => {
    let tempDir;
    let originalCwd;

    beforeEach(() => {
        originalCwd = process.cwd();
        
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'mapper-test-'));
    });

    afterEach(() => {
        process.cwd = () => originalCwd;
        
        if (tempDir && fs.existsSync(tempDir)) {
            removeDir(tempDir);
        }
    });

    function removeDir(dir) {
        if (fs.existsSync(dir)) {
            fs.readdirSync(dir).forEach((file) => {
                const curPath = path.join(dir, file);
                if (fs.lstatSync(curPath).isDirectory()) {
                    removeDir(curPath);
                } else {
                    fs.unlinkSync(curPath);
                }
            });
            fs.rmdirSync(dir);
        }
    }

    function createTestStructure(structure, basePath = tempDir) {
        for (const [name, content] of Object.entries(structure)) {
            const fullPath = path.join(basePath, name);
            if (typeof content === 'object' && content !== null) {
                // Create directory and sub-structure
                if (!fs.existsSync(fullPath)) {
                    fs.mkdirSync(fullPath, { recursive: true });
                }
                createTestStructure(content, fullPath);
            } else {
                // Create file
                fs.writeFileSync(fullPath, content, 'utf8');
            }
        }
    }

    function setCwd(dir) {
        process.cwd = () => dir;
    }

    describe('map() - basic functionality', () => {
        it('should return undefined for invalid inputs', () => {
            setCwd(tempDir);
            assert.isUndefined(map(null));
            assert.isUndefined(map(undefined));
            assert.isUndefined(map(123));
            assert.isUndefined(map({}));
            assert.isUndefined(map(''));
        });

        it('should find package.json in the same directory', () => {
            const packageJson = {
                name: 'test-project',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'test-project');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });

        it('should find package.json in parent directory', () => {
            const packageJson = {
                name: 'parent-project',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'lib': {
                        'utils': {
                            'helper.js': 'module.exports = {};'
                        }
                    }
                }
            });

            setCwd(tempDir);
            const result = map('src/lib/utils/helper.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'parent-project');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });

        it('should handle absolute paths', () => {
            const packageJson = {
                name: 'absolute-test',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'file.js': 'module.exports = {};'
            });

            setCwd(tempDir);
            const absolutePath = path.join(tempDir, 'file.js');
            const result = map(absolutePath);
            
            assert.isNotNull(result);
            assert.equal(result.name, 'absolute-test');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });

        it('should fallback to working directory when no package.json found', () => {
            createTestStructure({
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, path.basename(tempDir));
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });
    });

    describe('map() - nested package.json', () => {
        it('should find the closest package.json', () => {
            const rootPackageJson = {
                name: 'root-project',
                version: '1.0.0'
            };
            
            const nestedPackageJson = {
                name: 'nested-project',
                version: '2.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(rootPackageJson),
                'packages': {
                    'nested': {
                        'package.json': JSON.stringify(nestedPackageJson),
                        'src': {
                            'index.js': 'console.log("nested");'
                        }
                    }
                }
            });

            setCwd(tempDir);
            const result = map('packages/nested/src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'nested-project');
            assert.equal(
                result.root,
                path.join(tempDir, 'packages', 'nested').replace(/\\/g, '/')
            );
        });

        it('should not search above working directory', () => {
            // Search in a subdirectory of the working directory
            const subDir = path.join(tempDir, 'workspace');
            fs.mkdirSync(subDir);
            
            createTestStructure({
                'src': {
                    'file.js': 'console.log("test");'
                }
            }, subDir);

            setCwd(subDir);
            const result = map('src/file.js');
            
            assert.isNotNull(result);
            // Should fall back to working directory
            assert.equal(result.name, path.basename(subDir));
            assert.equal(result.root, subDir.replace(/\\/g, '/'));
        });
    });

    describe('map() - caching mechanism', () => {
        it('should cache results for subsequent calls', () => {
            const packageJson = {
                name: 'cached-project',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'file1.js': 'module.exports = {};',
                    'file2.js': 'module.exports = {};'
                }
            });

            setCwd(tempDir);
            
            // Create spy to monitor fs.existsSync calls
            const originalExistsSync = fs.existsSync;
            let existsSyncCallCount = 0;
            fs.existsSync = function(...args) {
                existsSyncCallCount++;
                return originalExistsSync.apply(fs, args);
            };

            // Create spy to monitor fs.readFileSync calls
            const originalReadFileSync = fs.readFileSync;
            let readFileSyncCallCount = 0;
            fs.readFileSync = function(...args) {
                readFileSyncCallCount++;
                return originalReadFileSync.apply(fs, args);
            };

            try {
                const result1 = map('src/file1.js');
                const firstExistsCount = existsSyncCallCount;
                const firstReadCount = readFileSyncCallCount;
                
                const result2 = map('src/file2.js');
                const secondExistsCount = existsSyncCallCount - firstExistsCount;
                const secondReadCount = readFileSyncCallCount - firstReadCount;
                
                // Verify results are the same
                assert.isNotNull(result1);
                assert.isNotNull(result2);
                assert.equal(result1.name, result2.name);
                assert.equal(result1.root, result2.root);
                assert.equal(result1.name, 'cached-project');
                
                // Verify second call didn't read package.json (used cache)
                // First call should read package.json
                assert.isAbove(firstReadCount, 0, 'First call should read package.json');
                // Second call should use cache and not read package.json
                assert.equal(secondReadCount, 0, 'Second call should use cache and not read package.json');
                // Second call may still check if files exist, but shouldn't read file contents
                assert.isBelow(secondExistsCount, firstExistsCount, 'Second call should make fewer existsSync calls due to caching');
            } finally {
                // Restore original methods
                fs.existsSync = originalExistsSync;
                fs.readFileSync = originalReadFileSync;
            }
        });

        it('should use cache for files in different subdirectories', () => {
            const packageJson = {
                name: 'multi-dir-project',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'lib': {
                        'utils.js': 'module.exports = {};'
                    },
                    'components': {
                        'button.js': 'module.exports = {};'
                    }
                }
            });

            setCwd(tempDir);
            
            // Create spy to monitor fs.readFileSync calls
            const originalReadFileSync = fs.readFileSync;
            let readFileSyncCallCount = 0;
            fs.readFileSync = function(...args) {
                readFileSyncCallCount++;
                return originalReadFileSync.apply(fs, args);
            };

            try {
                const result1 = map('src/lib/utils.js');
                const firstReadCount = readFileSyncCallCount;
                
                const result2 = map('src/components/button.js');
                const secondReadCount = readFileSyncCallCount - firstReadCount;
                
                // Verify results are the same
                assert.isNotNull(result1);
                assert.isNotNull(result2);
                assert.equal(result1.name, 'multi-dir-project');
                assert.equal(result2.name, 'multi-dir-project');
                assert.equal(result1.root, result2.root);
                
                // Verify second call used cache
                assert.isAbove(firstReadCount, 0, 'First call should read package.json');
                assert.equal(secondReadCount, 0, 'Second call should use cache and not read package.json again');
            } finally {
                // Restore original method
                fs.readFileSync = originalReadFileSync;
            }
        });
    });

    describe('map() - edge cases', () => {
        it('should handle package.json without name property', () => {
            const packageJson = {
                version: '1.0.0',
                description: 'no name'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'unknown');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });

        it('should handle malformed package.json', () => {
            createTestStructure({
                'package.json': '{ invalid json',
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'unknown');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });

        it('should handle relative paths', () => {
            const packageJson = {
                name: 'relative-test',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('./src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'relative-test');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });

        it('should convert Windows paths to portable format', () => {
            const packageJson = {
                name: 'windows-path-test',
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('src\\index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'windows-path-test');
            // Ensure path uses forward slashes
            assert.notInclude(result.root, '\\');
            assert.include(result.root, '/');
        });

        it('should handle package.json with non-string name', () => {
            const packageJson = {
                name: 123,
                version: '1.0.0'
            };
            
            createTestStructure({
                'package.json': JSON.stringify(packageJson),
                'src': {
                    'index.js': 'console.log("test");'
                }
            });

            setCwd(tempDir);
            const result = map('src/index.js');
            
            assert.isNotNull(result);
            assert.equal(result.name, 'unknown');
            assert.equal(result.root, tempDir.replace(/\\/g, '/'));
        });
    });

    describe('map() - multiple project roots', () => {
        it('should correctly identify different project roots', () => {
            const project1Json = {
                name: 'project-1',
                version: '1.0.0'
            };
            
            const project2Json = {
                name: 'project-2',
                version: '2.0.0'
            };
            
            createTestStructure({
                'projects': {
                    'project1': {
                        'package.json': JSON.stringify(project1Json),
                        'src': {
                            'index.js': 'console.log("p1");'
                        }
                    },
                    'project2': {
                        'package.json': JSON.stringify(project2Json),
                        'src': {
                            'index.js': 'console.log("p2");'
                        }
                    }
                }
            });

            setCwd(tempDir);
            
            const result1 = map('projects/project1/src/index.js');
            const result2 = map('projects/project2/src/index.js');
            
            assert.isNotNull(result1);
            assert.isNotNull(result2);
            assert.equal(result1.name, 'project-1');
            assert.equal(result2.name, 'project-2');
            assert.notEqual(result1.root, result2.root);
        });
    });
});
