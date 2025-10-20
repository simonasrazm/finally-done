import 'dart:async';
import 'package:googleapis_auth/auth_io.dart';
import '../infrastructure/network/network_service.dart';

/// Base class for all API connectors
/// Provides common functionality for network operations, authentication, and error handling
abstract class BaseConnector {
  final NetworkService _networkService = NetworkService();
  final String _connectorName;
  final NetworkConfig _networkConfig;
  
  AuthClient? _authClient;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  List<String> _scopes = [];

  BaseConnector({
    required String connectorName,
    NetworkConfig? networkConfig,
  }) : _connectorName = connectorName,
       _networkConfig = networkConfig ?? NetworkConfig.defaultConfig;

  /// Initialize the connector with authentication credentials
  Future<void> initialize({
    required String accessToken,
    required List<String> scopes,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = tokenExpiry;
    _scopes = scopes;
    
    await _createAuthClient();
  }

  /// Execute an API operation with automatic retry and error handling
  Future<T> executeOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    NetworkConfig? config,
  }) async {
    final effectiveConfig = config ?? _networkConfig;
    
    return _networkService.executeWithRetry(
      operation,
      operationName: operationName ?? '$_connectorName operation',
      maxRetries: effectiveConfig.maxRetries,
      baseDelay: effectiveConfig.baseDelay,
      maxDelay: effectiveConfig.maxDelay,
      isRetryableError: _isRetryableError,
    );
  }

  /// Execute an operation with authentication refresh handling
  Future<T> executeWithAuthRefresh<T>(
    Future<T> Function() operation, {
    String? operationName,
    NetworkConfig? config,
  }) async {
    return executeOperation(
      () async {
        try {
          return await operation();
        } catch (e) {
          // Check if this is an authentication error
          final refreshed = await _networkService.handleAuthenticationError(
            e,
            _refreshTokenCallback,
          );
          
          if (refreshed) {
            // Retry the operation with the new token
            return operation();
          }
          
          // If refresh failed, rethrow the original error
          rethrow;
        }
      },
      operationName: operationName,
      config: config,
    );
  }

  /// Get the current authenticated HTTP client
  AuthClient? get authClient => _authClient;

  /// Check if the connector is properly initialized
  bool get isInitialized => _authClient != null && _accessToken != null;

  /// Get the connector name
  String get connectorName => _connectorName;

  /// Create the authenticated HTTP client
  Future<void> _createAuthClient() async {
    if (_accessToken == null) {
      throw ConnectorException('Access token is required to create auth client');
    }

    _authClient = await _networkService.createAuthenticatedClient(
      accessToken: _accessToken!,
      scopes: _scopes,
      refreshToken: _refreshToken,
      tokenExpiry: _tokenExpiry,
      connectionTimeout: _networkConfig.connectionTimeout,
      receiveTimeout: _networkConfig.receiveTimeout,
    );
  }

  /// Callback for token refresh - to be implemented by subclasses
  Future<String?> _refreshTokenCallback() async {
    // This should be implemented by subclasses to handle token refresh
    // For now, return null to indicate refresh is not supported
    return null;
  }

  /// Check if an error is retryable for this connector
  bool _isRetryableError(dynamic error) {
    // Use the network service's default retry logic
    // Subclasses can override this for connector-specific logic
    return true; // Let NetworkService handle the retry logic
  }

  /// Update authentication credentials
  Future<void> updateCredentials({
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
    List<String>? scopes,
  }) async {
    if (accessToken != null) _accessToken = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (tokenExpiry != null) _tokenExpiry = tokenExpiry;
    if (scopes != null) _scopes = scopes;
    
    if (_accessToken != null) {
      await _createAuthClient();
    }
  }

  /// Dispose of resources
  void dispose() {
    _authClient = null;
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _scopes.clear();
  }
}

/// Exception for connector-related errors
class ConnectorException implements Exception {
  final String message;
  final dynamic originalError;
  
  ConnectorException(this.message, [this.originalError]);
  
  @override
  String toString() => 'ConnectorException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}
