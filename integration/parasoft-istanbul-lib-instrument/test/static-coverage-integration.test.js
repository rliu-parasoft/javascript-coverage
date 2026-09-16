/* globals describe, it, afterEach */

const { assert } = require('chai');
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const i18n = require('../src/i18n');
const { name: packageName } = require('../package.json');

const instrumenterPath = path.resolve(__dirname, '../src/index');

describe('static coverage integration', function() {
    this.timeout(5000);

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
        const inputSourceMap = Object.prototype.hasOwnProperty.call(options, 'inputSourceMap')
            ? JSON.stringify(options.inputSourceMap)
            : 'undefined';
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
            'index.createInstrumenter().instrumentSync(' +
                JSON.stringify(code) +
                ", 'source.js', " +
                inputSourceMap +
                ');'
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

    ['false', '1', 'yes', ''].forEach(environmentValue => {
        it(`does not create static coverage output for ${JSON.stringify(environmentValue)}`, () => {
            const directory = createTempDirectory();

            instrumentInChild(directory, environmentValue);

            assert.isFalse(fs.existsSync(path.join(directory, '.parasoft')));
        });
    });

    ['TRUE', 'True', 'tRuE'].forEach(environmentValue => {
        it(`creates static coverage output for ${JSON.stringify(environmentValue)}`, () => {
            const directory = createTempDirectory();

            instrumentInChild(directory, environmentValue);

            assert.isTrue(
                fs.existsSync(
                    path.join(directory, '.parasoft', 'static-coverage')
                )
            );
        });
    });

    it('creates the existing static coverage output for the true value', () => {
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
        assert.include(files, 'version.json');
        const coverageFiles = files.filter(file => file !== 'version.json');
        assert.lengthOf(coverageFiles, 1);
        assert.match(coverageFiles[0], /^source\.js-.+\.json$/);
    });

    it('captures the environment value when the visitor loads', function() {
        this.timeout(5000);

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
        assert.include(files, 'version.json');
        const coverageFiles = files.filter(file => file !== 'version.json');
        assert.lengthOf(coverageFiles, 1);
        assert.match(coverageFiles[0], /^source\.js-.+\.json$/);
    });

    it('fails instrumentation when static coverage remapping fails', () => {
        const directory = createTempDirectory();
        let failure;

        try {
            instrumentInChild(directory, 'true', {
                inputSourceMap: {}
            });
        } catch (error) {
            failure = error;
        }

        assert.instanceOf(failure, Error);

        const stderr = failure.stderr.toString();
        const expectedPrefix = i18n.t('coverage_remap_failed', {
            name: packageName,
            path: 'source.js',
            reason: ''
        }).trim();
        assert.include(stderr, expectedPrefix);

        const coverageRoot = path.join(
            directory,
            '.parasoft',
            'static-coverage'
        );
        assert.isTrue(fs.existsSync(coverageRoot));

        const snapshotFiles = fs.readdirSync(coverageRoot).flatMap(processDirectory =>
            fs.readdirSync(path.join(coverageRoot, processDirectory))
                .filter(file => file !== 'version.json')
        );
        assert.lengthOf(snapshotFiles, 0);
    });
});
