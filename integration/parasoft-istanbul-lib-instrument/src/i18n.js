const i18next = require('i18next');
const english = require('./locales/en.json');
const chinese = require('./locales/zh.json');

function getLocale() {
    return Intl.DateTimeFormat().resolvedOptions().locale.toLowerCase().startsWith('zh')
        ? 'zh'
        : 'en';
}

const i18n = i18next.createInstance();
i18n.init({
    lng: getLocale(),
    fallbackLng: 'en',
    resources: {
        en: { translation: english },
        zh: { translation: chinese }
    },
    interpolation: { escapeValue: false }
});

module.exports = i18n;
