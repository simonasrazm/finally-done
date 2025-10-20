import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language state management
class LanguageState {

  const LanguageState({
    required this.locale,
    this.isLoading = false,
  });
  final Locale locale;
  final bool isLoading;

  LanguageState copyWith({
    Locale? locale,
    bool? isLoading,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Language notifier for managing language state
class LanguageNotifier extends StateNotifier<LanguageState> {
  
  LanguageNotifier() : super(LanguageState(locale: const Locale('en'))) {
    _loadSavedLanguage();
  }
  static const String _languageKey = 'selected_language';

  /// Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      final locale = Locale(languageCode);
      
      state = state.copyWith(
        locale: locale,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to English if loading fails
      state = state.copyWith(
        locale: const Locale('en'),
        isLoading: false,
      );
    }
  }

  /// Change language and save to SharedPreferences
  Future<void> changeLanguage(Locale locale) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      
      state = state.copyWith(
        locale: locale,
        isLoading: false,
      );
    } catch (e) {
      // Still update the state even if saving fails
      state = state.copyWith(
        locale: locale,
        isLoading: false,
      );
    }
  }

  /// Get available languages
  List<Map<String, dynamic>> get availableLanguages => [
    {
      'code': 'en',
      'name': 'English',
      'flag': '🇺🇸',
    },
    {
      'code': 'lt',
      'name': 'Lietuvių',
      'flag': '🇱🇹',
    },
  ];

  /// Get current language display name
  String get currentLanguageName {
    final current = availableLanguages.firstWhere(
      (lang) => lang['code'] == state.locale.languageCode,
      orElse: () => availableLanguages.first,
    );
    return '${current['flag']} ${current['name']}';
  }
}

/// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

/// Current locale provider for easy access
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).locale;
});
