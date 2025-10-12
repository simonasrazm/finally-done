import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

/// Speech Recognition Service
/// Uses speech_to_text plugin for cross-platform transcription
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Record _audioRecorder = Record();
  
  // Toggle recording state
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
  
  /// Start recording (toggle on)
  Future<String?> startRecording() async {
    if (_isRecording) {
      print('🎤 RECORD: Already recording, ignoring start request');
      return null;
    }
    
    try {
      print('🎤 RECORD: Starting recording...');
      
      // Check permissions
      bool hasPermission = await _audioRecorder.hasPermission();
      print('🎤 RECORD: Has permission: $hasPermission');
      if (!hasPermission) {
        throw Exception('Microphone permission required');
      }
      
      // Create audio file path in documents directory (permanent)
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      final fileName = 'gemini_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentAudioPath = '${audioDir.path}/$fileName';
      print('🎤 RECORD: Audio path: $_currentAudioPath');
      
      // Check if directory exists
      bool dirExists = await directory.exists();
      print('🎤 RECORD: Directory exists: $dirExists');
      
      // Try with AAC encoder (more reliable than WAV)
      await _audioRecorder.start(
        path: _currentAudioPath!,
        encoder: AudioEncoder.aacLc,
      );
      
      _isRecording = true;
      print('🎤 RECORD: Recording started successfully');
      return _currentAudioPath;
      
    } catch (e) {
      print('🎤 RECORD: Error starting recording: $e');
      print('🎤 RECORD: Error type: ${e.runtimeType}');
      _isRecording = false;
      _currentAudioPath = null;
      return null;
    }
  }
  
  /// Stop recording (toggle off) and return audio path
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      print('🎤 RECORD: Not recording, ignoring stop request');
      return null;
    }
    
    try {
      print('🎤 RECORD: Stopping recording...');
      
      // Stop recording
      final path = await _audioRecorder.stop();
      _isRecording = false;
      
      print('🎤 RECORD: Recording stopped: $path');
      
      // Verify file was created
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        print('🎤 RECORD: File exists: $exists, Size: $size bytes');
      }
      
      final result = path;
      _currentAudioPath = null;
      return result;
      
    } catch (e) {
      print('🎤 RECORD: Error stopping recording: $e');
      _isRecording = false;
      _currentAudioPath = null;
      return null;
    }
  }
  
  /// Start recording and transcribing speech
  /// Returns transcription text when complete
  Future<String> transcribe({
    required String language,
    Duration? timeout,
  }) async {
    try {
      // Initialize speech recognition if not already done
      bool available = await _speech.initialize();
      if (!available) {
        throw SpeechException(
          code: 'INIT_FAILED',
          message: 'Speech recognition not available',
        );
      }

      // Check if already listening and stop if so
      if (_speech.isListening) {
        await _speech.stop();
      }

      // Start listening with proper error handling
      String transcription = '';
      bool hasError = false;
      String? errorMessage;
      
      await _speech.listen(
        onResult: (result) {
          transcription = result.recognizedWords;
        },
        onSoundLevelChange: (level) {
          // Optional: handle sound level changes
        },
        localeId: language,
        listenFor: timeout ?? const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );

      // Wait for completion with proper timeout
      int waitTime = 0;
      const maxWaitTime = 10000; // 10 seconds
      const checkInterval = 100; // 100ms
      
      while (waitTime < maxWaitTime && _speech.isListening && !hasError) {
        await Future.delayed(const Duration(milliseconds: checkInterval));
        waitTime += checkInterval;
      }
      
      // Stop listening if still active
      if (_speech.isListening) {
        await _speech.stop();
      }
      
      if (hasError) {
        throw SpeechException(
          code: 'LISTEN_ERROR',
          message: errorMessage ?? 'Speech recognition failed',
        );
      }
      
      return transcription.isNotEmpty ? transcription : 'No speech detected';
    } on PlatformException catch (e) {
      throw SpeechException(
        code: e.code,
        message: e.message ?? 'Unknown speech recognition error',
        details: e.details,
      );
    } catch (e) {
      // Handle ListenFailedException specifically
      if (e.toString().contains('ListenFailedException')) {
        throw SpeechException(
          code: 'LISTEN_FAILED',
          message: 'Failed to start listening. Please check microphone permissions.',
        );
      }
      throw SpeechException(
        code: 'UNKNOWN_ERROR',
        message: e.toString(),
      );
    }
  }

  /// Simple recording method with basic error handling
  Future<String> recordSimple({
    required String language,
    Duration? timeout,
  }) async {
    try {
      // Initialize speech recognition with permission check
      bool available = await _speech.initialize(
        onError: (error) {
          print('🎤 iOS: Error - $error');
        },
        onStatus: (status) {
          print('🎤 iOS: Status - $status');
        },
      );
      
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
      if (locales.any((l) => l.localeId == language)) {
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

  /// Main speech recognition method that respects engine preference
  Future<String> recognizeSpeech({
    required String enginePreference,
    Duration? timeout,
  }) async {
    switch (enginePreference) {
      case 'gemini':
        // Skip iOS native, go directly to Gemini
        return await _recognizeWithGemini();
      
      case 'ios':
        // Use iOS native with auto-detect
        return await _recognizeWithIos();
      
      case 'auto':
      default:
        // Try iOS first, fallback to Gemini on error or gibberish
        try {
          String result = await _recognizeWithIos();
          
          // Check if result is gibberish or empty
          if (_isGibberish(result)) {
            print('iOS result appears to be gibberish, falling back to Gemini');
            return await _recognizeWithGemini();
          }
          
          return result;
        } catch (e) {
          print('iOS recognition failed, falling back to Gemini: $e');
          return await _recognizeWithGemini();
        }
    }
  }

  /// Recognize speech using iOS native with auto-detect
  Future<String> _recognizeWithIos() async {
    try {
      // Initialize speech recognition
      bool available = await _speech.initialize();
      if (!available) {
        throw Exception('Speech recognition not available');
      }

      // Check permissions
      bool hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        throw Exception('Microphone permission required');
      }

      // Stop any existing listening
      if (_speech.isListening) {
        await _speech.stop();
      }

      String transcription = '';
      
      // Use auto-detect by not specifying localeId
      print('🎤 iOS: Starting to listen...');
      await _speech.listen(
        onResult: (result) {
          print('🎤 iOS: Raw result: "${result.recognizedWords}"');
          print('🎤 iOS: Confidence: ${result.confidence}');
          print('🎤 iOS: Final: ${result.finalResult}');
          transcription = result.recognizedWords;
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 1),
        partialResults: true, // Enable partial results for debugging
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // Wait for results
      print('🎤 iOS: Waiting for results...');
      await Future.delayed(const Duration(seconds: 6)); // Wait longer
      
      // Stop listening
      if (_speech.isListening) {
        print('🎤 iOS: Stopping listening...');
        await _speech.stop();
      }
      
      print('🎤 iOS: Final transcription: "$transcription"');
      return transcription.isNotEmpty ? transcription : 'No speech detected';
    } catch (e) {
      throw Exception('iOS recognition failed: $e');
    }
  }

  /// Recognize speech using Gemini Pro with raw audio
  Future<String> _recognizeWithGemini() async {
    try {
      // Get API key from environment
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found. Please add GEMINI_API_KEY to .env file');
      }

      print('🎤 GEMINI PRO: Starting raw audio recording...');

      // Start recording
      String? audioPath = await startRecording();
      
      if (audioPath != null) {
        print('🎤 GEMINI PRO: Recording started, waiting for user to stop...');
        // Return a special message indicating recording is in progress
        return 'RECORDING_IN_PROGRESS';
      } else {
        throw Exception('Failed to start recording. Please try again.');
      }
      
    } catch (e) {
      print('🎤 GEMINI PRO: Error - $e');
      throw Exception('Gemini Pro recognition failed: $e');
    }
  }
  
  /// Process the recorded audio with Gemini
  Future<String> processRecordedAudio() async {
    try {
      // Get API key from environment
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found. Please add GEMINI_API_KEY to .env file');
      }

      // Use the stored audio path
      if (_currentAudioPath != null && _currentAudioPath!.isNotEmpty) {
        print('🎤 GEMINI PRO: Processing audio: $_currentAudioPath');
        print('🎤 GEMINI PRO: Sending audio to Gemini...');
        
        return await _processAudioWithGemini(_currentAudioPath!, apiKey);
      } else {
        throw Exception('No audio path available. Please try again.');
      }
      
    } catch (e) {
      print('🎤 GEMINI PRO: Error processing audio - $e');
      throw Exception('Failed to process audio: $e');
    }
  }

  /// Record raw audio for Gemini processing
  Future<String> _recordRawAudio() async {
    try {
      print('🎤 RECORD: Checking microphone permissions...');
      
      // Check if we have permission
      bool hasPermission = await _audioRecorder.hasPermission();
      print('🎤 RECORD: Has permission: $hasPermission');
      
      if (!hasPermission) {
        throw Exception('Microphone permission required');
      }

      // Create temporary file path
      final directory = Directory.systemTemp;
      final audioPath = '${directory.path}/gemini_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      print('🎤 RECORD: Starting audio recording to: $audioPath');
      
      // Start recording
      await _audioRecorder.start(
        path: audioPath,
        encoder: AudioEncoder.aacLc, // Compressed format, smaller than WAV
      );
      
      print('🎤 RECORD: Recording started successfully');
      
      // Record for a reasonable duration (5 seconds max for now)
      // TODO: Implement proper voice activity detection
      await Future.delayed(const Duration(seconds: 5));
      
      // Stop recording
      print('🎤 RECORD: Stopping recording...');
      final path = await _audioRecorder.stop();
      print('🎤 RECORD: Audio recording stopped: $path');
      
      // Verify file was created
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        print('🎤 RECORD: File exists: $exists, Size: $size bytes');
      }
      
      return path ?? '';
      
    } catch (e) {
      print('🎤 RECORD: Error during audio recording: $e');
      print('🎤 RECORD: Error type: ${e.runtimeType}');
      return '';
    }
  }

  /// Process audio file with Gemini Pro
  Future<String> _processAudioWithGemini(String audioPath, String apiKey) async {
    try {
      print('🤖 GEMINI API: Sending audio file to Gemini Pro...');
      
      final dio = Dio();
      final audioFile = File(audioPath);
      
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }
      
      // Read audio file as bytes
      final audioBytes = await audioFile.readAsBytes();
      print('🤖 GEMINI API: Audio file size: ${audioBytes.length} bytes');
      
      // Convert to base64
      final audioBase64 = base64Encode(audioBytes);
      
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {
                  "text": "Please transcribe this audio. If it's in Lithuanian, keep it in Lithuanian. If it's unclear, try to interpret what the person might have said."
                },
                {
                  "inline_data": {
                    "mime_type": "audio/mp4",
                    "data": audioBase64
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.1,
            "topK": 1,
            "topP": 1,
            "maxOutputTokens": 10000, // Supports up to 5+ minutes of audio
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🤖 GEMINI API: Response status: ${response.statusCode}');
      print('🤖 GEMINI API: Full response: ${response.data}');

      if (response.statusCode == 200) {
        final result = response.data;
        print('🤖 GEMINI API: Parsing response...');
        
        if (result['candidates'] != null && 
            result['candidates'].isNotEmpty && 
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          
          String geminiResult = result['candidates'][0]['content']['parts'][0]['text'];
          print('🤖 GEMINI API: Audio transcription result: $geminiResult');
          
          // Keep audio file for replay functionality
          print('🤖 GEMINI API: Audio file preserved for replay');
          
          return geminiResult;
        } else {
          print('🤖 GEMINI API: No valid candidates in response');
          print('🤖 GEMINI API: Response structure: ${result.keys}');
          
          // Check for prompt feedback (content filtering)
          if (result['promptFeedback'] != null) {
            print('🤖 GEMINI API: Prompt feedback: ${result['promptFeedback']}');
            final blockReason = result['promptFeedback']['blockReason'];
            if (blockReason != null) {
              print('🤖 GEMINI API: Content blocked - Reason: $blockReason');
              // This is likely a false positive for innocent content
              throw Exception('Content was blocked by Gemini (likely false positive): $blockReason');
            }
          }
          
          if (result['candidates'] != null) {
            print('🤖 GEMINI API: Candidates length: ${result['candidates'].length}');
            if (result['candidates'].isNotEmpty) {
              print('🤖 GEMINI API: First candidate: ${result['candidates'][0]}');
            }
          }
        }
      }
      
      throw Exception('Invalid response from Gemini API');
      
    } catch (e) {
      print('🤖 GEMINI API: Error - $e');
      // Keep audio file for retry/debugging purposes
      print('🤖 GEMINI API: Audio file preserved for retry/debugging');
      throw e;
    }
  }

  /// Process text with Gemini Pro for better understanding (legacy method)
  Future<String> _processWithGemini(String text, String apiKey) async {
    try {
      print('🤖 GEMINI API: Sending request to Gemini Pro...');
      final dio = Dio();
      
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {
                  "text": "Please transcribe and improve this speech recognition result. If it's in Lithuanian, keep it in Lithuanian. If it's unclear or seems like gibberish, try to interpret what the person might have said. Keep your response concise and direct: '$text'"
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.1,
            "topK": 1,
            "topP": 1,
            "maxOutputTokens": 10000, // Supports up to 5+ minutes of audio
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🤖 GEMINI API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['candidates'] != null && 
            result['candidates'].isNotEmpty && 
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          
          String geminiResult = result['candidates'][0]['content']['parts'][0]['text'];
          print('🤖 GEMINI API: Processed result: $geminiResult');
          return geminiResult;
        }
      }
      
      throw Exception('Invalid response from Gemini API');
      
    } catch (e) {
      print('🤖 GEMINI API: Error - $e');
      // Fallback to original text if Gemini fails
      return text;
    }
  }

  /// Check if text appears to be gibberish
  bool _isGibberish(String text) {
    if (text.isEmpty || text == 'No speech detected') return true;
    
    // Simple gibberish detection - check for common patterns
    String lowerText = text.toLowerCase();
    
    // Check for very short results (likely incomplete)
    if (text.length < 3) return true;
    
    // Check for common gibberish patterns
    List<String> gibberishPatterns = [
      'mhm', 'uh', 'um', 'ah', 'eh', 'oh',
      'hmm', 'mmm', 'err', 'umm'
    ];
    
    for (String pattern in gibberishPatterns) {
      if (lowerText.contains(pattern)) return true;
    }
    
    // Check for repeated characters (like "aaaa" or "mmmm")
    RegExp repeatedChars = RegExp(r'(.)\1{3,}');
    if (repeatedChars.hasMatch(text)) return true;
    
    return false;
  }
  
  /// Check if speech recognition is available for language
  Future<bool> isAvailable(String language) async {
    try {
      bool available = await _speech.initialize();
      if (!available) return false;
      
      List<stt.LocaleName> locales = await _speech.locales();
      return locales.any((locale) => locale.localeId == language);
    } catch (e) {
      return false;
    }
  }
  
  /// Request speech recognition permissions
  Future<SpeechPermissionStatus> requestPermission() async {
    try {
      bool available = await _speech.initialize();
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
      bool available = await _speech.initialize();
      if (!available) return ['en-US'];
      
      List<stt.LocaleName> locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      return ['en-US']; // Fallback to English
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

/// Speech Permission Status
enum SpeechPermissionStatus {
  notDetermined,
  denied,
  restricted,
  authorized,
}

/// Speech Service Provider
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

/// Speech Permission Provider
final speechPermissionProvider = StateProvider<SpeechPermissionStatus>((ref) {
  return SpeechPermissionStatus.notDetermined;
});

/// Speech Engine Preference Provider
final speechEngineProvider = StateNotifierProvider<SpeechEngineNotifier, String>((ref) {
  return SpeechEngineNotifier();
});

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
