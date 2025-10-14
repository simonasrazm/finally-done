import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/services.dart';
import '../../utils/logger.dart';
import '../../utils/performance_monitor.dart';
import 'integration_provider.dart';

/// Google-specific integration provider
class GoogleIntegrationProvider extends IntegrationProvider {
  static const _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'google_access_token';
  static const String _refreshTokenKey = 'google_refresh_token';
  static const String _tokenExpiryKey = 'google_token_expiry';
  static const String _userIdKey = 'google_user_id';
  static const String _userEmailKey = 'google_user_email';
  static const String _userNameKey = 'google_user_name';
  static const String _connectedServicesKey = 'google_connected_services';

  GoogleSignIn? _googleSignIn;
  AuthClient? _authClient;

  GoogleIntegrationProvider() : super(
    id: 'google',
    displayName: 'Google',
    icon: 'google', // Icon identifier
    description: 'Connect to Google services like Tasks, Calendar, and Gmail',
  ) {
    // Defer initialization to avoid blocking UI during construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromStoredTokensAsync();
    });
  }

  /// Initialize from stored tokens asynchronously
  Future<void> _initializeFromStoredTokensAsync() async {
    print('🔵 GOOGLE INTEGRATION: _initializeFromStoredTokensAsync called');
    Logger.info('GoogleIntegrationProvider: _initializeFromStoredTokensAsync called', tag: 'GOOGLE_INTEGRATION');
    // Add a small delay to spread out initialization work
    await Future.delayed(Duration(milliseconds: 100));
    await _initializeFromStoredTokens();
  }

  @override
  List<IntegrationService> get availableServices => [
    const IntegrationService(
      id: 'tasks',
      name: 'Google Tasks',
      description: 'Manage your tasks and to-do lists',
      icon: 'tasks',
      scope: tasks.TasksApi.tasksScope,
    ),
    const IntegrationService(
      id: 'calendar',
      name: 'Google Calendar',
      description: 'Access your calendar events',
      icon: 'calendar',
      scope: calendar.CalendarApi.calendarScope,
    ),
    const IntegrationService(
      id: 'gmail',
      name: 'Gmail',
      description: 'Read your email messages',
      icon: 'gmail',
      scope: 'https://www.googleapis.com/auth/gmail.readonly',
    ),
  ];

  @override
  Future<bool> authenticate() async {
    try {
      Logger.info('🚀 Starting Google authentication', tag: 'GOOGLE_INTEGRATION');
      
      state = state.copyWith(isConnecting: true);
      
      _ensureGoogleSignInInitialized();
      
      // Check if already signed in
      final isAlreadySignedIn = await _googleSignIn!.isSignedIn();
      if (isAlreadySignedIn) {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signInSilently();
        if (googleUser != null) {
          await _setupUserSession(googleUser);
          return true;
        }
      }

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        state = state.copyWith(isConnecting: false);
        return false;
      }

      await _setupUserSession(googleUser);
      return true;
    } catch (e, stackTrace) {
      Logger.error('Google authentication failed', tag: 'GOOGLE_INTEGRATION', error: e, stackTrace: stackTrace);
      state = state.copyWith(isConnecting: false);
      return false;
    }
  }

  @override
  Future<bool> connectServices(List<String> serviceIds) async {
    if (!state.isAuthenticated) {
      Logger.warning('Cannot connect services without authentication', tag: 'GOOGLE_INTEGRATION');
      return false;
    }

    try {
      state = state.copyWith(isSyncing: true);

      // Get scopes for requested services
      final requestedScopes = <String>[
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
      ];

      for (final serviceId in serviceIds) {
        final service = availableServices.firstWhere(
          (s) => s.id == serviceId,
          orElse: () => throw Exception('Unknown service: $serviceId'),
        );
        if (service.scope != null) {
          requestedScopes.add(service.scope!);
        }
      }

      // Create new GoogleSignIn instance with additional scopes
      final serviceGoogleSignIn = GoogleSignIn(scopes: requestedScopes);
      final GoogleSignInAccount? googleUser = await serviceGoogleSignIn.signIn();
      
      if (googleUser == null) {
        state = state.copyWith(isSyncing: false);
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null) {
        state = state.copyWith(isSyncing: false);
        return false;
      }

      // Update auth client with new scopes - use a custom HTTP client with better error handling
      _authClient = authenticatedClient(
        _createHttpClient(),
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().toUtc().add(Duration(hours: 1))),
          null,
          requestedScopes,
        ),
      );

      // Update connected services
      final updatedServices = Map<String, IntegrationService>.from(state.services);
      for (final serviceId in serviceIds) {
        final service = updatedServices[serviceId];
        if (service != null) {
          updatedServices[serviceId] = service.copyWith(isConnected: true);
        }
      }

      // Store tokens and connected services
      await _storeTokens(googleAuth.accessToken!, requestedScopes);
      await _storeConnectedServices(serviceIds);

      state = state.copyWith(
        services: updatedServices,
        isSyncing: false,
        lastSyncTime: DateTime.now().toIso8601String(),
      );

      Logger.info('Successfully connected services: $serviceIds', tag: 'GOOGLE_INTEGRATION');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Failed to connect services', tag: 'GOOGLE_INTEGRATION', error: e, stackTrace: stackTrace);
      state = state.copyWith(isSyncing: false);
      return false;
    }
  }

  @override
  Future<bool> disconnectServices(List<String> serviceIds) async {
    try {
      state = state.copyWith(isLoading: true);

      // Update services to disconnected
      final updatedServices = Map<String, IntegrationService>.from(state.services);
      for (final serviceId in serviceIds) {
        final service = updatedServices[serviceId];
        if (service != null) {
          updatedServices[serviceId] = service.copyWith(isConnected: false);
        }
      }

      // Update stored connected services
      final currentConnected = await _getStoredConnectedServices();
      final newConnected = currentConnected.where((id) => !serviceIds.contains(id)).toList();
      await _storeConnectedServices(newConnected);

      state = state.copyWith(
        services: updatedServices,
        isLoading: false,
      );

      Logger.info('Successfully disconnected services: $serviceIds', tag: 'GOOGLE_INTEGRATION');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Failed to disconnect services', tag: 'GOOGLE_INTEGRATION', error: e, stackTrace: stackTrace);
      state = state.copyWith(isSyncing: false);
      return false;
    }
  }

  @override
  Future<bool> toggleService(String serviceId) async {
    final isConnected = state.isServiceConnected(serviceId);
    if (isConnected) {
      return await disconnectServices([serviceId]);
    } else {
      return await connectServices([serviceId]);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      Logger.info('Signing out from Google', tag: 'GOOGLE_INTEGRATION');
      
      // Sign out from Google Sign-In
      await _googleSignIn?.signOut();
      
      // Clear stored data
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userEmailKey);
      await _storage.delete(key: _userNameKey);
      await _storage.delete(key: _connectedServicesKey);
      
      // Clear client and reset state
      _authClient?.close();
      _authClient = null;
      
      // Reset services to disconnected
      final updatedServices = <String, IntegrationService>{};
      for (final service in availableServices) {
        updatedServices[service.id] = service.copyWith(isConnected: false);
      }
      
      state = IntegrationProviderState(
        services: updatedServices,
      );
      
      Logger.info('Successfully signed out from Google', tag: 'GOOGLE_INTEGRATION');
    } catch (e, stackTrace) {
      Logger.error('Google sign out failed', tag: 'GOOGLE_INTEGRATION', error: e, stackTrace: stackTrace);
    }
  }

  /// Get the authenticated client for API calls
  AuthClient? get authClient => _authClient;

  /// Ensure valid authentication before API calls
  Future<bool> ensureValidAuthentication() async {
    if (!state.isAuthenticated) {
      Logger.warning('GoogleIntegrationProvider: Not authenticated', tag: 'GOOGLE_INTEGRATION');
      return false;
    }

    // Check if token is expired
    final tokenExpiryStr = await _storage.read(key: _tokenExpiryKey);
    if (tokenExpiryStr != null) {
      try {
        final tokenExpiry = DateTime.parse(tokenExpiryStr);
        if (tokenExpiry.isBefore(DateTime.now().toUtc())) {
          Logger.info('GoogleIntegrationProvider: Token expired, refreshing...', tag: 'GOOGLE_INTEGRATION');
          final refreshed = await _refreshTokensSilently();
          if (!refreshed) {
            Logger.warning('GoogleIntegrationProvider: Failed to refresh expired token', tag: 'GOOGLE_INTEGRATION');
            return false;
          }
        }
      } catch (e) {
        Logger.warning('GoogleIntegrationProvider: Failed to parse token expiry, attempting refresh', tag: 'GOOGLE_INTEGRATION');
        final refreshed = await _refreshTokensSilently();
        if (!refreshed) {
          Logger.warning('GoogleIntegrationProvider: Failed to refresh token after parse error', tag: 'GOOGLE_INTEGRATION');
          return false;
        }
      }
    }

    return _authClient != null;
  }

  /// Get current scopes based on connected services
  List<String> _getCurrentScopes() {
    final scopes = <String>[
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/userinfo.email',
    ];
    
    final connectedServices = state.services.values
        .where((service) => service.isConnected)
        .map((service) => service.scope)
        .where((scope) => scope != null)
        .cast<String>();
    
    scopes.addAll(connectedServices);
    return scopes;
  }

  /// Initialize from stored tokens
  Future<void> _initializeFromStoredTokens() async {
    print('🔵 GOOGLE INTEGRATION: _initializeFromStoredTokens called');
    Logger.info('GoogleIntegrationProvider: _initializeFromStoredTokens called', tag: 'GOOGLE_INTEGRATION');
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final userEmail = await _storage.read(key: _userEmailKey);
      final userName = await _storage.read(key: _userNameKey);
      final userId = await _storage.read(key: _userIdKey);
      final connectedServices = await _getStoredConnectedServices();
      
      Logger.info('GoogleIntegrationProvider: Stored data check - accessToken: ${accessToken != null ? "EXISTS" : "NULL"}, userEmail: ${userEmail ?? "NULL"}', tag: 'GOOGLE_INTEGRATION');
      Logger.info('GoogleIntegrationProvider: Connected services from storage: $connectedServices', tag: 'GOOGLE_INTEGRATION');
      
      if (accessToken != null && userEmail != null) {
        Logger.info('GoogleIntegrationProvider: Found valid stored tokens, setting up authentication', tag: 'GOOGLE_INTEGRATION');
        
        // Check if token is expired
        final tokenExpiryStr = await _storage.read(key: _tokenExpiryKey);
        DateTime? tokenExpiry;
        if (tokenExpiryStr != null) {
          try {
            tokenExpiry = DateTime.parse(tokenExpiryStr);
          } catch (e) {
            Logger.warning('Failed to parse token expiry: $e', tag: 'GOOGLE_INTEGRATION');
          }
        }
        
        // If token is expired or no expiry info, try to refresh
        if (tokenExpiry == null || tokenExpiry.isBefore(DateTime.now().toUtc())) {
          Logger.info('GoogleIntegrationProvider: Token expired, attempting to refresh...', tag: 'GOOGLE_INTEGRATION');
          final refreshed = await _refreshTokensSilently();
          if (!refreshed) {
            Logger.warning('GoogleIntegrationProvider: Failed to refresh tokens, clearing stored data', tag: 'GOOGLE_INTEGRATION');
            await _clearStoredData();
            return;
          }
        }
        
        // Set up services based on stored data first
        final updatedServices = <String, IntegrationService>{};
        for (final service in availableServices) {
          updatedServices[service.id] = service.copyWith(
            isConnected: connectedServices.contains(service.id),
          );
        }
        
        // Get fresh token after potential refresh
        final freshAccessToken = await _storage.read(key: _accessTokenKey);
        if (freshAccessToken == null) {
          Logger.warning('GoogleIntegrationProvider: No access token after refresh', tag: 'GOOGLE_INTEGRATION');
          return;
        }
        
        // Set up auth client with correct scopes
        _authClient = authenticatedClient(
          http.Client(),
          AccessCredentials(
            AccessToken('Bearer', freshAccessToken, DateTime.now().toUtc().add(Duration(hours: 1))),
            null,
            _getCurrentScopes(),
          ),
        );
        
        state = state.copyWith(
          isAuthenticated: true,
          userEmail: userEmail,
          userName: userName,
          userId: userId,
          services: updatedServices,
          lastSyncTime: DateTime.now().toIso8601String(),
        );
        
        
        print('🔵 GOOGLE INTEGRATION: Successfully initialized from stored tokens');
        print('🔵 GOOGLE INTEGRATION: Final state - isAuthenticated: ${state.isAuthenticated}, userEmail: ${state.userEmail}');
        print('🔵 GOOGLE INTEGRATION: Connected services: $connectedServices');
        print('🔵 GOOGLE INTEGRATION: Updated services: ${updatedServices.keys}');
        Logger.info('GoogleIntegrationProvider: Successfully initialized from stored tokens', tag: 'GOOGLE_INTEGRATION');
        Logger.info('GoogleIntegrationProvider: Final state - isAuthenticated: ${state.isAuthenticated}, userEmail: ${state.userEmail}', tag: 'GOOGLE_INTEGRATION');
        Logger.info('GoogleIntegrationProvider: Connected services: $connectedServices', tag: 'GOOGLE_INTEGRATION');
        Logger.info('GoogleIntegrationProvider: Updated services: ${updatedServices.keys}', tag: 'GOOGLE_INTEGRATION');
      } else {
        print('🔵 GOOGLE INTEGRATION: No valid stored tokens found - accessToken: ${accessToken != null}, userEmail: ${userEmail != null}');
        Logger.info('GoogleIntegrationProvider: No valid stored tokens found - accessToken: ${accessToken != null}, userEmail: ${userEmail != null}', tag: 'GOOGLE_INTEGRATION');
      }
    } catch (e) {
      Logger.warning('GoogleIntegrationProvider: Failed to initialize from stored tokens: $e', tag: 'GOOGLE_INTEGRATION');
    }
  }

  /// Set up user session after successful authentication
  Future<void> _setupUserSession(GoogleSignInAccount googleUser) async {
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    if (googleAuth.accessToken == null) {
      Logger.error('No access token received from Google', tag: 'GOOGLE_INTEGRATION');
      return;
    }

    // Create authenticated client
    _authClient = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().toUtc().add(Duration(hours: 1))),
        null,
        ['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email'],
      ),
    );

    // Set up services (initially none connected)
    final updatedServices = <String, IntegrationService>{};
    for (final service in availableServices) {
      updatedServices[service.id] = service.copyWith(isConnected: false);
    }

    // Store basic authentication
    await _storeTokens(googleAuth.accessToken!, ['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email']);
    await _storeUserInfo(googleUser.id, googleUser.email, googleUser.displayName ?? '');

    state = state.copyWith(
      isAuthenticated: true,
      userEmail: googleUser.email,
      userName: googleUser.displayName,
      userId: googleUser.id,
      services: updatedServices,
      isConnecting: false,
      lastSyncTime: DateTime.now().toIso8601String(),
    );

    Logger.info('Successfully set up Google user session', tag: 'GOOGLE_INTEGRATION');
  }

  /// Initialize GoogleSignIn
  void _ensureGoogleSignInInitialized() {
    if (_googleSignIn == null) {
      _googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email'],
      );
    }
  }

  /// Store authentication tokens
  Future<void> _storeTokens(String accessToken, List<String> scopes) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _tokenExpiryKey, value: DateTime.now().toUtc().add(Duration(hours: 1)).toIso8601String());
  }

  /// Store user information
  Future<void> _storeUserInfo(String userId, String userEmail, String userName) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userEmailKey, value: userEmail);
    await _storage.write(key: _userNameKey, value: userName);
  }

  /// Store connected services
  Future<void> _storeConnectedServices(List<String> serviceIds) async {
    await _storage.write(key: _connectedServicesKey, value: serviceIds.join(','));
  }

  /// Get stored connected services
  Future<List<String>> _getStoredConnectedServices() async {
    final stored = await _storage.read(key: _connectedServicesKey);
    return stored?.split(',') ?? [];
  }

  /// Refresh tokens silently using Google Sign-In
  Future<bool> _refreshTokensSilently() async {
    try {
      Logger.info('GoogleIntegrationProvider: Attempting to refresh tokens silently...', tag: 'GOOGLE_INTEGRATION');
      _ensureGoogleSignInInitialized();
      
      // Try to sign in silently to refresh tokens
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signInSilently();
      if (googleUser == null) {
        Logger.warning('GoogleIntegrationProvider: Silent sign-in failed - user is null', tag: 'GOOGLE_INTEGRATION');
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null) {
        Logger.warning('GoogleIntegrationProvider: No access token from silent sign-in', tag: 'GOOGLE_INTEGRATION');
        return false;
      }

      // Update the auth client with new token
      _authClient = authenticatedClient(
        _createHttpClient(),
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().toUtc().add(Duration(hours: 1))),
          null,
          _getCurrentScopes(),
        ),
      );

      // Store the new tokens
      await _storeTokens(googleAuth.accessToken!, _getCurrentScopes());
      
      Logger.info('GoogleIntegrationProvider: Successfully refreshed tokens and updated auth client', tag: 'GOOGLE_INTEGRATION');
      return true;
    } catch (e, stackTrace) {
      Logger.error('GoogleIntegrationProvider: Failed to refresh tokens silently', tag: 'GOOGLE_INTEGRATION', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clear all stored authentication data
  Future<void> _clearStoredData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _connectedServicesKey);
    
    _authClient?.close();
    _authClient = null;
    
    // Reset state
    final updatedServices = <String, IntegrationService>{};
    for (final service in availableServices) {
      updatedServices[service.id] = service.copyWith(isConnected: false);
    }
    
    state = IntegrationProviderState(
      services: updatedServices,
    );
  }

  /// Create a custom HTTP client with better error handling
  http.Client _createHttpClient() {
    return http.Client();
  }
}
