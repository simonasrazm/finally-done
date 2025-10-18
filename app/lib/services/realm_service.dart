import 'package:realm/realm.dart';
import '../models/queued_command.dart';
import '../database/migrations/migration_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Realm database service for persistent storage
class RealmService {
  late Realm _realm;

  RealmService() {
    _initializeRealm();
  }

  void _initializeRealm() {
    try {
  // SCHEMA VERSION HISTORY:
  // v0: Initial schema (id, text, audioPath, status, createdAt, transcription)
  // v1: Added photoPaths (List<String>)
  // v2: Added errorMessage (String?) + status renames (audioRecorded→recorded, transcribed→queued)
  // v3: (intermediate version - not used in production)
  // v4: Added failed flag (bool) - separate from status
  // v5: Added actionNeeded flag (bool) - indicates if command needs user attention
      final config = Configuration.local([
        QueuedCommandRealm.schema,
      ], schemaVersion: MigrationManager.currentVersion, migrationCallback: MigrationManager.migrate);
      _realm = Realm(config);
    } catch (e) {
      rethrow;
    }
  }


  /// Get all queued commands
  List<QueuedCommandRealm> getAllCommands() {
    try {
      final realmCommands = _realm.all<QueuedCommandRealm>();
      return realmCommands.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get queued commands only
  List<QueuedCommandRealm> getQueuedCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>('status == "queued"');
      return realmCommands.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get processing commands
  List<QueuedCommandRealm> getProcessingCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>(
        'status == "transcribing" OR status == "transcribed" OR status == "processing"'
      );
      return realmCommands.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get completed commands
  List<QueuedCommandRealm> getCompletedCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>('status == "completed"');
      return realmCommands.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get failed commands
  List<QueuedCommandRealm> getFailedCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>('failed == true');
      return realmCommands.toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new command
  void addCommand(QueuedCommandRealm command) {
    try {
      _realm.write(() {
        _realm.add(command);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update command status
  void updateCommandStatus(String id, CommandStatus status) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          realmCommand.status = status.name;
        });
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update command transcription
  void updateCommandTranscription(String id, String transcription) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          realmCommand.transcription = transcription;
        });
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update command audio path
  void updateCommandAudioPath(String id, String? audioPath) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          realmCommand.audioPath = audioPath;
        });
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update command failed flag
  void updateCommandFailed(String id, bool failed) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          realmCommand.failed = failed;
        });
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update command error message
  void updateCommandErrorMessage(String id, String? errorMessage) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          realmCommand.errorMessage = errorMessage;
        });
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  void updateCommandActionNeeded(String id, bool actionNeeded) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          realmCommand.actionNeeded = actionNeeded;
        });
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a command
  void removeCommand(String id) {
    try {
      final realmCommand = _realm.find<QueuedCommandRealm>(id);
      if (realmCommand != null) {
        _realm.write(() {
          _realm.delete(realmCommand);
        });
      } else {
        // Command not found for removal
      }
    } catch (e, stackTrace) {
      
      // Send to Sentry for debugging
      Sentry.captureException(e, stackTrace: stackTrace);
      
      rethrow;
    }
  }

  /// Clear all commands
  void clearAllCommands() {
    try {
      _realm.write(() {
        _realm.deleteAll<QueuedCommandRealm>();
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Close the database
  void close() {
    _realm.close();
  }
}
