globalThis.__coverage__ = {
    '/fixture.js': { s: { '0': 3 }, f: { '0': 2 }, b: { '0': [4, 5] }, bT: { '0': [6, 7] } }
};

console.log('AUT_COVERAGE_READY');
process.stdin.setEncoding('utf8');
process.stdin.on('data', (data) => {
    if (data.includes('REPORT_COVERAGE')) {
        console.log(`AUT_COVERAGE:${JSON.stringify(globalThis.__coverage__)}`);
    }
});
setInterval(() => undefined, 1_000);
