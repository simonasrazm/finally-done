import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Comprehensive Sentry Performance monitoring utility
///
/// This utility provides consistent transaction and span management
/// for tracking app performance across all critical operations.
class SentryPerformance {
  factory SentryPerformance() => _instance;
  SentryPerformance._internal();
  static final SentryPerformance _instance = SentryPerformance._internal();

  final Map<String, dynamic> _activeSpans = {};
  final Map<String, dynamic> _activeTransactions = {};

  /// Start a new transaction
  dynamic startTransaction(String name, String operation) {
    final transaction = Sentry.startTransaction(name, operation);
    _activeTransactions[name] = transaction;

    return transaction;
  }

  /// Start a span within an active transaction
  dynamic startSpan(String transactionName, String spanName, String operation) {
    final transaction = _activeTransactions[transactionName];
    if (transaction == null) {
      return null;
    }

    final span = transaction.startChild(spanName, description: operation);
    _activeSpans[spanName] = span;

    return span;
  }

  /// Finish a span
  void finishSpan(String spanName, {Map<String, dynamic>? data}) {
    final span = _activeSpans.remove(spanName);
    if (span != null) {
      if (data != null) {
        span.setData('data', data);
      }
      span.finish();
    }
  }

  /// Finish a transaction
  void finishTransaction(String transactionName, {Map<String, dynamic>? data}) {
    final transaction = _activeTransactions.remove(transactionName);
    if (transaction != null) {
      if (data != null) {
        transaction.setData('data', data);
      }
      transaction.finish();
    }
  }

  /// Monitor an async operation with automatic span management
  Future<T> monitorOperation<T>(
    String transactionName,
    String spanName,
    String operation,
    Future<T> Function() operationFunc, {
    Map<String, dynamic>? data,
  }) async {
    final span = startSpan(transactionName, spanName, operation);

    try {
      final result = await operationFunc();
      finishSpan(spanName, data: data);
      return result;
    } catch (e) {
      if (span != null) {
        span.setData('error', e.toString());
      }
      finishSpan(spanName, data: data);
      rethrow;
    }
  }

  /// Monitor a sync operation with automatic span management
  T monitorSyncOperation<T>(
    String transactionName,
    String spanName,
    String operation,
    T Function() operationFunc, {
    Map<String, dynamic>? data,
  }) {
    final span = startSpan(transactionName, spanName, operation);

    try {
      final result = operationFunc();
      finishSpan(spanName, data: data);
      return result;
    } catch (e) {
      if (span != null) {
        span.setData('error', e.toString());
      }
      finishSpan(spanName, data: data);
      rethrow;
    }
  }

  /// Monitor a complete transaction with automatic management
  Future<T> monitorTransaction<T>(
    String transactionName,
    String operation,
    Future<T> Function() transactionFunc, {
    Map<String, dynamic>? data,
  }) async {
    final transaction = startTransaction(transactionName, operation);

    try {
      final result = await transactionFunc();
      finishTransaction(transactionName, data: data);
      return result;
    } catch (e) {
      if (transaction != null) {
        transaction.setData('error', e.toString());
      }
      finishTransaction(transactionName, data: data);
      rethrow;
    }
  }

  /// Add breadcrumb for debugging
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    // ignore: discarded_futures
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      data: data,
      level: SentryLevel.info,
    ));
  }

  /// Get active transactions and spans for debugging
  Map<String, dynamic> getActiveOperations() {
    return {
      'active_transactions': _activeTransactions.keys.toList(),
      'active_spans': _activeSpans.keys.toList(),
    };
  }

  /// Clear all active operations (for testing)
  void clear() {
    for (final transaction in _activeTransactions.values) {
      if (transaction != null) {
        transaction.finish();
      }
    }
    for (final span in _activeSpans.values) {
      if (span != null) {
        span.finish();
      }
    }
    _activeTransactions.clear();
    _activeSpans.clear();
  }
}

/// Global instance for easy access
final sentryPerformance = SentryPerformance();

/// Performance operation types for consistent naming
class PerformanceOps {
  // Screen operations
  static const String screenLoad = 'screen.load';
  static const String screenNavigation = 'screen.navigation';

  // Authentication operations
  static const String authSignIn = 'auth.signin';
  static const String authTokenRefresh = 'auth.token_refresh';
  static const String authCheck = 'auth.check';

  // API operations
  static const String apiCall = 'api.call';
  static const String apiRequest = 'api.request';
  static const String apiResponse = 'api.response';

  // Provider operations
  static const String providerInit = 'provider.init';
  static const String providerUpdate = 'provider.update';

  // Background operations
  static const String backgroundPoll = 'background.poll';
  static const String backgroundSync = 'background.sync';

  // UI operations
  static const String uiRender = 'ui.render';
  static const String uiUpdate = 'ui.update';
}

/// Performance transaction names for consistent naming
class PerformanceTransactions {
  // Screen transactions
  static const String screenHome = 'screen.home';
  static const String screenTasks = 'screen.tasks';
  static const String screenSettings = 'screen.settings';
  static const String screenMissionControl = 'screen.mission_control';
  static const String screenIntegrations = 'screen.integrations';

  // Authentication transactions
  static const String authGoogleSignIn = 'auth.google.signin';
  static const String authGoogleTokenRefresh = 'auth.google.token_refresh';

  // API transactions
  static const String apiTasksFetch = 'api.tasks.fetch';
  static const String apiTasksCreate = 'api.tasks.create';
  static const String apiTasksComplete = 'api.tasks.complete';
  static const String apiTasksDelete = 'api.tasks.delete';
  static const String apiTaskListsFetch = 'api.task_lists.fetch';

  // Provider transactions
  static const String providerIntegrationManagerInit =
      'provider.integration_manager.init';
  static const String providerTasksProviderInit =
      'provider.tasks_provider.init';
  static const String providerGoogleIntegrationInit =
      'provider.google_integration.init';

  // Background transactions
  static const String backgroundTasksPoll = 'background.tasks.poll';
  static const String backgroundTasksSync = 'background.tasks.sync';
}
