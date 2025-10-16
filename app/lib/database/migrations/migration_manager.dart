import 'package:realm/realm.dart';
import 'migration_v0_to_v2.dart';
import 'migration_v1_to_v2.dart';
import '../../models/queued_command.dart';

/// Central migration manager
/// Routes migrations based on oldSchemaVersion to appropriate migration class
class MigrationManager {
  static const int currentVersion = 5;
  
  /// Main migration entry point
  static void migrate(Migration migration, int oldSchemaVersion) {
    print('🗄️ MIGRATION MANAGER: Migrating from v$oldSchemaVersion to v$currentVersion');
    
    // Route to appropriate migration based on oldSchemaVersion
    if (oldSchemaVersion == 0) {
      // v0 can migrate directly to v2 (cumulative)
      MigrationV0ToV2.migrate(migration, oldSchemaVersion);
    } else if (oldSchemaVersion == 1) {
      // v1 migrates to v2
      MigrationV1ToV2.migrate(migration, oldSchemaVersion);
    } else if (oldSchemaVersion == 2) {
      // v2 migrates to v4 (errorMessage + failed flag)
      _migrateV2ToV4(migration, oldSchemaVersion);
    } else if (oldSchemaVersion == 3) {
      // v3 migrates to v4 (failed flag)
      _migrateV3ToV4(migration, oldSchemaVersion);
    } else if (oldSchemaVersion == 4) {
      // v4 migrates to v5 (actionNeeded flag)
      _migrateV4ToV5(migration, oldSchemaVersion);
    } else if (oldSchemaVersion == currentVersion) {
      // No migration needed
      print('🗄️ MIGRATION MANAGER: Already at current version');
    } else {
      // Unsupported version jump
      throw Exception('Unsupported migration from v$oldSchemaVersion to v$currentVersion');
    }
  }

  /// Migrate from v2 to v4 (add errorMessage + failed flag)
  static void _migrateV2ToV4(Migration migration, int oldSchemaVersion) {
    print('🗄️ MIGRATION V2→V4: Adding errorMessage and failed flag to existing commands');
    
    // Get all existing commands from old realm
    final oldCommands = migration.oldRealm.all('QueuedCommandRealm');
    
    // Migrate each command
    for (final oldCommand in oldCommands) {
      final id = oldCommand.dynamic.get('id') as String;
      
      // Find the corresponding command in new realm
      final newCommand = migration.newRealm.find<QueuedCommandRealm>(id);
      if (newCommand != null) {
        // Set errorMessage to null and failed flag to false for existing commands
        newCommand.errorMessage = null;
        newCommand.failed = false;
        print('🗄️ MIGRATION V2→V4: Set errorMessage=null, failed=false for command $id');
      }
    }
    
    print('🗄️ MIGRATION V2→V4: Migration completed');
  }

  /// Migrate from v3 to v4 (add failed flag)
  static void _migrateV3ToV4(Migration migration, int oldSchemaVersion) {
    print('🗄️ MIGRATION V3→V4: Adding failed flag to existing commands');
    
    // Get all existing commands from old realm
    final oldCommands = migration.oldRealm.all('QueuedCommandRealm');
    
    // Migrate each command
    for (final oldCommand in oldCommands) {
      final id = oldCommand.dynamic.get('id') as String;
      
      // Find the corresponding command in new realm
      final newCommand = migration.newRealm.find<QueuedCommandRealm>(id);
      if (newCommand != null) {
        // Set failed flag to false for existing commands
        newCommand.failed = false;
        print('🗄️ MIGRATION V3→V4: Set failed=false for command $id');
      }
    }
    
    print('🗄️ MIGRATION V3→V4: Migration completed');
  }

  /// Migrate from v4 to v5 (add actionNeeded flag)
  static void _migrateV4ToV5(Migration migration, int oldSchemaVersion) {
    print('🗄️ MIGRATION V4→V5: Adding actionNeeded flag to existing commands');
    
    // Get all existing commands from old realm
    final oldCommands = migration.oldRealm.all('QueuedCommandRealm');
    
    // Migrate each command
    for (final oldCommand in oldCommands) {
      final id = oldCommand.dynamic.get('id') as String;
      
      // Find the corresponding command in new realm
      final newCommand = migration.newRealm.find<QueuedCommandRealm>(id);
      if (newCommand != null) {
        // Set actionNeeded flag to false for existing commands
        newCommand.actionNeeded = false;
        print('🗄️ MIGRATION V4→V5: Set actionNeeded=false for command $id');
      }
    }
    
    print('🗄️ MIGRATION V4→V5: Migration completed');
  }

  /// Get all supported migration paths
  static List<MigrationPath> getSupportedPaths() {
    return [
      MigrationPath(from: 0, to: 2, description: 'Initial to v2 (cumulative)'),
      MigrationPath(from: 1, to: 2, description: 'PhotoPaths to v2'),
      MigrationPath(from: 2, to: 4, description: 'v2 to v4 (errorMessage + failed flag)'),
      MigrationPath(from: 3, to: 4, description: 'v3 to v4 (failed flag)'),
      MigrationPath(from: 4, to: 5, description: 'v4 to v5 (actionNeeded flag)'),
    ];
  }
}

class MigrationPath {
  final int from;
  final int to;
  final String description;
  
  const MigrationPath({
    required this.from,
    required this.to,
    required this.description,
  });
}
