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
import '../utils/logger.dart';

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
  static const List<String> _scopes = [
    tasks.TasksApi.tasksScope,           // USER's tasks
    calendar.CalendarApi.calendarScope,  // USER's calendar
    gmail.GmailApi.gmailReadonlyScope,   // USER's email (read)
    gmail.GmailApi.gmailComposeScope,    // USER's email (compose)
  ];

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
        scopes: _scopes,
        // No clientId needed - users authenticate with their own accounts
      );
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
          _scopes,
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
    try {
      Logger.info('Starting Google OAuth2 authentication for USER', tag: 'GOOGLE_AUTH');
      
      // Initialize GoogleSignIn only when user tries to authenticate
      _ensureGoogleSignInInitialized();
      
      Logger.info('Calling GoogleSignIn.signIn()...', tag: 'GOOGLE_AUTH');
      
      // Sign in with Google (with timeout to prevent freezing)
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Logger.error('Google sign-in timed out after 30 seconds', tag: 'GOOGLE_AUTH');
          throw TimeoutException('Google sign-in timed out', const Duration(seconds: 30));
        },
      );
      if (googleUser == null) {
        Logger.info('User cancelled Google sign-in', tag: 'GOOGLE_AUTH');
        return false;
      }
      
      Logger.info('Google sign-in successful for user: ${googleUser.email}', tag: 'GOOGLE_AUTH');

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
          _scopes,
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
          _scopes,
        ),
        googleUser.id,
        googleUser.email,
        googleUser.displayName ?? '',
      );

      Logger.info('Successfully authenticated USER: ${googleUser.email}', tag: 'GOOGLE_AUTH');
      return true;
    } catch (e, stackTrace) {
      Logger.error('USER authentication failed', 
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
          _scopes,
        ),
      );

      // Store new tokens
      await _storeTokens(
        AccessCredentials(
          AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          null, // Google Sign-In handles refresh internally
          _scopes,
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
  static List<String> get requiredScopes => List.from(_scopes);
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
