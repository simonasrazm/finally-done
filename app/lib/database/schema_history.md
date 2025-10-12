# Database Schema History

## Version 0 (Initial)
- `id` (String, PrimaryKey)
- `text` (String)
- `audioPath` (String?, Optional)
- `status` (String)
- `createdAt` (DateTime)
- `transcription` (String?, Optional)

## Version 1 (2024-01-XX)
**Changes:**
- Added `photoPaths` (List<String>) - for photo attachments

**Migration:**
- Initialize `photoPaths` as empty list for existing records

## Version 2 (2024-01-XX)
**Changes:**
- Added `errorMessage` (String?, Optional) - for error details
- Renamed statuses:
  - `audioRecorded` → `recorded`
  - `transcribed` → `queued` (transcribed audio becomes queued for processing)

**Migration:**
- Initialize `errorMessage` as null for existing records
- Update status values for existing records

## Future Versions
When adding new fields:
1. Update this file with version number, date, and changes
2. Update `schemaVersion` in `realm_service.dart`
3. Add migration logic to `_migrateRealm()`
4. Test migration from oldest supported version

## Migration Testing Checklist
- [ ] Test migration from v0 → v2
- [ ] Test migration from v1 → v2  
- [ ] Test fresh install (no migration)
- [ ] Verify data integrity after migration
- [ ] Test rollback scenarios
