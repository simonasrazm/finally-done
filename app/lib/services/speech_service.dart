import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speech_engine_strategy.dart';
import 'speech_engine_factory.dart';
import 'ios_speech_service.dart';
import 'gemini_api_service.dart';
import 'audio_recording_service.dart';

/// Main Speech Recognition Service
/// Uses strategy pattern to support different speech engines
class SpeechService {
  final SpeechEngineFactory _engineFactory;
  final IosSpeechService _iosService;
  final GeminiApiService _geminiService;
  final AudioRecordingService _audioService;
  
  SpeechService(
    this._engineFactory,
    this._iosService,
    this._geminiService,
    this._audioService,
  );
  
  /// Get current audio path from recording service
  String? get currentAudioPath => _audioService.currentAudioPath;
  
  /// Set current audio path
  void setCurrentAudioPath(String audioPath) {
    _audioService.setCurrentAudioPath(audioPath);
  }
  
  /// Check if currently recording
  bool get isRecording => _audioService.isRecording;
  
  /// Start recording audio
  Future<String?> startRecording() async {
    return await _audioService.startRecording();
  }
  
  /// Stop recording audio
  Future<String?> stopRecording() async {
    return await _audioService.stopRecording();
  }
  
  /// Main speech recognition method that respects engine preference
  Future<String> recognizeSpeech({
    required String enginePreference,
    String? language,
    Duration? timeout,
  }) async {
    try {
      final strategy = _engineFactory.createStrategy(enginePreference);
      
      return await strategy.recognizeSpeech(
        language: language,
        timeout: timeout,
      );
    } catch (e) {
      throw SpeechServiceException('Speech recognition failed: $e');
    }
  }
  
  /// Process recorded audio with Gemini (for Gemini engine)
  Future<String> processRecordedAudio() async {
    try {
      return await _geminiService.processAudioFile(_audioService.currentAudioPath!);
    } catch (e) {
      throw SpeechServiceException('Audio processing failed: $e');
    }
  }
  
  /// Process a specific audio file with Gemini
  Future<String> processAudioFile(String audioPath) async {
    try {
      return await _geminiService.processAudioFile(audioPath);
    } catch (e) {
      throw SpeechServiceException('Audio processing failed: $e');
    }
  }
  
  /// Check if speech recognition is available for language
  Future<bool> isAvailable(String language) async {
    try {
      return await _iosService.isAvailable();
    } catch (e) {
      return false;
    }
  }
  
  /// Request speech recognition permissions
  Future<SpeechPermissionStatus> requestPermission() async {
    try {
      bool available = await _iosService.isAvailable();
      if (available) {
        return SpeechPermissionStatus.authorized;
      } else {
        return SpeechPermissionStatus.denied;
      }
    } catch (e) {
      return SpeechPermissionStatus.denied;
    }
  }
  
  /// Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    try {
      return await _iosService.getSupportedLanguages();
    } catch (e) {
      return ['en-US']; // Fallback to English
    }
  }
  
  /// Check if microphone permission is available
  Future<bool> hasMicrophonePermission() async {
    return await _audioService.hasPermission();
  }
  
  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    return await _audioService.requestPermission();
  }
  
  /// Get available speech engines
  List<String> getAvailableEngines() {
    return _engineFactory.getAvailableEngines();
  }
  
  /// Check if a specific engine is available
  Future<bool> isEngineAvailable(String enginePreference) async {
    return await _engineFactory.isEngineAvailable(enginePreference);
  }
}

/// Speech Service Exception
class SpeechServiceException implements Exception {
  final String message;
  const SpeechServiceException(this.message);
  
  @override
  String toString() => 'SpeechServiceException: $message';
}

/// Speech Permission Status
enum SpeechPermissionStatus {
  notDetermined,
  denied,
  restricted,
  authorized,
}

/// Speech Service Provider
final speechServiceProvider = Provider<SpeechService>((ref) {
  final engineFactory = ref.read(speechEngineFactoryProvider);
  final iosService = ref.read(iosSpeechServiceProvider);
  final geminiService = ref.read(geminiApiServiceProvider);
  final audioService = ref.read(audioRecordingServiceProvider);
  
  return SpeechService(engineFactory, iosService, geminiService, audioService);
});

/// Speech Permission Provider
final speechPermissionProvider = StateProvider<SpeechPermissionStatus>((ref) {
  return SpeechPermissionStatus.notDetermined;
});

/// Speech Engine Preference Provider
final speechEngineProvider = StateNotifierProvider<SpeechEngineNotifier, String>((ref) {
  return SpeechEngineNotifier();
});

/// Speech Engine Notifier
class SpeechEngineNotifier extends StateNotifier<String> {
  SpeechEngineNotifier() : super('auto') {
    _loadPreference();
  }

  void _loadPreference() async {
    // TODO: Load from SharedPreferences
    // For now, default to 'gemini' since that's what you want
    state = 'gemini';
  }

  void setEngine(String engine) {
    state = engine;
    // TODO: Save to SharedPreferences
  }
}

/// Current Language Provider (for display purposes)
final speechLanguageProvider = StateProvider<String>((ref) {
  return 'lt-LT'; // Default to Lithuanian
});