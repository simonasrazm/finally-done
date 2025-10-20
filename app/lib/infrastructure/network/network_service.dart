import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../../design_system/tokens.dart';

/// Centralized network service for handling common connectivity challenges
/// Provides retry logic, authentication refresh, and error handling for all connectors
class NetworkService {
  factory NetworkService() => _instance;
  NetworkService._internal();
  static final NetworkService _instance = NetworkService._internal();

  /// Default retry configuration
  static const int defaultMaxRetries = 3;
  static const Duration defaultBaseDelay =
      Duration(milliseconds: DesignTokens.delayMedium);
  static const Duration defaultMaxDelay = Duration(seconds: 10);

  /// Execute an operation with retry logic and error handling
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? isRetryableError,
  }) async {
    int retryCount = 0;
    final String operationLabel = operationName ?? 'network operation';

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        // Check if this is a retryable error
        final shouldRetry = (isRetryableError ?? _isRetryableError)(e) &&
            retryCount < maxRetries;

        if (shouldRetry) {
          final delay = _calculateBackoffDelay(retryCount, baseDelay, maxDelay);
          await Future.delayed(delay);
          continue;
        }

        // Log the final error and rethrow
        rethrow;
      }
    }

    throw NetworkException('Max retries exceeded for $operationLabel');
  }

  /// Create a robust HTTP client with proper configuration
  http.Client createHttpClient({
    Duration? connectionTimeout,
    Duration? receiveTimeout,
  }) {
    return http.Client();
  }

  /// Create an authenticated HTTP client with automatic token refresh
  Future<AuthClient> createAuthenticatedClient({
    required String accessToken,
    required List<String> scopes,
    String? refreshToken,
    DateTime? tokenExpiry,
    Duration? connectionTimeout,
    Duration? receiveTimeout,
  }) async {
    final httpClient = createHttpClient(
      connectionTimeout: connectionTimeout,
      receiveTimeout: receiveTimeout,
    );

    final credentials = AccessCredentials(
      AccessToken('Bearer', accessToken,
          tokenExpiry ?? DateTime.now().toUtc().add(const Duration(hours: 1))),
      refreshToken,
      scopes,
    );

    return authenticatedClient(httpClient, credentials);
  }

  /// Check if an error is retryable
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network-related errors that should be retried
    return errorString.contains('oserror') ||
        errorString.contains('handshakeexception') ||
        errorString.contains('socketexception') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('bad file descriptor') ||
        errorString.contains('connection terminated') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection refused') ||
        errorString.contains('host unreachable') ||
        errorString.contains('network unreachable');
  }

  /// Calculate exponential backoff delay with jitter
  Duration _calculateBackoffDelay(
      int retryCount, Duration baseDelay, Duration maxDelay) {
    // Exponential backoff: baseDelay * 2^(retryCount-1)
    final exponentialDelay = baseDelay * (1 << (retryCount - 1));

    // Add jitter to prevent thundering herd (random factor between 0.5 and 1.5)
    final jitter =
        0.5 + (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
    final delayWithJitter = exponentialDelay * jitter;

    // Cap at maxDelay
    return delayWithJitter > maxDelay ? maxDelay : delayWithJitter;
  }

  /// Handle authentication errors and attempt refresh
  Future<bool> handleAuthenticationError(
    dynamic error,
    Future<String?> Function() refreshTokenCallback,
  ) async {
    if (_isAuthenticationError(error)) {
      try {
        final newToken = await refreshTokenCallback();
        return newToken != null;
      } on Exception {
        return false;
      }
    }
    return false;
  }

  /// Check if an error is authentication-related
  bool _isAuthenticationError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('invalid_token') ||
        errorString.contains('authentication expired') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('token expired') ||
        errorString.contains('invalid_grant');
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  NetworkException(this.message, [this.originalError]);
  final String message;
  final dynamic originalError;

  @override
  String toString() =>
      'NetworkException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}

/// Configuration for network operations
class NetworkConfig {
  const NetworkConfig({
    this.maxRetries = NetworkService.defaultMaxRetries,
    this.baseDelay = NetworkService.defaultBaseDelay,
    this.maxDelay = NetworkService.defaultMaxDelay,
    this.connectionTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 60),
  });
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final Duration connectionTimeout;
  final Duration receiveTimeout;

  /// Default configuration for most operations
  static const NetworkConfig defaultConfig = NetworkConfig();

  /// Configuration for critical operations (more retries)
  static const NetworkConfig criticalConfig = NetworkConfig(
    maxRetries: 5,
    baseDelay: Duration(milliseconds: DesignTokens.delayShort),
    maxDelay: Duration(seconds: 15),
  );

  /// Configuration for quick operations (fewer retries)
  static const NetworkConfig quickConfig = NetworkConfig(
    maxRetries: 2,
    baseDelay: Duration(milliseconds: DesignTokens.delayShort),
    maxDelay: Duration(seconds: 5),
  );
}
