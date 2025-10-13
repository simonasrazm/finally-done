# Sentry Error Handling Architecture

This document describes the comprehensive error monitoring and reporting system implemented in Finally Done.

## Overview

The app uses a **hybrid error reporting system** that combines Flutter and native iOS error handling to provide comprehensive error monitoring through Sentry.

## Architecture Diagram

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Native iOS     │    │   Sentry SDK    │
│                 │    │   (Swift)        │    │                 │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ • Flutter errors│    │ • Native errors  │    │ • Error storage │
│ • UI exceptions │    │ • Google Sign-In │    │ • Performance   │
│ • Async errors  │    │ • System crashes │    │ • Session Replay│
│ • Business logic│    │ • Memory issues  │    │ • Release track │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    Error Queue System   │
                    │                         │
                    │ • Queues errors when    │
                    │   Sentry not ready      │
                    │ • Flushes on init       │
                    │ • Retry mechanism       │
                    └─────────────────────────┘
```

## Error Handling Responsibilities

### Flutter Side

**Files**: `main.dart`, `services/*.dart`, `screens/*.dart`

**Responsibilities**:
- **Flutter exceptions**: UI errors, widget crashes, async errors
- **Business logic errors**: Service failures, API errors, validation errors
- **Performance monitoring**: Custom transactions and spans
- **Global error handlers**: `FlutterError.onError`, `PlatformDispatcher.instance.onError`

**Implementation**:
```dart
// Global error handlers in main.dart
FlutterError.onError = (FlutterErrorDetails details) {
  Sentry.captureException(details.exception, stackTrace: details.stack);
};

PlatformDispatcher.instance.onError = (error, stack) {
  Sentry.captureException(error, stackTrace: stack);
  return true;
};
```

### Native iOS Side

**Files**: `ios/Runner/AppDelegate.swift`

**Responsibilities**:
- **Native crashes**: Memory access violations, thread deadlocks
- **Google Sign-In errors**: Configuration issues, authentication failures
- **System-level errors**: Keychain access, file system errors
- **Method channel errors**: Swift-to-Flutter communication failures

**Implementation**:
```swift
// Error reporting in AppDelegate.swift
func reportError(_ error: Error, context: String = "") {
  let nsError = error as NSError
  let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
  
  if SentrySDK.isEnabled {
    SentrySDK.capture(error: error) { scope in
      scope.setTag(value: "native_swift", key: "source")
      scope.setTag(value: "ios", key: "platform")
      scope.setContext(value: [
        "domain": nsError.domain,
        "code": nsError.code,
        "thread": "\(Thread.current)",
        "context": context
      ], key: "swift_error")
    }
  } else {
    errorQueue.append(error)
  }
}
```

## Error Queue System

### Problem
Native iOS errors can occur before Sentry is initialized, leading to lost error reports.

### Solution
A sophisticated error queue system that:
1. **Queues errors** when `SentrySDK.isEnabled = false`
2. **Flushes queue** after Sentry initialization
3. **Retries with exponential backoff** if flushing fails
4. **Filters duplicates** to prevent noise

### Implementation

#### Swift Side (Error Queuing)
```swift
private var errorQueue: [Error] = []

func reportError(_ error: Error, context: String = "") {
  if SentrySDK.isEnabled {
    // Send directly to Sentry
    SentrySDK.capture(error: error) { scope in
      // ... configure scope
    }
  } else {
    // Queue for later
    errorQueue.append(error)
  }
}

func flushErrorQueue() -> Int {
  if SentrySDK.isEnabled {
    let errorCount = errorQueue.count
    for error in errorQueue {
      SentrySDK.capture(error: error) { scope in
        // ... configure scope
      }
    }
    errorQueue.removeAll()
    return errorCount
  }
  return 0
}
```

#### Flutter Side (Queue Flushing)
```dart
// In main.dart after Sentry initialization
const errorQueueChannel = MethodChannel('error_queue');

await RetryMechanism.execute(
  () async {
    final result = await errorQueueChannel.invokeMethod('flushQueue');
    final flushedCount = result['count'] as int;
    
    if (flushedCount == 0) {
      throw Exception('No errors were flushed - SentrySDK may not be ready');
    }
  },
);
```

## Retry Mechanism

### Configuration
- **Retry Sequence**: 1s, 3s, 10s, 1m, 5m, 1h
- **Max Retries**: 6 attempts
- **Error Filtering**: Prevents duplicate reporting

### Implementation
```dart
class RetryMechanism {
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    List<Duration> retrySequence = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 10),
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(hours: 1),
    ],
    Function(int attempt, int delaySeconds)? onRetry,
    Function(int totalAttempts)? onMaxRetriesReached,
  }) async {
    // Implementation with exponential backoff
  }
}
```

## Performance Monitoring

### Custom Transactions
```dart
// App startup monitoring
final appStartTransaction = Sentry.startTransaction(
  'app.startup',
  'app.lifecycle',
);

// Google Sign-In monitoring
final transaction = Sentry.startTransaction('google.signin', 'auth');
final span = transaction.startChild('google.signin.call');
```

### Performance Spans
- **App Startup**: Complete app initialization time
- **Google Sign-In**: Authentication flow performance
- **API Calls**: Service integration response times
- **UI Interactions**: Critical user journey monitoring

## Configuration

### Flutter Sentry Setup
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = sentryDsn;
    options.tracesSampleRate = 1.0;
    options.debug = true; // Development only
    options.enableAutoSessionTracking = true;
    options.attachStacktrace = true;
    options.sendDefaultPii = false;
    
    // Session Replay
    options.replay.sessionSampleRate = 1.0;
    options.replay.onErrorSampleRate = 1.0;
    
    // Release tracking
    options.release = 'finally-done@1.0.0+1';
    options.dist = '1';
  },
  appRunner: () => runApp(FinallyDoneApp()),
);
```

### iOS Configuration
- **dSYM Upload**: Automatic symbolication for native crashes
- **Method Channels**: `safe_google_sign_in`, `error_queue`
- **Error Codes**: Negative values to prevent Sentry grouping

## Error Categories

### Flutter Errors
- **UI Exceptions**: Widget crashes, rendering errors
- **Async Errors**: Future/Stream failures
- **Business Logic**: Service failures, validation errors
- **State Management**: Riverpod provider errors

### Native iOS Errors
- **Configuration Errors**: Missing GoogleService-Info.plist
- **Authentication Errors**: Google Sign-In failures
- **System Errors**: Keychain access, file system issues
- **Memory Errors**: Access violations, thread deadlocks

## Best Practices

### Error Reporting
1. **Include Context**: Always provide meaningful error context
2. **Avoid Duplicates**: Use proper error grouping and fingerprinting
3. **Stack Traces**: Ensure stack traces are captured and symbolicated
4. **User Privacy**: Don't include sensitive user data

### Performance Monitoring
1. **Key Transactions**: Monitor critical user journeys
2. **Custom Spans**: Add spans for important operations
3. **Error Correlation**: Link performance issues to errors
4. **Release Tracking**: Monitor performance across releases

### Debugging
1. **Console Logs**: Use Logger for structured logging
2. **Sentry Debug**: Enable debug mode in development
3. **Error Context**: Include relevant business context
4. **Stack Trace Quality**: Ensure clean, meaningful stack traces

## Troubleshooting

### Common Issues

#### Errors Not Appearing in Sentry
1. Check if Sentry is properly initialized
2. Verify DSN configuration
3. Check error queue flushing
4. Ensure proper error categorization

#### Performance Data Missing
1. Verify transaction/span creation
2. Check sample rates
3. Ensure proper transaction finishing
4. Verify release configuration

#### Native Errors Not Reported
1. Check method channel setup
2. Verify error queue implementation
3. Ensure proper error code assignment
4. Check Sentry iOS SDK initialization

### Debug Commands
```bash
# Check Sentry configuration
flutter run --verbose

# Monitor error queue
# Check iOS console logs for "SWIFT DEBUG" messages

# Verify error reporting
# Check Sentry dashboard for recent errors
```

## Monitoring Dashboard

### Key Metrics
- **Error Rate**: Errors per session
- **Performance**: Transaction duration and spans
- **Release Health**: Error trends across releases
- **User Impact**: Affected users and sessions

### Alerts
- **Error Spike**: Sudden increase in error rate
- **Performance Degradation**: Slow transaction times
- **New Issues**: Previously unseen error types
- **Release Issues**: Errors in new releases

This error handling system ensures comprehensive monitoring and debugging capabilities while maintaining good performance and user experience.
