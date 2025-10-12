import 'package:sentry_flutter/sentry_flutter.dart';

/// Modern performance monitoring utility using Sentry
class PerformanceMonitor {
  /// Start a performance transaction
  static ISentrySpan startTransaction(String name, String operation) {
    return Sentry.startTransaction(name, operation);
  }
  
  /// Start a child span within a transaction
  static ISentrySpan startChild(ISentrySpan transaction, String operation) {
    return transaction.startChild(operation);
  }
  
  /// Finish a span with success status
  static void finishSpan(ISentrySpan span, {Map<String, dynamic>? data}) {
    if (data != null) {
      data.forEach((key, value) => span.setData(key, value));
    }
    span.finish(status: const SpanStatus.ok());
  }
  
  /// Finish a span with error status
  static void finishSpanWithError(ISentrySpan span, dynamic error, {Map<String, dynamic>? data}) {
    if (data != null) {
      data.forEach((key, value) => span.setData(key, value));
    }
    span.setData('error', error.toString());
    span.finish(status: const SpanStatus.internalError());
  }
  
  /// Finish a span with cancelled status
  static void finishSpanCancelled(ISentrySpan span, {Map<String, dynamic>? data}) {
    if (data != null) {
      data.forEach((key, value) => span.setData(key, value));
    }
    span.finish(status: const SpanStatus.cancelled());
  }
  
  /// Measure a function execution with Sentry spans
  static Future<T> measure<T>(
    String transactionName,
    String operation,
    Future<T> Function() function, {
    Map<String, dynamic>? data,
  }) async {
    final transaction = startTransaction(transactionName, operation);
    final span = startChild(transaction, operation);
    
    try {
      final result = await function();
      finishSpan(span, data: data);
      transaction.finish(status: const SpanStatus.ok());
      return result;
    } catch (e) {
      finishSpanWithError(span, e, data: data);
      transaction.finish(status: const SpanStatus.internalError());
      rethrow;
    }
  }
  
  /// Measure a synchronous function execution
  static T measureSync<T>(
    String transactionName,
    String operation,
    T Function() function, {
    Map<String, dynamic>? data,
  }) {
    final transaction = startTransaction(transactionName, operation);
    final span = startChild(transaction, operation);
    
    try {
      final result = function();
      finishSpan(span, data: data);
      transaction.finish(status: const SpanStatus.ok());
      return result;
    } catch (e) {
      finishSpanWithError(span, e, data: data);
      transaction.finish(status: const SpanStatus.internalError());
      rethrow;
    }
  }
}

/// Performance monitoring mixin for easy integration
mixin PerformanceMixin {
  /// Measure an async operation
  Future<T> measureOperation<T>(
    String operation,
    Future<T> Function() function, {
    Map<String, dynamic>? data,
  }) {
    return PerformanceMonitor.measure(
      '${runtimeType.toString().toLowerCase()}.$operation',
      operation,
      function,
      data: data,
    );
  }
  
  /// Measure a sync operation
  T measureSyncOperation<T>(
    String operation,
    T Function() function, {
    Map<String, dynamic>? data,
  }) {
    return PerformanceMonitor.measureSync(
      '${runtimeType.toString().toLowerCase()}.$operation',
      operation,
      function,
      data: data,
    );
  }
}
