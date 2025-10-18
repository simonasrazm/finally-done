import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// NLP Service for AI Command Processing
/// Handles command interpretation using Gemini Pro
class NLPService {
  
  NLPService({Dio? dio, String? geminiApiKey}) 
      : _dio = dio ?? Dio(),
        _geminiApiKey = geminiApiKey;
  final Dio _dio;
  final String? _geminiApiKey;
  
  /// Parse command using Gemini Pro
  Future<ParsedCommand> parseCommand(String transcription) async {
    try {
      // Use Gemini Pro for command interpretation
      return await _parseWithGemini(transcription);
    } catch (e) {
      // Return low confidence result for manual review
      return ParsedCommand(
        entities: [],
        lowConfidence: true,
        error: e.toString(),
      );
    }
  }
  
  /// Parse with Gemini Pro
  Future<ParsedCommand> _parseWithGemini(String transcription) async {
    if (_geminiApiKey == null) {
      throw Exception('Gemini API key not configured');
    }
    
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
      queryParameters: {'key': _geminiApiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': _buildPrompt(transcription)}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topP': 0.9,
          'maxOutputTokens': 1000,
        }
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    
    final responseText = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
    return _parseResponse(responseText);
  }
  
  
  
  /// Build prompt for LLM
  String _buildPrompt(String transcription) {
    return '''
You are an AI assistant that parses voice commands into structured data for a personal organization app.

Parse this command: "$transcription"

Return ONLY a JSON object with this exact structure:
{
  "entities": [
    {
      "type": "task|event|note|alarm",
      "content": "extracted text",
      "target": "google_tasks|google_calendar|evernote|apple_notes|alarm",
      "datetime": "ISO 8601 if applicable",
      "confidence": 0.0-1.0,
      "reasoning": "why this interpretation"
    }
  ],
  "low_confidence": true/false
}

Rules:
- Extract entities from the command
- Determine appropriate target service
- Extract dates/times if mentioned
- Provide confidence score (0.0-1.0)
- Set low_confidence=true if confidence < 0.7
- Be conservative with confidence scores
- If unclear, prefer lower confidence for human review

Examples:
"Buy milk tomorrow" → task, google_tasks, confidence 0.9
"Meeting with John at 2pm" → event, google_calendar, confidence 0.8
"Note: password is abc123" → note, evernote, confidence 0.9
"Set alarm for 7am" → alarm, alarm, confidence 0.9
''';
  }
  
  /// Parse LLM response
  ParsedCommand _parseResponse(String response) {
    try {
      // Clean response (remove markdown if present)
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();
      
      final json = jsonDecode(cleanResponse) as Map<String, dynamic>;
      
      final entities = <ParsedEntity>[];
      for (final entityJson in json['entities'] as List) {
        entities.add(ParsedEntity.fromJson(entityJson as Map<String, dynamic>));
      }
      
      return ParsedCommand(
        entities: entities,
        lowConfidence: json['low_confidence'] as bool? ?? false,
      );
    } catch (e) {
      return ParsedCommand(
        entities: [],
        lowConfidence: true,
        error: 'Failed to parse LLM response: $e',
      );
    }
  }
}

/// Parsed Command Result
class ParsedCommand {
  
  const ParsedCommand({
    required this.entities,
    required this.lowConfidence,
    this.error,
  });
  final List<ParsedEntity> entities;
  final bool lowConfidence;
  final String? error;
  
  bool get hasError => error != null;
  bool get isEmpty => entities.isEmpty;
}

/// Parsed Entity
class ParsedEntity {
  
  const ParsedEntity({
    required this.type,
    required this.content,
    required this.target,
    this.datetime,
    required this.confidence,
    required this.reasoning,
  });
  
  factory ParsedEntity.fromJson(Map<String, dynamic> json) {
    return ParsedEntity(
      type: json['type'] as String,
      content: json['content'] as String,
      target: json['target'] as String,
      datetime: json['datetime'] != null 
          ? DateTime.tryParse(json['datetime'] as String)
          : null,
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
    );
  }
  final String type;
  final String content;
  final String target;
  final DateTime? datetime;
  final double confidence;
  final String reasoning;
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'target': target,
      'datetime': datetime?.toIso8601String(),
      'confidence': confidence,
      'reasoning': reasoning,
    };
  }
}

/// NLP Service Provider
final nlpServiceProvider = Provider<NLPService>((ref) {
  // TODO: Get Gemini API key from environment variables
  return NLPService(geminiApiKey: null);
});

/// Parsed Command Provider
final parsedCommandProvider = StateProvider<ParsedCommand?>((ref) {
  return null;
});
