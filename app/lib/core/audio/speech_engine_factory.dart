import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speech_engine_strategy.dart';
import 'ios_speech_service.dart';
import '../../infrastructure/external_apis/gemini_api_service.dart';
import 'audio_recording_service.dart';

/// Factory for creating speech engine strategies
class SpeechEngineFactory {
  
  SpeechEngineFactory(
    this._iosService,
    this._geminiService,
    this._audioService,
  );
  final IosSpeechService _iosService;
  final GeminiApiService _geminiService;
  final AudioRecordingService _audioService;
  
  /// Create a speech engine strategy based on preference
  SpeechEngineStrategy createStrategy(String enginePreference) {
    switch (enginePreference.toLowerCase()) {
      case 'ios':
        return IosSpeechStrategy(_iosService);
      
      case 'gemini':
        return GeminiSpeechStrategy(_geminiService, _audioService);
      
      case 'auto':
      default:
        return AutoDetectSpeechStrategy(_iosService, _geminiService, _audioService);
    }
  }
  
  /// Get all available engine names
  List<String> getAvailableEngines() {
    return ['ios', 'gemini', 'auto'];
  }
  
  /// Check if an engine is available
  Future<bool> isEngineAvailable(String enginePreference) async {
    final strategy = createStrategy(enginePreference);
    return strategy.isAvailable();
  }
}

/// Provider for SpeechEngineFactory
final speechEngineFactoryProvider = Provider<SpeechEngineFactory>((ref) {
  final iosService = ref.read(iosSpeechServiceProvider);
  final geminiService = ref.read(geminiApiServiceProvider);
  final audioService = ref.read(audioRecordingServiceProvider);
  
  return SpeechEngineFactory(iosService, geminiService, audioService);
});
