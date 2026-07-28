const fs = require('fs');
const path = require('path');
const { name } = require('../package.json');
const { v5: uuidv5 } = require('uuid');
const { TraceMap } = require('@jridgewell/trace-mapping');
const { SourceMapTransformer } = require('istanbul-lib-source-maps/lib/transformer');
const { MappedCoverage } = require('istanbul-lib-source-maps/lib/mapped');
const libCoverage = require('istanbul-lib-coverage');
const debug = require('debug')(name);

let outputDir;

function ensureOutputDir() {
    if (!outputDir) {
        outputDir = path.join(
            process.cwd(),
            '.parasoft',
            'static-coverage',
            String(process.pid)
        );
        fs.mkdirSync(outputDir, { recursive: true });
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
        debug('[WARNING] Failed to remap coverage for %s: %s', coverageData.path, e.message);
    }

    return [coverageData];
}

function writeStaticCoverage(sourceFilePath, coverageData, projectInfo) {
    ensureOutputDir();

    const mappedCoverageList = remapCoverageData(coverageData);

    for (const mapped of mappedCoverageList) {
        const filePath = mapped.path || sourceFilePath;
        const fileName = path.basename(filePath);
        const outputFile = path.join(
                outputDir,
                `${fileName}-${uuidv5(filePath, uuidv5.URL)}.json`
            );

        if (fs.existsSync(outputFile)) {
            debug('Skipping already written coverage for %s', filePath);
            continue;
        }

        debug('Writing static coverage for %s to %s', filePath, outputFile);
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
