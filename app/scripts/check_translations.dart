#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Script to check for untranslated messages and fail build if any are found
/// This ensures all localization keys have translations in all supported languages

void main(List<String> args) {
  print('🔍 Checking for untranslated messages...');

  final untranslatedFile = File('untranslated_messages.json');

  if (!untranslatedFile.existsSync()) {
    print(
        '✅ No untranslated messages file found - all translations are complete!');
    exit(0);
  }

  try {
    final content = untranslatedFile.readAsStringSync();
    final Map<String, dynamic> untranslated = json.decode(content);

    if (untranslated.isEmpty) {
      print(
          '✅ No untranslated messages found - all translations are complete!');
      exit(0);
    }

    print('❌ Found untranslated messages:');
    untranslated.forEach((locale, messages) {
      if (messages is List && messages.isNotEmpty) {
        print('  📍 $locale: ${messages.join(', ')}');
      }
    });

    print('\n🚨 Build failed: Missing translations detected!');
    print(
        '💡 Add the missing translations to lib/l10n/app_${untranslated.keys.first}.arb');
    print('💡 Then run: flutter gen-l10n');

    exit(1);
  } on Exception catch (e) {
    print('❌ Error reading untranslated messages file: $e');
    exit(1);
  }
}
