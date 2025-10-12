import 'dart:developer' as developer;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Simple logging utility for debugging and error tracking
class Logger {
  static const String _tag = 'FinallyDone';
  
  /// Log debug information
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 500, // Debug level
    );
  }
  
  /// Log info messages
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // Info level
    );
  }
  
  /// Log warnings
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // Warning level
    );
  }
  
  /// Log errors with stack trace
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
    
    // Send to Sentry for error tracking
    if (error != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    } else {
      Sentry.captureMessage('ERROR: $message', level: SentryLevel.error);
    }
  }
  
  /// Log critical errors that should be reported
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      '🚨 CRITICAL: $message',
      name: tag ?? _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
    
    // Send to Sentry for error tracking
    if (error != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    } else {
      Sentry.captureMessage('CRITICAL: $message', level: SentryLevel.error);
    }
  }
  
  /// Handle exceptions consistently - logs and sends to Sentry
  static void handleException(Object error, StackTrace? stackTrace, {String? tag, String? context}) {
    final message = context != null ? '$context: $error' : error.toString();
    Logger.error(message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Safe exception handler - always sends to Sentry, even if logging fails
  static void safeHandleException(Object error, StackTrace? stackTrace, {String? tag, String? context}) {
    try {
      // Try to log normally
      handleException(error, stackTrace, tag: tag, context: context);
    } catch (loggingError) {
      // If logging fails, at least send to Sentry
      print('⚠️ Logger failed, but sending to Sentry: $error');
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
  
  /// Simple helper for try/catch blocks - just call this in catch
  static void catchAndLog(Object error, StackTrace? stackTrace, {String? tag, String? context}) {
    handleException(error, stackTrace, tag: tag, context: context);
  }
  
  /// Wrapper for try/catch blocks that automatically logs exceptions
  static T? tryCatch<T>(T Function() operation, {String? tag, String? context, T? fallback}) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleException(error, stackTrace, tag: tag, context: context);
      return fallback;
    }
  }
  
  /// Wrapper for async try/catch blocks that automatically logs exceptions
  static Future<T?> tryCatchAsync<T>(Future<T> Function() operation, {String? tag, String? context, T? fallback}) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleException(error, stackTrace, tag: tag, context: context);
      return fallback;
    }
  }
  
}
