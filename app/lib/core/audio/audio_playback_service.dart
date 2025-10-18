import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

/// Service for handling audio playback functionality
class AudioPlaybackService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play audio file from filename
  static Future<void> playAudio(String audioPath, BuildContext context) async {
    try {
      // Convert filename to full path
      final fullPath = await _getFullAudioPath(audioPath);
      
      // Check if file exists first
      final file = File(fullPath);
      if (!await file.exists()) {
        _showSnackBar(context, 'Audio file not found', isError: true);
        return;
      }
      
      // Show loading snackbar
      _showSnackBar(context, 'Playing audio...');
      
      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(fullPath));
      
      // Show success message
      _showSnackBar(context, 'Audio playback started');
      
    } catch (e) {
      _showSnackBar(context, 'Error playing audio: $e', isError: true);
    }
  }

  /// Get full audio path from filename
  static Future<String> _getFullAudioPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio/$fileName';
  }

  /// Show snackbar message
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: Duration(seconds: isError ? 2 : 1),
      ),
    );
  }

  /// Dispose the audio player
  static void dispose() {
    _audioPlayer.dispose();
  }
}
