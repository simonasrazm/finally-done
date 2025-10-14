# Translation System

This document describes the translation system and how to ensure all messages are properly translated.

## Overview

The app uses Flutter's built-in localization system with ARB (Application Resource Bundle) files. All user-facing strings must be translated to all supported languages.

## Supported Languages

- **English (en)** - Primary language
- **Lithuanian (lt)** - Secondary language

## File Structure

```
lib/l10n/
├── app_en.arb          # English translations (template)
├── app_lt.arb          # Lithuanian translations
└── l10n.yaml           # Localization configuration

scripts/
├── check_translations.dart  # Translation validation script
└── pre-commit-hook.sh       # Git pre-commit hook

.github/workflows/
└── check-translations.yml   # CI/CD translation check
```

## Adding New Translations

1. **Add to English template** (`lib/l10n/app_en.arb`):
   ```json
   {
     "newKey": "New message",
     "@newKey": {
       "description": "Description of the message"
     }
   }
   ```

2. **Add to Lithuanian** (`lib/l10n/app_lt.arb`):
   ```json
   {
     "newKey": "Naujas pranešimas"
   }
   ```

3. **Generate localization files**:
   ```bash
   make gen-l10n
   # or
   flutter gen-l10n
   ```

## Build-Time Translation Checks

The build will **FAIL** if any translations are missing. This is enforced at multiple levels:

### 1. Make Commands
```bash
# Check translations only
make check-translations

# Build with translation check
make build
make build-dev

# Run with translation check
make run
```

### 2. VS Code Tasks
- **Check Translations** - Validates all translations
- **Generate Localizations** - Regenerates localization files
- **Build with Translation Check** - Builds with validation

### 3. Git Pre-commit Hook
```bash
# Install the pre-commit hook
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 4. CI/CD Pipeline
GitHub Actions automatically checks translations on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

## How It Works

1. **Generation**: `flutter gen-l10n` creates `untranslated_messages.json` if any translations are missing
2. **Validation**: `scripts/check_translations.dart` reads this file and fails the build if it exists
3. **Cleanup**: The untranslated messages file is automatically cleaned up after successful builds

## Error Messages

If translations are missing, you'll see:
```
❌ Found untranslated messages:
  📍 lt: connecting, notConnected, connected

🚨 Build failed: Missing translations detected!
💡 Add the missing translations to lib/l10n/app_lt.arb
💡 Then run: flutter gen-l10n
```

## Best Practices

1. **Always add descriptions** to English keys for context
2. **Use parameterized strings** for dynamic content:
   ```json
   {
     "welcomeMessage": "Welcome, {name}!",
     "@welcomeMessage": {
       "placeholders": {
         "name": {
           "type": "String"
         }
       }
     }
   }
   ```
3. **Test both languages** before committing
4. **Use the Make commands** for consistent builds

## Troubleshooting

### Build Fails with Missing Translations
1. Check `untranslated_messages.json` for missing keys
2. Add missing translations to the appropriate ARB file
3. Run `make gen-l10n` to regenerate
4. Run `make check-translations` to verify

### Localization Files Not Updating
1. Delete `lib/generated/` folder
2. Run `flutter clean`
3. Run `make gen-l10n`
4. Rebuild the app

## Adding New Languages

1. Add the language code to `l10n.yaml`:
   ```yaml
   preferred-supported-locales: [en, lt, de]  # Add 'de' for German
   ```

2. Create `lib/l10n/app_de.arb` with German translations

3. Update the translation check script if needed

4. Test with `make check-translations`
