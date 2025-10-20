import 'ios_speech_service.dart';
import '../../infrastructure/external_apis/gemini_api_service.dart';
import 'audio_recording_service.dart';

/// Abstract strategy for speech recognition engines
abstract class SpeechEngineStrategy {
  Future<String> recognizeSpeech({
    String? language,
    Duration? timeout,
  });
  
  Future<bool> isAvailable();
  String get engineName;
}

/// iOS Native Speech Recognition Strategy
class IosSpeechStrategy implements SpeechEngineStrategy {
  
  IosSpeechStrategy(this._iosService);
  final IosSpeechService _iosService;
  
  @override
  String get engineName => 'iOS Native';
  
  @override
  Future<String> recognizeSpeech({
    String? language,
    Duration? timeout,
  }) async {
    return _iosService.recognizeSpeech(
      language: language,
      timeout: timeout,
    );
  }
  
  @override
  Future<bool> isAvailable() async {
    return _iosService.isAvailable();
  }
}

/// Gemini API Speech Recognition Strategy
class GeminiSpeechStrategy implements SpeechEngineStrategy {
  
  GeminiSpeechStrategy(this._geminiService, this._audioService);
  final GeminiApiService _geminiService;
  final AudioRecordingService _audioService;
  
  @override
  String get engineName => 'Gemini API';
  
  @override
  Future<String> recognizeSpeech({
    String? language,
    Duration? timeout,
  }) async {
    try {
      // Start recording
      final String? audioPath = await _audioService.startRecording();
      
      if (audioPath != null) {
        // Return a special message indicating recording is in progress
        return 'RECORDING_IN_PROGRESS';
      } else {
        throw const SpeechEngineException('Failed to start recording. Please try again.');
      }
      
    } on Exception catch (e) {
      throw SpeechEngineException('Gemini speech recognition failed: $e');
    }
  }
  
  @override
  Future<bool> isAvailable() async {
    return _geminiService.isApiKeyAvailable;
  }
  
  /// Process the recorded audio with Gemini
  Future<String> processRecordedAudio() async {
    try {
      final audioPath = _audioService.currentAudioPath;
      if (audioPath == null || audioPath.isEmpty) {
        throw const SpeechEngineException('No audio path available. Please try again.');
      }
      
      return _geminiService.processAudioFile(audioPath);
      
    } on Exception {
      throw const SpeechEngineException('Audio processing failed. Please try again.');
    }
  }
  
  /// Process a specific audio file with Gemini (for retry functionality)
  Future<String> processAudioFile(String audioPath) async {
    try {
      return _geminiService.processAudioFile(audioPath);
      
    } on Exception {
      throw const SpeechEngineException('Audio processing failed. Please try again.');
    }
  }
}

/// Auto-detect Speech Recognition Strategy
class AutoDetectSpeechStrategy implements SpeechEngineStrategy {
  
  AutoDetectSpeechStrategy(this._iosService, this._geminiService, this._audioService);
  final IosSpeechService _iosService;
  final GeminiApiService _geminiService;
  final AudioRecordingService _audioService;
  
  @override
  String get engineName => 'Auto-detect';
  
  @override
  Future<String> recognizeSpeech({
    String? language,
    Duration? timeout,
  }) async {
    try {
      // Try iOS first
      final String result = await _iosService.recognizeSpeech(
        language: language,
        timeout: timeout,
      );
      
      // Check if result is gibberish or empty
      if (_isGibberish(result)) {
        return await GeminiSpeechStrategy(_geminiService, _audioService).recognizeSpeech(
          language: language,
          timeout: timeout,
        );
      }
      
      return result;
    } on Exception {
      return GeminiSpeechStrategy(_geminiService, _audioService).recognizeSpeech(
        language: language,
        timeout: timeout,
      );
    }
  }
  
  @override
  Future<bool> isAvailable() async {
    return await _iosService.isAvailable() || _geminiService.isApiKeyAvailable;
  }
  
  /// Check if text appears to be gibberish
  bool _isGibberish(String text) {
    if (text.isEmpty || text == 'No speech detected') return true;
    
    // Simple gibberish detection - check for common patterns
    final String lowerText = text.toLowerCase();
    
    // Check for very short results (likely incomplete)
    if (text.length < 3) return true;
    
    // Check for common gibberish patterns
    final List<String> gibberishPatterns = [
      'mhm', 'uh', 'um', 'ah', 'eh', 'oh',
      'hmm', 'mmm', 'err', 'umm'
    ];
    
    for (String pattern in gibberishPatterns) {
      if (lowerText.contains(pattern)) return true;
    }
    
    // Check for repeated characters (like "aaaa" or "mmmm")
    final RegExp repeatedChars = RegExp(r'(.)\1{3,}');
    if (repeatedChars.hasMatch(text)) return true;
    
    return false;
  }
}

/// Speech Engine Exception
class SpeechEngineException implements Exception {
  const SpeechEngineException(this.message);
  final String message;
  
  @override
  String toString() => 'SpeechEngineException: $message';
}
