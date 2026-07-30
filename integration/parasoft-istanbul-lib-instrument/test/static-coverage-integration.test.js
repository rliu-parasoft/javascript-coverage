/* globals describe, it, afterEach */

const { assert } = require('chai');
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const instrumenterPath = path.resolve(__dirname, '../src/index');

describe('static coverage integration', () => {
    const tempDirectories = [];

    afterEach(() => {
        for (const directory of tempDirectories.splice(0)) {
            removeDirectory(directory);
        }
    });

    function createTempDirectory() {
        const directory = fs.mkdtempSync(
            path.join(os.tmpdir(), 'static-coverage-integration-')
        );
        tempDirectories.push(directory);
        return directory;
    }

    function removeDirectory(directory) {
        if (!fs.existsSync(directory)) {
            return;
        }
        for (const entry of fs.readdirSync(directory)) {
            const entryPath = path.join(directory, entry);
            if (fs.lstatSync(entryPath).isDirectory()) {
                removeDirectory(entryPath);
            } else {
                fs.unlinkSync(entryPath);
            }
        }
        fs.rmdirSync(directory);
    }

    function instrumentInChild(directory, environmentValue, options = {}) {
        const childEnv = { ...process.env };
        if (environmentValue === undefined) {
            delete childEnv.PARASOFT_STATIC_COVERAGE_ENABLE;
        } else {
            childEnv.PARASOFT_STATIC_COVERAGE_ENABLE = environmentValue;
        }

        const { code = 'const value = 1;' } = options;
        const script = [`const index = require(${JSON.stringify(instrumenterPath)});`];
        if (Object.prototype.hasOwnProperty.call(options, 'environmentValueAfterLoad')) {
            const value = options.environmentValueAfterLoad;
            script.push(
                value === null
                    ? 'delete process.env.PARASOFT_STATIC_COVERAGE_ENABLE;'
                    : `process.env.PARASOFT_STATIC_COVERAGE_ENABLE = ${JSON.stringify(value)};`
            );
        }
        script.push(
            `index.createInstrumenter().instrumentSync(${JSON.stringify(code)}, 'source.js');`
        );

        execFileSync(process.execPath, ['-e', script.join('\n')], {
            cwd: directory,
            env: childEnv,
            stdio: 'pipe'
        });
    }

    it('does not create static coverage output when the flag is absent', () => {
        const directory = createTempDirectory();

        instrumentInChild(directory, undefined);

        assert.isFalse(fs.existsSync(path.join(directory, '.parasoft')));
    });

    ['false', 'TRUE', '1', 'yes', ''].forEach(environmentValue => {
        it(`does not create static coverage output for ${JSON.stringify(environmentValue)}`, () => {
            const directory = createTempDirectory();

            instrumentInChild(directory, environmentValue);

            assert.isFalse(fs.existsSync(path.join(directory, '.parasoft')));
        });
    });

    it('creates the existing static coverage output for the exact true value', () => {
        const directory = createTempDirectory();

        instrumentInChild(directory, 'true');

        const coverageRoot = path.join(
            directory,
            '.parasoft',
            'static-coverage'
        );
        assert.isTrue(fs.existsSync(coverageRoot));
        const processDirectories = fs.readdirSync(coverageRoot);
        assert.lengthOf(processDirectories, 1);
        const outputDirectory = path.join(
            coverageRoot,
            processDirectories[0]
        );
        const files = fs.readdirSync(outputDirectory);
        assert.lengthOf(files, 1);
        assert.match(files[0], /^source\.js-.+\.json$/);
    });

    it('captures the environment value when the visitor loads', () => {
        const disabledDirectory = createTempDirectory();
        instrumentInChild(disabledDirectory, undefined, {
            environmentValueAfterLoad: 'true'
        });
        assert.isFalse(fs.existsSync(path.join(disabledDirectory, '.parasoft')));

        const enabledDirectory = createTempDirectory();
        instrumentInChild(enabledDirectory, 'true', {
            environmentValueAfterLoad: 'false'
        });
        assert.isTrue(
            fs.existsSync(
                path.join(enabledDirectory, '.parasoft', 'static-coverage')
            )
        );
    });

    it('creates static coverage for a file ignored by Istanbul when enabled', () => {
        const directory = createTempDirectory();

        instrumentInChild(directory, 'true', {
            code: '/* istanbul ignore file */\nconst value = 1;'
        });

        const coverageRoot = path.join(
            directory,
            '.parasoft',
            'static-coverage'
        );
        assert.isTrue(fs.existsSync(coverageRoot));
        const processDirectories = fs.readdirSync(coverageRoot);
        assert.lengthOf(processDirectories, 1);
        const outputDirectory = path.join(
            coverageRoot,
            processDirectories[0]
        );
        const files = fs.readdirSync(outputDirectory);
        assert.lengthOf(files, 1);
        assert.match(files[0], /^source\.js-.+\.json$/);
    });
});
