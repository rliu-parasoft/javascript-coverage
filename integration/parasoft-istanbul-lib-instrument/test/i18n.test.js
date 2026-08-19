/* globals describe, it */

const { assert } = require('chai');
const en = require('../src/locales/en.json');
const zh = require('../src/locales/zh.json');

function loadI18n(locale) {
    const i18nPath = require.resolve('../src/i18n');
    const dateTimeFormat = Intl.DateTimeFormat;

    try {
        Intl.DateTimeFormat = () => ({ resolvedOptions: () => ({ locale }) });
        delete require.cache[i18nPath];
        return require('../src/i18n');
    } finally {
        Intl.DateTimeFormat = dateTimeFormat;
        delete require.cache[i18nPath];
    }
}

describe('localization', () => {
    it('selects Chinese resources, falls back to English, and keeps resource keys aligned', () => {
        const i18n = loadI18n('zh-CN');

        assert.strictEqual(i18n.language, 'zh');
        assert.strictEqual(
            i18n.t('load_notice', { name: 'instrument', version: '1.0.0' }),
            zh.load_notice.replace('{{name}}', 'instrument').replace('{{version}}', '1.0.0')
        );
        assert.deepEqual(Object.keys(zh).sort(), Object.keys(en).sort());

        i18n.addResource('en', 'translation', 'test_only_english_fallback', 'English fallback');
        assert.strictEqual(i18n.t('test_only_english_fallback'), 'English fallback');
    });
});
