# Breaking Change Migration Strategy

## When Breaking Changes Are Needed
- Performance optimization (changing data types)
- Security improvements (encryption changes)
- Major schema restructuring
- Platform changes (iOS → Android compatibility)

## Multi-Step Migration Strategy

### Step 1: Add New Schema (Backward Compatible)
```dart
// v3: Add new optimized fields alongside old ones
class _QueuedCommandRealm {
  // OLD FIELDS (keep for compatibility)
  late String id;
  late String text;
  
  // NEW FIELDS (optimized)
  late String optimizedId;  // New primary key
  late Map<String, dynamic> structuredData;  // New data structure
}
```

### Step 2: Data Migration (Background Process)
```dart
// Migrate data from old to new format
void migrateDataInBackground() {
  final oldCommands = _realm.all<QueuedCommandRealm>();
  for (final command in oldCommands) {
    // Convert old format to new format
    command.optimizedId = generateOptimizedId(command.id);
    command.structuredData = convertToStructured(command.text);
  }
}
```

### Step 3: Remove Old Fields (Breaking Change)
```dart
// v4: Remove old fields, keep only new ones
class _QueuedCommandRealm {
  late String optimizedId;  // New primary key
  late Map<String, dynamic> structuredData;  // New data structure
  // OLD FIELDS REMOVED
}
```

## Migration Paths for Breaking Changes

### Path A: Gradual Migration (Recommended)
- v2 → v3: Add new fields, keep old ones
- v3 → v4: Migrate data, remove old fields
- Users can skip v3 if they're on v2

### Path B: Forced Migration
- v2 → v4: Direct migration with data transformation
- Riskier but simpler for users

### Path C: App Store Strategy
- Release v3 with migration tools
- Wait for 90%+ users to migrate
- Release v4 with breaking changes
- Provide migration guide for remaining users

## Implementation Example

```dart
class BreakingChangeMigration {
  static void migrateV2ToV3(Migration migration, int oldVersion) {
    // Add new fields, keep old ones
    // This is backward compatible
  }
  
  static void migrateV3ToV4(Migration migration, int oldVersion) {
    // Transform data from old to new format
    // Remove old fields
    // This is breaking
  }
  
  static void migrateV2ToV4(Migration migration, int oldVersion) {
    // Direct migration for users who skipped v3
    // More complex but handles all cases
  }
}
```

## Best Practices

1. **Always provide migration path** from any supported version
2. **Test all migration paths** thoroughly
3. **Provide rollback strategy** if possible
4. **Communicate breaking changes** clearly to users
5. **Consider data export/import** for major changes
6. **Use feature flags** to enable new features gradually
