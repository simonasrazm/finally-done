/// Generic retry mechanism with exponential backoff
/// 
/// This utility provides a configurable retry mechanism that can be used
/// across different parts of an application. It supports custom retry sequences
/// and follows industry best practices for handling transient failures.
/// 
/// Example usage:
/// ```dart
/// final result = await RetryMechanism.execute(
///   () => someAsyncOperation(),
///   maxRetries: 3,
///   retrySequence: [1, 3, 10], // seconds
/// );
/// ```
class RetryMechanism {
  /// Default retry sequence: 1s, 3s, 10s, 1m, 5m, 1h
  static const List<int> defaultRetrySequence = [1, 3, 10, 60, 300, 3600];
  
  /// Execute an async operation with retry logic
  /// 
  /// [operation] - The async operation to execute
  /// [retrySequence] - Custom retry delays in seconds (default: [1, 3, 10, 60, 300, 3600])
  /// [shouldRetry] - Optional function to determine if an error should trigger a retry
  /// [onRetry] - Optional callback called before each retry attempt
  /// [onMaxRetriesReached] - Optional callback called when max retries are reached
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    List<int>? retrySequence,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, int delaySeconds)? onRetry,
    void Function(int totalAttempts)? onMaxRetriesReached,
  }) async {
    final sequence = retrySequence ?? defaultRetrySequence;
    int attempt = 0;
    
    while (attempt <= sequence.length) {
      try {
        final result = await operation();
        return result;
      } catch (error) {
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // Check if we've reached max retries (based on sequence length)
        if (attempt >= sequence.length) {
          onMaxRetriesReached?.call(attempt + 1);
          rethrow;
        }
        
        // Calculate delay for this retry attempt
        final delayIndex = attempt < sequence.length ? attempt : sequence.length - 1;
        final delaySeconds = sequence[delayIndex];
        
        // Call retry callback
        onRetry?.call(attempt + 1, delaySeconds);
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: delaySeconds));
        attempt++;
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Retry mechanism reached unexpected state');
  }
  
  /// Execute a sync operation with retry logic
  static T executeSync<T>(
    T Function() operation, {
    List<int>? retrySequence,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, int delaySeconds)? onRetry,
    void Function(int totalAttempts)? onMaxRetriesReached,
  }) {
    final sequence = retrySequence ?? defaultRetrySequence;
    int attempt = 0;
    
    while (attempt <= sequence.length) {
      try {
        final result = operation();
        return result;
      } catch (error) {
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // Check if we've reached max retries (based on sequence length)
        if (attempt >= sequence.length) {
          onMaxRetriesReached?.call(attempt + 1);
          rethrow;
        }
        
        // Calculate delay for this retry attempt
        final delayIndex = attempt < sequence.length ? attempt : sequence.length - 1;
        final delaySeconds = sequence[delayIndex];
        
        // Call retry callback
        onRetry?.call(attempt + 1, delaySeconds);
        
        // Wait before retrying (sync version uses a simple loop)
        _syncDelay(delaySeconds);
        attempt++;
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Retry mechanism reached unexpected state');
  }
  
  /// Helper method to create a delay in sync context
  /// Note: This is a simple implementation - in production you might want
  /// to use a more sophisticated approach for sync delays
  static void _syncDelay(int seconds) {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed.inSeconds < seconds) {
      // Simple busy wait - not ideal for production but works for sync context
      // In a real app, you'd typically avoid sync delays or use platform-specific solutions
    }
  }
}

/// Simple retry configuration
class RetryConfig {
  final List<int> retrySequence;
  final bool Function(dynamic error)? shouldRetry;
  final void Function(int attempt, int delaySeconds)? onRetry;
  final void Function(int totalAttempts)? onMaxRetriesReached;
  
  const RetryConfig({
    this.retrySequence = RetryMechanism.defaultRetrySequence,
    this.shouldRetry,
    this.onRetry,
    this.onMaxRetriesReached,
  });
}

/// Extension methods for easier usage
extension RetryMechanismExtension<T> on Future<T> Function() {
  /// Execute this future with retry logic
  Future<T> withRetry({
    List<int>? retrySequence,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, int delaySeconds)? onRetry,
    void Function(int totalAttempts)? onMaxRetriesReached,
  }) {
    return RetryMechanism.execute(
      this,
      retrySequence: retrySequence,
      shouldRetry: shouldRetry,
      onRetry: onRetry,
      onMaxRetriesReached: onMaxRetriesReached,
    );
  }
}
