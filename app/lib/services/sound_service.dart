import 'package:flutter/services.dart';
import 'haptic_service.dart';

class SoundService {
  static bool _isPlaying = false;

  /// Play a simple click sound (respects user settings)
  static void playClick() {
    if (HapticService.isSoundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play a delete/trash sound pattern (shush-like)
  static void playDeleteSound() {
    if (!HapticService.isSoundEnabled) return;

    _playSoundPattern([150, 100, 200]); // Short-short-long pattern
  }

  /// Play a completion sound pattern
  static void playCompletionSound() {
    if (!HapticService.isSoundEnabled) return;

    _playSoundPattern([100, 50, 100]); // Quick completion pattern
  }

  /// Play sound pattern with cancellation support
  static void _playSoundPattern(List<int> delays) async {
    // Cancel any ongoing sound
    _isPlaying = false;

    _isPlaying = true;
    for (int delay in delays) {
      if (!_isPlaying) break; // Check if cancelled
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(Duration(milliseconds: delay));
    }
    _isPlaying = false;
  }

  /// Cancel any currently playing sound
  static void cancelSound() {
    _isPlaying = false;
  }
}
