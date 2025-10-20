import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../design_system/colors.dart';

/// Service for handling audio playback functionality
class AudioPlaybackService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentAudioPath;
  static bool _initialized = false;
  static final StreamController<Map<String, dynamic>> _audioStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream to listen for audio state changes
  static Stream<Map<String, dynamic>> get audioStateStream =>
      _audioStateController.stream;

  /// Notify listeners of audio state changes
  static void _notifyStateChange() {
    _audioStateController.add({
      'isPlaying': _isPlaying,
      'currentAudioPath': _currentAudioPath,
    });
  }

  /// Initialize audio player with completion listener
  static void _initializeAudioPlayer() {
    if (!_initialized) {
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
        _currentAudioPath = null;
        _notifyStateChange();
      });
      _initialized = true;
    }
  }

  /// Play audio file from filename
  static Future<void> playAudio(String audioPath, BuildContext context) async {
    try {
      // Initialize audio player if not already done
      _initializeAudioPlayer();

      // If already playing the same audio, pause it
      if (_isPlaying && _currentAudioPath == audioPath) {
        await pauseAudio(context);
        return;
      }

      // Convert filename to full path
      final fullPath = await _getFullAudioPath(audioPath);

      // Check if file exists first
      final file = File(fullPath);
      if (!await file.exists()) {
        if (context.mounted) {
          _showSnackBar(context, 'Audio file not found', isError: true);
        }
        return;
      }

      // Show loading snackbar
      if (context.mounted) {
        _showSnackBar(context, 'Playing audio...');
      }

      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(fullPath));
      _isPlaying = true;
      _currentAudioPath = audioPath;
      _notifyStateChange(); // Notify listeners of state change

      // Show success message
      if (context.mounted) {
        _showSnackBar(context, 'Audio playback started - Tap again to pause');
      }
    } on Exception catch (e, stackTrace) {
      // Log to Sentry at UI level
      Sentry.captureException(e, stackTrace: stackTrace);

      // Show user feedback
      if (context.mounted) {
        _showSnackBar(context,
            'Error playing audio: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}',
            isError: true);
      }
    }
  }

  /// Get full audio path from filename
  static Future<String> _getFullAudioPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio/$fileName';
  }

  /// Show snackbar message
  static void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    // Clear any existing snackbars before showing new one
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        duration: Duration(seconds: isError ? 2 : 1),
      ),
    );
  }

  /// Pause current audio playback
  static Future<void> pauseAudio(BuildContext context) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _isPlaying = false;
        _notifyStateChange(); // Notify listeners of state change
        if (context.mounted) {
          _showSnackBar(context, 'Audio paused - Tap to resume');
        }
      }
    } on Exception catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      if (context.mounted) {
        _showSnackBar(context,
            'Error pausing audio: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}',
            isError: true);
      }
    }
  }

  /// Stop current audio playback
  static Future<void> stopAudio(BuildContext context) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
        _currentAudioPath = null;
        _notifyStateChange(); // Notify listeners of state change
        if (context.mounted) {
          _showSnackBar(context, 'Audio stopped');
        }
      }
    } on Exception catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      if (context.mounted) {
        _showSnackBar(context,
            'Error stopping audio: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}',
            isError: true);
      }
    }
  }

  /// Resume paused audio playback
  static Future<void> resumeAudio(BuildContext context) async {
    try {
      if (!_isPlaying && _currentAudioPath != null) {
        await _audioPlayer.resume();
        _isPlaying = true;
        _notifyStateChange(); // Notify listeners of state change
        if (context.mounted) {
          _showSnackBar(context, 'Audio resumed');
        }
      }
    } on Exception catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      if (context.mounted) {
        _showSnackBar(context,
            'Error resuming audio: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}',
            isError: true);
      }
    }
  }

  /// Check if audio is currently playing
  static bool get isPlaying => _isPlaying;

  /// Get current audio path
  static String? get currentAudioPath => _currentAudioPath;

  /// Dispose the audio player
  static void dispose() {
    _audioPlayer.dispose();
    _isPlaying = false;
    _currentAudioPath = null;
    _audioStateController.close();
  }
}
