import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';

/// Google Authentication Service
/// Handles USER authentication for Google services (Tasks, Calendar, Gmail)
/// This is for the USER's personal Google account, not system APIs
class GoogleAuthService {
  static const _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'user_google_access_token';
  static const String _refreshTokenKey = 'user_google_refresh_token';
  static const String _tokenExpiryKey = 'user_google_token_expiry';
  static const String _userIdKey = 'user_google_id';
  static const String _userEmailKey = 'user_google_email';
  static const String _userNameKey = 'user_google_name';

  // Google API scopes for USER's personal data
  // Request basic scopes first, then add service-specific scopes
  static const List<String> _basicScopes = [
    'https://www.googleapis.com/auth/userinfo.profile',  // Basic profile info
    'https://www.googleapis.com/auth/userinfo.email',    // Email access
  ];
  
  // Service-specific scopes
  static const Map<String, String> _serviceScopes = {
    'tasks': tasks.TasksApi.tasksScope,
    'calendar': calendar.CalendarApi.calendarScope,
    'gmail': 'https://www.googleapis.com/auth/gmail.readonly',
  };
  
  // Track which services are connected
  Set<String> _connectedServices = {};

  GoogleSignIn? _googleSignIn;
  AuthClient? _authClient;
  String? _userId;
  String? _userEmail;
  String? _userName;

  /// Get the current authenticated client
  AuthClient? get authClient => _authClient;

  /// Get the current user ID
  String? get userId => _userId;

  /// Get the current user email
  String? get userEmail => _userEmail;

  /// Get the current user name
  String? get userName => _userName;

  /// Check if user is authenticated
  bool get isAuthenticated => _authClient != null;
  
  /// Get list of connected services
  Set<String> get connectedServices => Set.from(_connectedServices);
  
  /// Check if a specific service is connected
  bool isServiceConnected(String service) => _connectedServices.contains(service);
  
  /// Get available services
  List<String> get availableServices => _serviceScopes.keys.toList();
  
  /// Connect to additional Google services
  Future<bool> connectToService(String service) async {
    if (!_serviceScopes.containsKey(service)) {
      print('🔵 DEBUG: Unknown service: $service');
      return false;
    }
    
    if (_connectedServices.contains(service)) {
      print('🔵 DEBUG: Service $service already connected');
      return true;
    }
    
    try {
      print('🔵 DEBUG: Connecting to service: $service');
      
      // Create new GoogleSignIn instance with additional scope
      final additionalScopes = [..._basicScopes, _serviceScopes[service]!];
      final serviceGoogleSignIn = GoogleSignIn(scopes: additionalScopes);
      
      // Sign in with additional scope
      final GoogleSignInAccount? googleUser = await serviceGoogleSignIn.signIn();
      if (googleUser == null) {
        print('🔵 DEBUG: User cancelled service connection: $service');
        return false;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null) {
        print('🔵 DEBUG: No access token for service: $service');
        return false;
      }
      
      // Update auth client with new scopes
      _authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null,
          additionalScopes,
        ),
      );
      
      // Add service to connected services
      _connectedServices.add(service);
      
