# Exception Handling Guidelines

## Quick Reference

### IDE Snippets (VS Code)
- Type `trylog` → Get try/catch with Logger
- Type `trylogasync` → Get async try/catch with Logger  
- Type `logerror` → Get Logger.catchAndLog call

### Manual Approach
```dart
try {
  riskyOperation();
} catch (e, stackTrace) {
  Logger.catchAndLog(e, stackTrace, tag: 'OPERATION', context: 'Operation failed');
  // Handle the error
}
```

## What Gets Sent to Sentry

✅ **Unhandled exceptions** (global handlers catch these automatically)  
✅ **Exceptions in try/catch with Logger.catchAndLog()**  
❌ **Exceptions in try/catch without Logger** (silently swallowed)  

## Best Practices

1. **Always use Logger.catchAndLog()** in catch blocks
2. **Use meaningful tags** (e.g., 'RECORDING', 'DATABASE', 'NETWORK')
3. **Provide context** (e.g., 'Voice recording failed', 'Database query failed')
4. **Don't just print errors** - they won't reach Sentry

## Examples

### Good ✅
```dart
try {
  await recordAudio();
} catch (e, stackTrace) {
  Logger.catchAndLog(e, stackTrace, tag: 'RECORDING', context: 'Voice recording failed');
  setState(() => _isRecording = false);
}
```

### Bad ❌
```dart
try {
  await recordAudio();
} catch (e) {
  print('Error: $e'); // Won't reach Sentry!
  setState(() => _isRecording = false);
}
```

## Future: CI/CD Checks

When we add GitHub Actions, we'll add:
- Lint checks for try/catch without Logger
- Sentry integration tests
- Exception coverage reports
