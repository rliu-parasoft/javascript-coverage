import i18next from 'i18next';
import en from './locales/en.json' with { type: 'json' };
import zh from './locales/zh.json' with { type: 'json' };

function getLocale(): 'en' | 'zh' {
    const locale = Intl.DateTimeFormat().resolvedOptions().locale.toLowerCase();
    return locale.startsWith('zh') ? 'zh' : 'en';
}

const i18n = i18next.createInstance();
i18n.init({
    lng: getLocale(),
    fallbackLng: 'en',
    resources: {
        en: { translation: en },
        zh: { translation: zh }
    },
    interpolation: { escapeValue: false }
});

export default i18n;
