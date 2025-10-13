# Retry Mechanism Utility

A simple retry mechanism with configurable delays for Dart/Flutter applications.

## Features

- **Configurable retry sequences** - Default: 1s, 3s, 10s, 1m, 5m, 1h
- **Custom retry logic** - Define when to retry based on error type
- **Async and sync support** - Works with both `Future` and synchronous operations
- **Simple API** - Max retries = sequence length

## Quick Start

```dart
import 'package:your_app/utils/retry_mechanism.dart';

// Basic usage (uses default sequence: 1s, 3s, 10s, 1m, 5m, 1h)
final result = await RetryMechanism.execute(
  () => someAsyncOperation(),
);

// With custom retry sequence (max retries = sequence length)
final result = await RetryMechanism.execute(
  () => apiCall(),
  retrySequence: [1, 3, 10, 30, 60], // 5 retries total
);

// With error filtering
final result = await RetryMechanism.execute(
  () => networkRequest(),
  shouldRetry: (error) => error is TimeoutException,
);
```

## Configuration

```dart
// Custom retry sequence (3 retries: 1s, 2s, 4s)
await RetryMechanism.execute(
  () => someOperation(),
  retrySequence: [1, 2, 4],
  shouldRetry: (error) => error is TimeoutException,
);
```

## Extension Methods

```dart
// Cleaner syntax
await someOperation().withRetry(
  retrySequence: [1, 3, 10],
);
```
