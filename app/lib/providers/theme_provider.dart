import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Theme state
class ThemeState {

  ThemeState({
    required this.mode,
    required this.flutterThemeMode,
  });
  final AppThemeMode mode;
  final ThemeMode flutterThemeMode;

  ThemeState copyWith({
    AppThemeMode? mode,
    ThemeMode? flutterThemeMode,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      flutterThemeMode: flutterThemeMode ?? this.flutterThemeMode,
    );
  }
}

/// Theme notifier for managing theme state
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(
    mode: AppThemeMode.system,
    flutterThemeMode: ThemeMode.system,
  )) {
    _loadThemeMode();
  }

  /// Available theme modes
  final List<Map<String, dynamic>> availableModes = [
    {
      'mode': AppThemeMode.system,
      'name': 'System Default',
      'icon': Icons.brightness_auto,
    },
    {
      'mode': AppThemeMode.light,
      'name': 'Light',
      'icon': Icons.light_mode,
    },
    {
      'mode': AppThemeMode.dark,
      'name': 'Dark',
      'icon': Icons.dark_mode,
    },
  ];

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      final mode = AppThemeMode.values[modeIndex];
      _updateThemeMode(mode);
    } catch (e) {
      // If loading fails, use system default
      _updateThemeMode(AppThemeMode.system);
    }
  }

  /// Change theme mode
  Future<void> changeThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
      _updateThemeMode(mode);
    } catch (e) {
      // If saving fails, still update the state
      _updateThemeMode(mode);
    }
  }

  /// Update theme mode and convert to Flutter ThemeMode
  void _updateThemeMode(AppThemeMode mode) {
    ThemeMode flutterMode;
    switch (mode) {
      case AppThemeMode.system:
        flutterMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        flutterMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        flutterMode = ThemeMode.dark;
        break;
    }

    state = state.copyWith(
      mode: mode,
      flutterThemeMode: flutterMode,
    );
  }

  /// Get display name for theme mode
  String getThemeModeName(AppThemeMode mode) {
    final modeData = availableModes.firstWhere(
      (m) => m['mode'] == mode,
      orElse: () => availableModes.first,
    );
    return modeData['name'] as String;
  }

  /// Get icon for theme mode
  IconData getThemeModeIcon(AppThemeMode mode) {
    final modeData = availableModes.firstWhere(
      (m) => m['mode'] == mode,
      orElse: () => availableModes.first,
    );
    return modeData['icon'] as IconData;
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Current theme mode provider
final currentThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).mode;
});

/// Current Flutter theme mode provider
final currentFlutterThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).flutterThemeMode;
});
