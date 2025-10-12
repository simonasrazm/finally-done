import 'package:realm/realm.dart';
import 'migration_v0_to_v2.dart';
import 'migration_v1_to_v2.dart';

/// Central migration manager
/// Routes migrations based on oldSchemaVersion to appropriate migration class
class MigrationManager {
  static const int currentVersion = 2;
  
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
    } else if (oldSchemaVersion == currentVersion) {
      // No migration needed
      print('🗄️ MIGRATION MANAGER: Already at current version');
    } else {
      // Unsupported version jump
      throw Exception('Unsupported migration from v$oldSchemaVersion to v$currentVersion');
    }
  }
  
  /// Get all supported migration paths
  static List<MigrationPath> getSupportedPaths() {
    return [
      MigrationPath(from: 0, to: 2, description: 'Initial to current (cumulative)'),
      MigrationPath(from: 1, to: 2, description: 'PhotoPaths to current'),
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
