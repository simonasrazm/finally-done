import 'package:realm/realm.dart';
import '../../models/queued_command.dart';

/// Migration from v1 to v2
/// Handles: errorMessage field + status renames
class MigrationV1ToV2 {
  static const int fromVersion = 1;
  static const int toVersion = 2;
  
  static void migrate(Migration migration, int oldSchemaVersion) {
    
    if (oldSchemaVersion == 1) {
      final oldCommands = migration.oldRealm.all('QueuedCommandRealm');
      
      for (final oldCommand in oldCommands) {
        try {
          final id = oldCommand.dynamic.get('id') as String;
          final status = oldCommand.dynamic.get('status') as String;
          
          final newCommand = migration.newRealm.find<QueuedCommandRealm>(id);
          if (newCommand != null) {
            // Update status names
            if (status == 'audioRecorded') {
              newCommand.status = 'recorded';
            } else if (status == 'transcribed') {
              newCommand.status = 'queued';
            }
            // errorMessage is null by default (new field)
            
          }
        } catch (e) {
        }
      }
    }
  }
}
