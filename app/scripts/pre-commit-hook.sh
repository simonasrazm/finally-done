#!/bin/bash

# Pre-commit hook to check translations
# This script can be used as a Git pre-commit hook

echo "🔍 Pre-commit: Checking translations..."

# Generate localization files
flutter gen-l10n

# Check for untranslated messages
dart scripts/check_translations.dart

if [ $? -eq 0 ]; then
    echo "✅ Pre-commit: All translations are complete!"
    exit 0
else
    echo "❌ Pre-commit: Missing translations detected!"
    echo "💡 Please add missing translations and try again."
    exit 1
fi
