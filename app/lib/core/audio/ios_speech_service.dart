import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service responsible for iOS native speech recognition
class IosSpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize();
    } catch (e) {
      return false;
    }
  }
  
  /// Check if we have microphone permission
  Future<bool> hasPermission() async {
    try {
      bool available = await _speech.initialize();
      if (!available) return false;
      return await _speech.hasPermission;
    } catch (e) {
      return false;
    }
  }
  
  /// Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    try {
      bool available = await _speech.initialize();
      if (!available) return ['en-US'];
      
      List<stt.LocaleName> locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      return ['en-US']; // Fallback to English
    }
  }
  
  /// Recognize speech using iOS native
  Future<String> recognizeSpeech({
    String? language,
    Duration? timeout,
  }) async {
    try {
      // Initialize speech recognition
      bool available = await _speech.initialize();
      if (!available) {
        throw SpeechException(
          code: 'INIT_FAILED',
          message: 'Speech recognition not available',
        );
      }

      // Check permissions
      bool hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        throw SpeechException(
          code: 'PERMISSION_DENIED',
          message: 'Microphone permission required',
        );
      }

      // Stop any existing listening
      if (_speech.isListening) {
        await _speech.stop();
      }

      String transcription = '';
      
      // Use auto-detect by not specifying localeId if no language provided
      await _speech.listen(
        onResult: (result) {
          transcription = result.recognizedWords;
        },
        localeId: language,
        listenFor: timeout ?? const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 1),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // Wait for results
      await Future.delayed(timeout ?? const Duration(seconds: 6));
      
      // Stop listening
      if (_speech.isListening) {
        await _speech.stop();
      }
      
      return transcription.isNotEmpty ? transcription : 'No speech detected';
      
    } on PlatformException catch (e) {
      throw SpeechException(
        code: e.code,
        message: e.message ?? 'Unknown speech recognition error',
        details: e.details,
      );
    } catch (e) {
      throw SpeechException(
        code: 'RECOGNITION_FAILED',
        message: 'iOS speech recognition failed: $e',
      );
    }
  }
  
  /// Simple recording method with basic error handling
  Future<String> recordSimple({
    String? language,
    Duration? timeout,
  }) async {
    try {
      // Initialize speech recognition with permission check
      bool available = await _speech.initialize();
      
      if (!available) {
        return 'Speech recognition not available. Please check permissions.';
      }

      // Check if we have permission
      bool hasPermission = await _speech.hasPermission;
      
      if (!hasPermission) {
        return 'Microphone permission required. Please enable in Settings.';
      }

      // Stop any existing listening
      if (_speech.isListening) {
        await _speech.stop();
      }

      String transcription = '';
      
      // Check if language is supported
      List<stt.LocaleName> locales = await _speech.locales();
      
      // Try to find a supported locale
      String? supportedLocale;
      if (language != null && locales.any((l) => l.localeId == language)) {
        supportedLocale = language;
      } else if (locales.any((l) => l.localeId == 'en-US')) {
        supportedLocale = 'en-US';
      } else if (locales.isNotEmpty) {
        supportedLocale = locales.first.localeId;
      }
      
      if (supportedLocale == null) {
        return 'No supported languages found';
      }
      
      // Simple listen with minimal configuration
      await _speech.listen(
        onResult: (result) {
          transcription = result.recognizedWords;
        },
        localeId: supportedLocale,
        listenFor: timeout ?? const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 1),
        partialResults: false,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // Wait briefly for results
      await Future.delayed(const Duration(seconds: 1));
      
      // Stop listening
      if (_speech.isListening) {
        await _speech.stop();
      }
      
      return transcription.isNotEmpty ? transcription : 'No speech detected';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}

/// Speech Recognition Exception
class SpeechException implements Exception {
  final String code;
  final String message;
  final dynamic details;
  
  const SpeechException({
    required this.code,
    required this.message,
    this.details,
  });
  
  @override
  String toString() => 'SpeechException($code): $message';
}

/// Provider for IosSpeechService
final iosSpeechServiceProvider = Provider<IosSpeechService>((ref) {
  return IosSpeechService();
});
