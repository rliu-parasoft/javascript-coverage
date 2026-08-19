const fs = require('fs');
const path = require('path');
const { name, version: toolVersion } = require('../package.json');
const { v5: uuidv5 } = require('uuid');
const { TraceMap } = require('@jridgewell/trace-mapping');
const { SourceMapTransformer } = require('istanbul-lib-source-maps/lib/transformer');
const { MappedCoverage } = require('istanbul-lib-source-maps/lib/mapped');
const libCoverage = require('istanbul-lib-coverage');
const i18n = require('./i18n');
const debug = require('debug')(name);

let outputDir;
const SCHEMA_VERSION = '1.0';
const VERSION_FILE_NAME = 'version.json';

function ensureOutputDirAndCreateVersionFile() {
    if (!outputDir) {
        outputDir = path.join(
            process.cwd(),
            '.parasoft',
            'static-coverage',
            String(process.pid)
        );
    }

    fs.mkdirSync(outputDir, { recursive: true });

    const versionFilePath = path.join(outputDir, VERSION_FILE_NAME);
    if (!fs.existsSync(versionFilePath)) {
        fs.writeFileSync(versionFilePath, JSON.stringify({
            schemaVersion: SCHEMA_VERSION,
            toolVersion
        }));
    }
}

function remapCoverageData(coverageData) {
    if (!coverageData.inputSourceMap) {
        return [coverageData];
    }

    try {
        const sourceMap = new TraceMap(coverageData.inputSourceMap);
        const transformer = new SourceMapTransformer(null);

        const uniqueFiles = {};
        const getMappedCoverage = (file) => {
            if (!uniqueFiles[file]) {
                uniqueFiles[file] = new MappedCoverage(file);
            }
            return uniqueFiles[file];
        };

        const fc = libCoverage.createFileCoverage(coverageData);
        transformer.processFile(fc, sourceMap, getMappedCoverage);

        const mappedFiles = Object.keys(uniqueFiles);
        if (mappedFiles.length > 0) {
            return mappedFiles.map(file => uniqueFiles[file].toJSON());
        }
    } catch (e) {
        debug(i18n.t('coverage_remap_failed', {
            path: coverageData.path,
            reason: e.message
        }));
    }

    return [coverageData];
}

function writeStaticCoverage(sourceFilePath, coverageData, projectInfo) {
    ensureOutputDirAndCreateVersionFile();

    const mappedCoverageList = remapCoverageData(coverageData);

    for (const mapped of mappedCoverageList) {
        const filePath = mapped.path || sourceFilePath;
        const fileName = path.basename(filePath);
        const outputFile = path.join(
                outputDir,
                `${fileName}-${uuidv5(filePath, uuidv5.URL)}.json`
            );

        if (fs.existsSync(outputFile)) {
            debug(i18n.t('coverage_skip_written', { path: filePath }));
            continue;
        }

        debug(i18n.t('static_coverage_write', {path: filePath, output: outputFile}));
        fs.writeFileSync(
            outputFile,
            JSON.stringify({
                ...mapped,
                project: projectInfo
            })
        );
    }
}

module.exports = writeStaticCoverage;
