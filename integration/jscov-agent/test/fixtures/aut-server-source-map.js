const generatedPath = 'C:\\project\\dist\\bundle.js';
const firstSourcePath = 'C:\\project\\src\\first.ts';
const secondSourcePath = 'C:\\project\\src\\second.ts';

const firstLocation = {
    start: { line: 1, column: 0 },
    end: { line: 1, column: 5 }
};
const secondLocation = {
    start: { line: 2, column: 0 },
    end: { line: 2, column: 5 }
};

globalThis.__coverage__ = {
    [generatedPath]: {
        path: generatedPath,
        statementMap: { '0': firstLocation, '1': secondLocation },
        fnMap: {
            '0': { name: 'first', decl: firstLocation, loc: firstLocation },
            '1': { name: 'second', decl: secondLocation, loc: secondLocation }
        },
        branchMap: {
            '0': { type: 'if', line: 1, loc: firstLocation, locations: [firstLocation, firstLocation] },
            '1': { type: 'if', line: 2, loc: secondLocation, locations: [secondLocation, secondLocation] }
        },
        s: { '0': 0, '1': 0 },
        f: { '0': 0, '1': 0 },
        b: { '0': [0, 0], '1': [0, 0] },
        inputSourceMap: {
            version: 3,
            file: generatedPath,
            sources: [firstSourcePath, secondSourcePath],
            names: [],
            mappings: 'AAAA;ACAA'
        }
    }
};

console.log('AUT_SOURCE_MAP_READY');
process.stdin.setEncoding('utf8');
process.stdin.on('data', (data) => {
    if (data.includes('SET_COVERAGE')) {
        const coverage = globalThis.__coverage__[generatedPath];
        coverage.s['0'] = 3;
        coverage.s['1'] = 4;
        coverage.f['0'] = 5;
        coverage.f['1'] = 6;
        coverage.b['0'] = [7, 0];
        coverage.b['1'] = [8, 0];
        console.log('AUT_SOURCE_MAP_UPDATED');
    }
});
setInterval(() => undefined, 1_000);
