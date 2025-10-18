import 'package:realm/realm.dart';

part 'queued_command.realm.dart';

/// Realm database model for storing user commands
/// 
/// This table stores all user commands (voice/text) that are queued for processing.
/// Commands flow through different statuses: queued → transcribing → processing → completed
@RealmModel()
class _QueuedCommandRealm {
  /// Primary key - unique identifier for each command
  @PrimaryKey()
  late String id;
  
  /// Original command text entered by user (voice or text)
  late String text;
  
  /// Path to audio file if command was voice input (null for text input)
  String? audioPath;

  /// List of photo file paths attached to this command
  List<String> photoPaths = [];

  /// Current processing status: queued, transcribing, transcribed, processing, completed
  late String status;
  
  /// When the command was created by user
  late DateTime createdAt;
  
  /// Transcribed text from audio (null if not voice input or not yet transcribed)
  String? transcription;

  /// Error message if command has failed (null if not failed)
  String? errorMessage;

  /// Failed flag - indicates if this command has failed (separate from status)
  bool failed = false;

  /// Action needed flag - indicates if this command needs user attention
  bool actionNeeded = false;

  // Helper method for creating copies
  _QueuedCommandRealm copyWith({
    String? id,
    String? text,
    String? audioPath,
    List<String>? photoPaths,
    String? status,
    DateTime? createdAt,
    String? transcription,
    String? errorMessage,
    bool? failed,
    bool? actionNeeded,
  }) {
    final newCommand = _QueuedCommandRealm();
    newCommand.id = id ?? this.id;
    newCommand.text = text ?? this.text;
    newCommand.audioPath = audioPath ?? this.audioPath;
    newCommand.photoPaths = photoPaths ?? this.photoPaths;
    newCommand.status = status ?? this.status;
    newCommand.createdAt = createdAt ?? this.createdAt;
    newCommand.transcription = transcription ?? this.transcription;
    newCommand.errorMessage = errorMessage ?? this.errorMessage;
    newCommand.failed = failed ?? this.failed;
    newCommand.actionNeeded = actionNeeded ?? this.actionNeeded;
    return newCommand;
  }
}

// Extension to add copyWith method to the generated class
extension QueuedCommandRealmExtension on QueuedCommandRealm {
  QueuedCommandRealm copyWithRealm({
    String? id,
    String? text,
    String? audioPath,
    List<String>? photoPaths,
    String? status,
    DateTime? createdAt,
    String? transcription,
    String? errorMessage,
    bool? failed,
    bool? actionNeeded,
  }) {
    // Create a new instance using the constructor from the generated class
    final newCommand = QueuedCommandRealm(
      id ?? this.id,
      text ?? this.text,
      status ?? this.status,
      createdAt ?? this.createdAt,
      audioPath: audioPath ?? this.audioPath,
      photoPaths: photoPaths ?? this.photoPaths,
      transcription: transcription ?? this.transcription,
      errorMessage: errorMessage ?? this.errorMessage,
      failed: failed ?? this.failed,
      actionNeeded: actionNeeded ?? this.actionNeeded,
    );
    return newCommand;
  }
}

/// Command status enum
/// 
/// Logical flow:
/// Voice: recorded → manual_review → transcribing → queued → processing → completed
/// Text:  queued → processing → completed
/// Note: Failed state is now handled by the 'failed' flag, not status
enum CommandStatus {
  recorded,         // Audio recorded, waiting for manual review
  manual_review,    // Audio needs manual review before transcription
  transcribing,     // Audio being transcribed by AI
  queued,           // Ready to process (text input or transcribed audio)
  processing,       // Being processed by agent
  completed        // Successfully executed
}