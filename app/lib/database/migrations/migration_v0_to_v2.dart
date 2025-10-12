import 'package:realm/realm.dart';
import '../../models/queued_command.dart';

/// Migration from v0 to v2 (cumulative)
/// Handles: v0→v1 (photoPaths) + v1→v2 (errorMessage + status renames)
class MigrationV0ToV2 {
  static const int fromVersion = 0;
  static const int toVersion = 2;
  
  static void migrate(Migration migration, int oldSchemaVersion) {
    print('🗄️ MIGRATION: v$oldSchemaVersion → v$toVersion');
    
    if (oldSchemaVersion < toVersion) {
      final oldCommands = migration.oldRealm.all('QueuedCommandRealm');
      print('🗄️ MIGRATION: Found ${oldCommands.length} commands to migrate');
      
      for (final oldCommand in oldCommands) {
        try {
          final id = oldCommand.dynamic.get('id') as String;
          final status = oldCommand.dynamic.get('status') as String;
          
          final newCommand = migration.newRealm.find<QueuedCommandRealm>(id);
          if (newCommand != null) {
            // v0→v1: Initialize photoPaths
            if (oldSchemaVersion < 1) {
              newCommand.photoPaths.clear();
            }
            
            // v1→v2: Update status names + add errorMessage
            if (oldSchemaVersion < 2) {
              if (status == 'audioRecorded') {
                newCommand.status = 'recorded';
              } else if (status == 'transcribed') {
                newCommand.status = 'queued';
              }
              // errorMessage is null by default
            }
            
            print('🗄️ MIGRATION: Migrated command: $id');
          }
        } catch (e) {
          print('🗄️ MIGRATION: Error migrating command: $e');
        }
      }
    }
  }
}
