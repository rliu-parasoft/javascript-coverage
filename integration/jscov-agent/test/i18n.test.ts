import { afterEach, describe, expect, it, vi } from 'vitest';
import en from '../src/locales/en.json' with { type: 'json' };
import zh from '../src/locales/zh.json' with { type: 'json' };

async function loadI18n(locale: string) {
    vi.resetModules();
    vi.spyOn(Intl, 'DateTimeFormat').mockReturnValue({
        resolvedOptions: () => ({ locale })
    } as Intl.DateTimeFormat);
    return (await import('../src/i18n.js')).default;
}

afterEach(() => {
    vi.restoreAllMocks();
    vi.resetModules();
});

describe('localization', () => {
    it('selects Chinese resources, falls back to English, and keeps resource keys aligned', async () => {
        const i18n = await loadI18n('zh-CN');

        expect(i18n.language).toBe('zh');
        expect(i18n.t('agent_started', { port: 8050 }))
            .toBe(zh.agent_started.replace('{{port}}', '8050'));
        expect(Object.keys(zh).sort()).toEqual(Object.keys(en).sort());

        i18n.addResource('en', 'translation', 'test_only_english_fallback', 'English fallback');
        expect(i18n.t('test_only_english_fallback')).toBe('English fallback');
    });
});
