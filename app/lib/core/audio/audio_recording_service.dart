import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service responsible for audio recording functionality
class AudioRecordingService {
  final Record _audioRecorder = Record();
  
  bool _isRecording = false;
  String? _currentAudioPath;
  
  /// Check if currently recording
  bool get isRecording => _isRecording;
  
  /// Get current audio path
  String? get currentAudioPath => _currentAudioPath;
  
  /// Set current audio path
  void setCurrentAudioPath(String audioPath) {
    _currentAudioPath = audioPath;
  }
  
  /// Start recording audio
  Future<String?> startRecording() async {
    if (_isRecording) {
      return null;
    }
    
    try {
      // Check permissions
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw const AudioRecordingException('Microphone permission required');
      }
      
      // Create audio file path in documents directory (permanent)
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentAudioPath = '${audioDir.path}/$fileName';
      
      // Start recording with AAC encoder (more reliable than WAV)
      await _audioRecorder.start(
        path: _currentAudioPath,
        encoder: AudioEncoder.aacLc,
      );
      
      _isRecording = true;
      return _currentAudioPath;
      
    } catch (e) {
      _isRecording = false;
      _currentAudioPath = null;
      if (e is AudioRecordingException) {
        rethrow;
      }
      throw AudioRecordingException('Failed to start recording: $e');
    }
  }
  
  /// Stop recording and return audio path
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }
    
    try {
      // Stop recording
      final path = await _audioRecorder.stop();
      _isRecording = false;
      
      final result = path;
      _currentAudioPath = null;
      return result;
      
    } catch (e) {
      _isRecording = false;
      _currentAudioPath = null;
      throw AudioRecordingException('Failed to stop recording: $e');
    }
  }
  
  /// Check if microphone permission is available
  Future<bool> hasPermission() async {
    return _audioRecorder.hasPermission();
  }
  
  /// Request microphone permission
  Future<bool> requestPermission() async {
    return _audioRecorder.hasPermission();
  }
}

/// Audio Recording Exception
class AudioRecordingException implements Exception {
  const AudioRecordingException(this.message);
  final String message;
  
  @override
  String toString() => 'AudioRecordingException: $message';
}

/// Provider for AudioRecordingService
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  return AudioRecordingService();
});
