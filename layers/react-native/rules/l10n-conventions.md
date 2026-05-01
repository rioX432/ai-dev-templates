# Localization Conventions

## String Management
- All user-visible strings in translation files, never hardcoded
- Use `i18next` + `react-i18next` with `expo-localization` for locale detection
- Translation files: JSON format in `src/i18n/locales/{locale}.json`
- String keys: `snake_case`, namespaced by feature (`canvas.toolbar_undo`, not `btn1`)
- Parameterized strings: use interpolation (`{{name}}`) not concatenation
- Plurals: use i18next plural rules (`key_one`, `key_other`), never `if count === 1`

## Content Rules
- Default language: English (base strings in `en.json`)
- No raw text in JSX — always reference translation keys via `t()` or `<Trans>`
- Date/time: use `Intl.DateTimeFormat` or `date-fns` with locale, never manual format strings
- Numbers/currency: use `Intl.NumberFormat` with locale, never manual formatting
- Do not assume text direction — support RTL via `I18nManager` where applicable

## Quality Checks
- Missing translations: all keys must exist in every supported locale
- String length: allow 40% expansion for translated text (German/French expand significantly)
- Truncation: all text must handle overflow with `numberOfLines` + `ellipsizeMode`
- Screenshots: verify UI doesn't break with longest translation

## React Native-Specific
- Detect device locale with `expo-localization` (`getLocales()`)
- Set i18next language on app start and respond to locale changes
- Platform-specific strings (e.g., iOS permission dialogs) in `Info.plist` / `infoPlist` via app.config
- Use `expo-localization` `getCalendars()` for calendar/timezone-aware formatting
