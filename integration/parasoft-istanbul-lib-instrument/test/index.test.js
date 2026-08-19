/* globals describe, it */
const { assert } = require('chai');
const i18n = require('../src/i18n');
const { name, version } = require('../package.json');

function loadIndex() {
    delete require.cache[require.resolve('../src/index')];
    return require('../src/index');
}

function loadIndexFromCache() {
    return require('../src/index');
}

const loadNoticeKey = Symbol.for(
    'parasoft.istanbul-lib-instrument.loadNoticeShown'
);

describe('external interface', () => {
    it('exposes the correct objects', () => {
        const index = loadIndex();
        const i = index.createInstrumenter();
        assert.ok(i);
        assert.ok(i.instrumentSync);
        assert.ok(i.instrument);
        const pc = index.programVisitor;
        assert.ok(pc);
        assert.isFunction(pc);
    });
});

describe('instrumenter', () => {
    it('should remove comments when asked to', function() {
        // This test has frequent timeout on Windows.
        this.timeout(5000);

        const index = loadIndex();
        const instrumenter = index.createInstrumenter({
            preserveComments: false
        });
        const instrumentedCode = instrumenter.instrumentSync(
            '/*foo*/\n//bar\ncode = true',
            'somefile.js'
        );
        assert.equal(
            instrumentedCode.indexOf('foo'),
            -1,
            'block comment not removed'
        );
        assert.equal(
            instrumentedCode.indexOf('bar'),
            -1,
            'line comment not removed'
        );
    });

    it('logs a load notice once when the module is required', () => {
        const originalInfo = console.info;
        const originalNoticeState = global[loadNoticeKey];
        const notices = [];
        console.info = message => {
            notices.push(message);
        };

        try {
            global[loadNoticeKey] = false;
            const index = loadIndex();
            assert.ok(index);
            loadIndexFromCache();
        } finally {
            console.info = originalInfo;
            if (originalNoticeState === undefined) {
                delete global[loadNoticeKey];
            } else {
                global[loadNoticeKey] = originalNoticeState;
            }
        }

        assert.deepEqual(notices, [i18n.t('load_notice', { name, version })]);
    });
});