      // Store updated tokens
      await _storeTokens(
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null,
          additionalScopes,
        ),
        googleUser.id,
        googleUser.email,
        googleUser.displayName ?? '',
      );
      
      print('🔵 DEBUG: Successfully connected to service: $service');
      return true;
    } catch (e, stackTrace) {
      print('🔵 DEBUG: Failed to connect to service $service: $e');
      Logger.error('Failed to connect to service $service',
        tag: 'GOOGLE_AUTH',
        error: e,
        stackTrace: stackTrace
      );
      return false;
    }
  }

  GoogleAuthService() {
    // Lazy initialization - GoogleSignIn will be created only when needed
    _googleSignIn = null;
    
    // Run background reconnection if tokens exist (non-blocking)
    _initializeFromStoredTokensAsync();
  }
  
  /// Initialize GoogleSignIn only when needed
  void _ensureGoogleSignInInitialized() {
    if (_googleSignIn == null) {
      _googleSignIn = GoogleSignIn(
        scopes: _basicScopes,
        // No clientId needed - users authenticate with their own accounts
        // This allows users to sign in with their personal Google accounts
      );
      
      // Check if user is already signed in
      _googleSignIn!.isSignedIn().then((isSignedIn) {
        if (isSignedIn) {
          print('🔵 DEBUG: User already signed in to Google');
          _googleSignIn!.signInSilently().then((account) {
            if (account != null) {
              print('🔵 DEBUG: Silently signed in as: ${account.email}');
              _userEmail = account.email;
              _userName = account.displayName;
              _userId = account.id;
            }
          });
        }
      });
    }
  }
  
  /// Background reconnection (non-blocking)
  Future<void> _initializeFromStoredTokensAsync() async {
    try {
      // Check if we have stored tokens
      final accessToken = await _storage.read(key: _accessTokenKey);
      if (accessToken != null) {
        Logger.info('Found stored Google tokens, attempting background reconnection', tag: 'GOOGLE_AUTH');
        await initializeFromStoredTokens();
      }
    } catch (e) {
      Logger.warning('Background Google token reconnection failed: $e', tag: 'GOOGLE_AUTH');
      // Don't throw - this is background operation
    }
  }

  /// Initialize authentication from stored tokens
  Future<bool> initializeFromStoredTokens() async {
    try {
      Logger.info('Initializing Google auth from stored tokens', tag: 'GOOGLE_AUTH');
      
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      _userId = await _storage.read(key: _userIdKey);
      _userEmail = await _storage.read(key: _userEmailKey);

      if (accessToken == null || refreshToken == null || expiryString == null) {
        Logger.info('No stored tokens found', tag: 'GOOGLE_AUTH');
        return false;
      }

      final expiry = DateTime.parse(expiryString);
      if (expiry.isBefore(DateTime.now())) {
        Logger.info('Stored tokens expired, need refresh', tag: 'GOOGLE_AUTH');
        return await _refreshTokens(refreshToken);
      }

      // Create auth client with stored tokens
      _authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken('Bearer', accessToken, expiry),
          refreshToken,
          _basicScopes,
        ),
      );

      Logger.info('Successfully initialized from stored tokens', tag: 'GOOGLE_AUTH');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize from stored tokens', 
        tag: 'GOOGLE_AUTH', 
        error: e, 
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Authenticate with Google OAuth2 (USER's personal account)
  Future<bool> authenticate() async {
    print('🔵 DEBUG: GoogleAuthService.authenticate() called!');
    try {
      Logger.info('🚀 Starting Google OAuth2 authentication for USER', tag: 'GOOGLE_AUTH');
      
      // Initialize GoogleSignIn only when user tries to authenticate
      Logger.info('🔧 Initializing GoogleSignIn...', tag: 'GOOGLE_AUTH');
      _ensureGoogleSignInInitialized();
      Logger.info('✅ GoogleSignIn initialized', tag: 'GOOGLE_AUTH');
      
      // Sign in with Google
      Logger.info('📱 Calling GoogleSignIn.signIn()...', tag: 'GOOGLE_AUTH');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        Logger.info('❌ User cancelled Google sign-in', tag: 'GOOGLE_AUTH');
        return false;
      }

      Logger.info('✅ Google sign-in successful for user: ${googleUser.email}', tag: 'GOOGLE_AUTH');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        Logger.error('No access token received from Google', tag: 'GOOGLE_AUTH');
        return false;
      }

      // Create authenticated client
      _authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null, // Google Sign-In handles refresh internally
          _basicScopes,
        ),
      );

      // Store user information
      _userId = googleUser.id;
      _userEmail = googleUser.email;
      _userName = googleUser.displayName;

      // Store tokens securely
      await _storeTokens(
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null, // Google Sign-In handles refresh internally
          _basicScopes,
        ),
        googleUser.id,
        googleUser.email,
        googleUser.displayName ?? '',
      );

      Logger.info('Successfully authenticated USER: ${googleUser.email}', tag: 'GOOGLE_AUTH');
      return true;
    } catch (e, stackTrace) {
      print('🔵 DEBUG: GoogleAuthService.authenticate() crashed: $e');
      print('🔵 DEBUG: Stack trace: $stackTrace');
      Logger.error('GoogleAuthService.authenticate() crashed',
        tag: 'GOOGLE_AUTH',
        error: e,
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Refresh access tokens
  Future<bool> _refreshTokens(String refreshToken) async {
    try {
      Logger.info('Refreshing Google access tokens', tag: 'GOOGLE_AUTH');
      
      // Use Google Sign-In to refresh tokens
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signInSilently();
      if (googleUser == null) {
        Logger.warning('Silent sign-in failed, user needs to re-authenticate', tag: 'GOOGLE_AUTH');
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null) {
        Logger.error('No access token received during refresh', tag: 'GOOGLE_AUTH');
        return false;
      }

      // Update auth client with new tokens
      _authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null, // Google Sign-In handles refresh internally
          _basicScopes,
        ),
      );

      // Store new tokens
      await _storeTokens(
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null, // Google Sign-In handles refresh internally
          _basicScopes,
        ),
        googleUser.id,
        googleUser.email,
        googleUser.displayName ?? '',
      );

      Logger.info('Successfully refreshed tokens', tag: 'GOOGLE_AUTH');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Token refresh failed', 
        tag: 'GOOGLE_AUTH', 
        error: e, 
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Store authentication tokens
  Future<void> _storeTokens(AccessCredentials credentials, String userId, String userEmail, String userName) async {
    try {
      await _storage.write(key: _accessTokenKey, value: credentials.accessToken.data);
      if (credentials.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: credentials.refreshToken!);
      }
      await _storage.write(key: _tokenExpiryKey, value: credentials.accessToken.expiry.toIso8601String());
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _userEmailKey, value: userEmail);
      await _storage.write(key: _userNameKey, value: userName);
      
      _userId = userId;
      _userEmail = userEmail;
      _userName = userName;
      
      Logger.info('Stored USER authentication tokens for: $userEmail', tag: 'GOOGLE_AUTH');
    } catch (e, stackTrace) {
      Logger.error('Failed to store USER tokens', 
        tag: 'GOOGLE_AUTH', 
        error: e, 
        stackTrace: stackTrace
      );
    }
  }

  /// Sign out and clear stored tokens
  Future<void> signOut() async {
    try {
      Logger.info('Signing out USER from Google', tag: 'GOOGLE_AUTH');
      
      // Sign out from Google Sign-In
      await _googleSignIn?.signOut();
      
      // Clear stored tokens
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userEmailKey);
      await _storage.delete(key: _userNameKey);
      
      // Clear client and user data
      _authClient?.close();
      _authClient = null;
      _userId = null;
      _userEmail = null;
      _userName = null;
      
      Logger.info('Successfully signed out USER', tag: 'GOOGLE_AUTH');
    } catch (e, stackTrace) {
      Logger.error('USER sign out failed', 
        tag: 'GOOGLE_AUTH', 
        error: e, 
        stackTrace: stackTrace
      );
    }
  }

  /// Check if tokens need refresh and refresh if necessary
  Future<bool> ensureValidTokens() async {
    try {
      if (!isAuthenticated) {
        Logger.info('Not authenticated, skipping token validation', tag: 'GOOGLE_AUTH');
        return false;
      }

      // Initialize GoogleSignIn if needed
      _ensureGoogleSignInInitialized();
      
      // Check if we have a refresh token
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        Logger.warning('No refresh token available', tag: 'GOOGLE_AUTH');
        return false;
      }

      // Try to refresh tokens
      final success = await _refreshTokens(refreshToken);
      if (success) {
        Logger.info('Tokens refreshed successfully', tag: 'GOOGLE_AUTH');
        return true;
      } else {
        Logger.warning('Token refresh failed, user needs to re-authenticate', tag: 'GOOGLE_AUTH');
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('Error ensuring valid tokens', 
        tag: 'GOOGLE_AUTH', 
        error: e, 
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Get required scopes for Google services
  static List<String> get requiredScopes => List.from(_basicScopes);
}

/// Provider for Google Auth Service
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// Provider for authentication status
final isGoogleAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.read(googleAuthServiceProvider);
  return await authService.initializeFromStoredTokens();
});
