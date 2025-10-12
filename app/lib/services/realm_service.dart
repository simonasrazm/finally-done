import 'package:realm/realm.dart';
import '../models/queued_command.dart';
import '../utils/logger.dart';
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
      print('🗄️ REALM: Starting database initialization...');
      // SCHEMA VERSION HISTORY:
      // v0: Initial schema (id, text, audioPath, status, createdAt, transcription)
      // v1: Added photoPaths (List<String>)
      // v2: Added errorMessage (String?) + status renames (audioRecorded→recorded, transcribed→queued)
      print('🗄️ REALM: Creating configuration...');
      final config = Configuration.local([
        QueuedCommandRealm.schema,
      ], schemaVersion: MigrationManager.currentVersion, migrationCallback: MigrationManager.migrate);
      print('🗄️ REALM: Opening Realm database...');
      _realm = Realm(config);
      print('🗄️ REALM: Database initialized successfully');
    } catch (e) {
      print('🗄️ REALM: Error initializing database: $e');
      rethrow;
    }
  }


  /// Get all queued commands
  List<QueuedCommandRealm> getAllCommands() {
    try {
      final realmCommands = _realm.all<QueuedCommandRealm>();
      return realmCommands.toList();
    } catch (e) {
      print('🗄️ REALM: Error getting all commands: $e');
      return [];
    }
  }

  /// Get queued commands only
  List<QueuedCommandRealm> getQueuedCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>('status == "queued"');
      return realmCommands.toList();
    } catch (e) {
      print('🗄️ REALM: Error getting queued commands: $e');
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
      print('🗄️ REALM: Error getting processing commands: $e');
      return [];
    }
  }

  /// Get completed commands
  List<QueuedCommandRealm> getCompletedCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>('status == "completed"');
      return realmCommands.toList();
    } catch (e) {
      print('🗄️ REALM: Error getting completed commands: $e');
      return [];
    }
  }

  /// Get failed commands
  List<QueuedCommandRealm> getFailedCommands() {
    try {
      final realmCommands = _realm.query<QueuedCommandRealm>('status == "failed"');
      return realmCommands.toList();
    } catch (e) {
      print('🗄️ REALM: Error getting failed commands: $e');
      return [];
    }
  }

  /// Add a new command
  void addCommand(QueuedCommandRealm command) {
    try {
      print('🗄️ REALM: Adding command: "${command.text}"');
      _realm.write(() {
        _realm.add(command);
      });
      print('🗄️ REALM: Command added successfully');
    } catch (e) {
      print('🗄️ REALM: Error adding command: $e');
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
        print('🗄️ REALM: Updated command $id status to ${status.name}');
      } else {
        print('🗄️ REALM: Command $id not found for update');
      }
    } catch (e) {
      print('🗄️ REALM: Error updating command status: $e');
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
        print('🗄️ REALM: Updated command $id transcription');
      } else {
        print('🗄️ REALM: Command $id not found for transcription update');
      }
    } catch (e) {
      print('🗄️ REALM: Error updating transcription: $e');
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
        print('🗄️ REALM: Updated command $id audio path');
      } else {
        print('🗄️ REALM: Command $id not found for audio path update');
      }
    } catch (e) {
      print('🗄️ REALM: Error updating audio path: $e');
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
        Logger.info('Removed command from Realm: $id', tag: 'REALM');
      } else {
        Logger.warning('Command not found for removal: $id', tag: 'REALM');
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to remove command from Realm: $id', 
        tag: 'REALM', 
        error: e, 
        stackTrace: stackTrace
      );
      
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
      print('🗄️ REALM: Cleared all commands');
    } catch (e) {
      print('🗄️ REALM: Error clearing commands: $e');
      rethrow;
    }
  }

  /// Close the database
  void close() {
    _realm.close();
    print('🗄️ REALM: Database closed');
  }
}
