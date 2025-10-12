// TODO: Add Realm back when we implement local storage
// import 'package:realm/realm.dart';

// Temporary data models for MVP
class Command {
  final String id;
  final String userId;
  final String? audioPath;
  final String transcription;
  final String? rawLLMOutput;
  final DateTime timestamp;
  final String status;
  final double? confidence;
  final List<Entity> entities;
  final String? language;
  final String? source;
  final Map<String, String>? metadata;

  Command({
    required this.id,
    required this.userId,
    this.audioPath,
    required this.transcription,
    this.rawLLMOutput,
    required this.timestamp,
    required this.status,
    this.confidence,
    required this.entities,
    this.language,
    this.source,
    this.metadata,
  });
}

class Entity {
  final String id;
  final String type;
  final String content;
  final String targetConnector;
  final String? externalId;
  final DateTime? scheduledTime;
  final String status;
  final double confidence;
  final String? reasoning;
  final Map<String, String>? metadata;

  Entity({
    required this.id,
    required this.type,
    required this.content,
    required this.targetConnector,
    this.externalId,
    this.scheduledTime,
    required this.status,
    required this.confidence,
    this.reasoning,
    this.metadata,
  });
}

class UserConfig {
  final String userId;
  final String? name;
  final String? email;
  final String? googleAccessToken;
  final String? googleRefreshToken;
  final DateTime? googleTokenExpiry;
  final String? evernoteAccessToken;
  final String? evernoteRefreshToken;
  final DateTime? evernoteTokenExpiry;
  final Map<String, String> preferences;
  final String defaultLanguage;
  final double confidenceThreshold;
  final bool darkModeEnabled;
  final bool hapticFeedbackEnabled;
  final bool soundEnabled;
  final String? customAlarmSound;
  final int totalCommands;
  final int successfulCommands;
  final DateTime lastUsed;

  UserConfig({
    required this.userId,
    this.name,
    this.email,
    this.googleAccessToken,
    this.googleRefreshToken,
    this.googleTokenExpiry,
    this.evernoteAccessToken,
    this.evernoteRefreshToken,
    this.evernoteTokenExpiry,
    required this.preferences,
    required this.defaultLanguage,
    required this.confidenceThreshold,
    required this.darkModeEnabled,
    required this.hapticFeedbackEnabled,
    required this.soundEnabled,
    this.customAlarmSound,
    required this.totalCommands,
    required this.successfulCommands,
    required this.lastUsed,
  });
}
