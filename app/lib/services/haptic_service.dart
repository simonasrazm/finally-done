import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static const String _hapticEnabledKey = 'haptic_enabled';
  static const String _soundEnabledKey = 'sound_enabled';

  static bool _hapticEnabled = true;
  static bool _soundEnabled = true;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticEnabled = prefs.getBool(_hapticEnabledKey) ?? true;
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
  }

  static Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticEnabledKey, enabled);
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  static bool get isHapticEnabled => _hapticEnabled;

  /// Check if sound should be enabled (app setting only - audio session handles silent switch)
  static Future<bool> get isSoundEnabled async {
    return _soundEnabled;
  }

  /// Synchronous version for cases where async isn't possible
  static bool get isSoundEnabledSync => _soundEnabled;

  static void debugPrint() {
    // Debug method kept for compatibility but no longer prints
  }

  static void lightImpact() {
    if (_hapticEnabled) {
      // ignore: discarded_futures
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (_hapticEnabled) {
      // ignore: discarded_futures
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (_hapticEnabled) {
      // ignore: discarded_futures
      HapticFeedback.heavyImpact();
    }
  }

  static void selectionClick() {
    if (_hapticEnabled) {
      // ignore: discarded_futures
      HapticFeedback.selectionClick();
    }
  }
}
