import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'haptic_service.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static bool _initialized = false;

  /// Initialize audio service with proper session configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configure audio session to respect silent switch
      await _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowBluetoothA2DP,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));

      _initialized = true;
    } catch (e) {
      // Silent error handling
    }
  }

  /// Play a custom audio file
  static Future<void> playAudioFile(String assetPath) async {
    // Ensure audio service is initialized
    await initialize();

    final bool soundEnabled = await HapticService.isSoundEnabled;

    if (!soundEnabled) {
      return;
    }

    try {
      // Cancel any ongoing sound
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      _isPlaying = true;
      await _audioPlayer.play(AssetSource(assetPath));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
    }
  }

  /// Play TickTick-style ding sound using pattern
  static Future<void> playTickTickDing() async {
    if (!(await HapticService.isSoundEnabled)) return;

    // Cancel any ongoing sound
    _isPlaying = false;

    _isPlaying = true;

    // TickTick-style pattern: quick double ding
    await _playSoundPattern([80, 40, 120, 60, 100]);

    _isPlaying = false;
  }

  /// Play completion sound (shorter, more subtle)
  static Future<void> playCompletionSound() async {
    if (!(await HapticService.isSoundEnabled)) return;

    _isPlaying = false;
    _isPlaying = true;

    // Quick completion pattern
    await _playSoundPattern([60, 30, 80]);

    _isPlaying = false;
  }

  /// Play delete/trash sound
  static Future<void> playDeleteSound() async {
    if (!(await HapticService.isSoundEnabled)) return;

    _isPlaying = false;
    _isPlaying = true;

    // Delete pattern: shush-like
    await _playSoundPattern([100, 50, 150, 80, 120]);

    _isPlaying = false;
  }

  /// Play Air Hit pattern (mimicking sound1.aac)
  static Future<void> playAirHitPattern() async {
    if (!(await HapticService.isSoundEnabled)) return;

    _isPlaying = false;
    _isPlaying = true;

    // Air Hit pattern: mimicking the converted sound
    await _playSoundPattern([60, 30, 80, 40, 120]);

    _isPlaying = false;
  }

  /// Play Swish pattern
  static Future<void> playSwishPattern() async {
    if (!(await HapticService.isSoundEnabled)) return;

    _isPlaying = false;
    _isPlaying = true;

    // Swish pattern: smooth whoosh effect
    await _playSoundPattern([100, 50, 80, 60, 90, 40]);

    _isPlaying = false;
  }

  /// Play sound pattern with SystemSound
  static Future<void> _playSoundPattern(List<int> delays) async {
    if (!(await HapticService.isSoundEnabled)) return;

    for (int i = 0; i < delays.length; i++) {
      if (!_isPlaying) {
        break; // Check if cancelled
      }
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(Duration(milliseconds: delays[i]));
    }
  }

  /// Cancel any currently playing sound
  static Future<void> cancelSound() async {
    _isPlaying = false;
    await _audioPlayer.stop();
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
