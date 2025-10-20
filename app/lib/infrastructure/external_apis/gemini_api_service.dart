import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service responsible for Gemini API integration
class GeminiApiService {
  final Dio _dio = Dio();
  
  /// Get API key from environment
  String? get _apiKey => dotenv.env['GEMINI_API_KEY'];
  
  /// Check if API key is available
  bool get isApiKeyAvailable => _apiKey != null && _apiKey!.isNotEmpty;
  
  /// Read transcription prompts from markdown file
  Future<String> getTranscriptionPrompt() async {
    try {
      // Read the markdown file from assets
      final promptData = await rootBundle.loadString('docs/speech_transcription_prompts.md');
      
      // Extract the system prompt from the markdown
      final lines = promptData.split('\n');
      bool inCodeBlock = false;
      final List<String> promptLines = [];
      
      for (final line in lines) {
        if (line.trim().startsWith('```')) {
          inCodeBlock = !inCodeBlock;
          continue;
        }
        if (inCodeBlock && line.trim().isNotEmpty) {
          promptLines.add(line);
        }
      }
      
      if (promptLines.isEmpty) {
        throw Exception('No transcription prompt found in markdown file');
      }
      
      return promptLines.join('\n');
    } catch (e) {
      throw Exception('Failed to load transcription prompts from markdown file: $e');
    }
  }
  
  /// Process audio file with Gemini Pro
  Future<String> processAudioFile(String audioPath) async {
    if (!isApiKeyAvailable) {
      throw const GeminiApiException('Gemini API key not found. Please add GEMINI_API_KEY to .env file');
    }

    try {
      final audioFile = File(audioPath);
      
      if (!await audioFile.exists()) {
        throw GeminiApiException('Audio file not found: $audioPath');
      }
      
      // Read audio file as bytes
      final audioBytes = await audioFile.readAsBytes();
      
      // Convert to base64
      final audioBase64 = base64Encode(audioBytes);
      
      // Get transcription prompt from markdown file
      final transcriptionPrompt = await getTranscriptionPrompt();
      
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': transcriptionPrompt
                },
                {
                  'inline_data': {
                    'mime_type': 'audio/mp4',
                    'data': audioBase64
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 10000,
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        
        if (result['candidates'] != null && 
            result['candidates'].isNotEmpty && 
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final String geminiResult = result['candidates'][0]['content']['parts'][0]['text'];
          return geminiResult;
        } else {
          // Check for prompt feedback (content filtering)
          if (result['promptFeedback'] != null) {
            final blockReason = result['promptFeedback']['blockReason'];
            if (blockReason != null) {
              throw GeminiApiException('Content was blocked by Gemini (likely false positive): $blockReason');
            }
          }
        }
      }
      
      throw const GeminiApiException('Invalid response from Gemini API');
      
    } catch (e) {
      throw e is GeminiApiException ? e : GeminiApiException('Audio processing failed: $e');
    }
  }
  
  /// Process text with Gemini Pro for better understanding (legacy method)
  Future<String> processText(String text) async {
    if (!isApiKeyAvailable) {
      throw const GeminiApiException('Gemini API key not found. Please add GEMINI_API_KEY to .env file');
    }

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': "Please transcribe and improve this speech recognition result. If it's in Lithuanian, keep it in Lithuanian. If it's unclear or seems like gibberish, try to interpret what the person might have said. Keep your response concise and direct: '$text'"
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 10000,
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['candidates'] != null && 
            result['candidates'].isNotEmpty && 
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final String geminiResult = result['candidates'][0]['content']['parts'][0]['text'];
          return geminiResult;
        }
      }
      
      throw const GeminiApiException('Invalid response from Gemini API');
      
    } catch (e) {
      // Fallback to original text if Gemini fails
      return text;
    }
  }
}

/// Gemini API Exception
class GeminiApiException implements Exception {
  const GeminiApiException(this.message);
  final String message;
  
  @override
  String toString() => 'GeminiApiException: $message';
}

/// Provider for GeminiApiService
final geminiApiServiceProvider = Provider<GeminiApiService>((ref) {
  return GeminiApiService();
});
