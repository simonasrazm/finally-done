# Finally Done - Technical Architecture

This document provides a comprehensive overview of the technical architecture, design patterns, and implementation details of the Finally Done app.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Finally Done App                        │
├─────────────────────────────────────────────────────────────────┤
│  Flutter UI Layer (Dart)                                       │
│  ├── Screens (Home, Settings, Mission Control, Tasks)         │
│  ├── Widgets (Custom components, design system)               │
│  ├── Localization (Multi-language support)                    │
│  ├── Theme Management (Dynamic theming)                       │
│  └── State Management (Riverpod StateNotifier)                │
├─────────────────────────────────────────────────────────────────┤
│  Service Layer (Dart)                                          │
│  ├── Integration Manager (Multi-provider coordination)        │
│  ├── Connector Manager (Service lifecycle management)         │
│  ├── Network Service (Retry logic, auth refresh)              │
│  ├── SpeechService (Voice recording, transcription)           │
│  ├── NLPService (Command interpretation)                      │
│  └── QueueService (Offline command management)                │
├─────────────────────────────────────────────────────────────────┤
│  Connector Layer (Dart)                                        │
│  ├── Base Connector (Abstract connector class)                │
│  ├── Google Tasks Connector (Google Tasks API)                │
│  ├── Apple Notes Connector (iOS Notes integration)            │
│  ├── Evernote Connector (Evernote API)                        │
│  └── Future Connectors (Calendar, Gmail, etc.)                │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer                                                     │
│  ├── RealmDB (Local storage, offline-first)                   │
│  ├── Flutter Secure Storage (Token storage)                   │
│  └── External APIs (Google, Apple, Evernote)                  │
├─────────────────────────────────────────────────────────────────┤
│  Native iOS Layer (Swift)                                      │
│  ├── AppDelegate (App lifecycle, error handling)              │
│  ├── Speech Recognition (SFSpeechRecognizer)                  │
│  ├── Google Sign-In (Native OAuth2)                           │
│  └── Method Channels (Swift ↔ Flutter communication)          │
├─────────────────────────────────────────────────────────────────┤
│  External Services                                              │
│  ├── Sentry (Error monitoring, performance tracking)          │
│  ├── Google Cloud APIs (Tasks, Calendar, Gmail)               │
│  ├── Apple APIs (Notes, Calendar)                             │
│  ├── Evernote API (Notes, Notebooks)                          │
│  └── AI/LLM Services (Command interpretation)                 │
└─────────────────────────────────────────────────────────────────┘
```

## State Management Architecture

### Riverpod StateNotifier Pattern

The app uses Riverpod with StateNotifier for reactive state management:

```dart
// State Definition
class GoogleAuthState {
  final bool isAuthenticated;
  final String? userEmail;
  final String? userName;
  final String? userId;
  final Set<String> connectedServices;
}

// StateNotifier Implementation
class GoogleAuthService extends StateNotifier<GoogleAuthState> {
  GoogleAuthService() : super(GoogleAuthState.initial());
  
  // State updates trigger UI rebuilds
  void _updateState() {
    state = state.copyWith(
      isAuthenticated: true,
      userEmail: userEmail,
      // ... other properties
    );
  }
}

// Provider Definition
final googleAuthServiceProvider = StateNotifierProvider<GoogleAuthService, GoogleAuthState>((ref) {
  return GoogleAuthService();
});
```

### State Flow

```
User Action → Service Method → State Update → UI Rebuild
     ↓              ↓              ↓            ↓
  onTap() → authenticate() → state = newState → Consumer rebuilds
```

## Connector Architecture

### Multi-Provider Integration System

The app uses a scalable connector architecture that supports multiple service providers:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Connector Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│  Integration Manager                                           │
│  ├── Provider Registration (Google, Apple, Evernote)          │
│  ├── State Management (Authentication, services)              │
│  └── Service Coordination (Multi-provider operations)         │
├─────────────────────────────────────────────────────────────────┤
│  Connector Manager                                             │
│  ├── Lifecycle Management (Initialize, dispose)               │
│  ├── Connector Registry (Available connectors)                │
│  └── Error Handling (Centralized error recovery)              │
├─────────────────────────────────────────────────────────────────┤
│  Network Service                                               │
│  ├── Retry Logic (Exponential backoff)                        │
│  ├── Authentication Refresh (Token renewal)                   │
│  └── Error Classification (Retryable vs fatal)                │
├─────────────────────────────────────────────────────────────────┤
│  Base Connector (Abstract)                                    │
│  ├── Common Network Logic (Shared retry, auth)                │
│  ├── Error Handling (Standardized error recovery)             │
│  └── Lifecycle Management (Initialize, dispose)               │
├─────────────────────────────────────────────────────────────────┤
│  Specific Connectors                                           │
│  ├── GoogleTasksConnector (Google Tasks API)                  │
│  ├── AppleNotesConnector (iOS Notes)                          │
│  ├── EvernoteConnector (Evernote API)                         │
│  └── Future Connectors (Calendar, Gmail, etc.)                │
└─────────────────────────────────────────────────────────────────┘
```

### Base Connector Implementation

```dart
abstract class BaseConnector {
  final String id;
  final String integrationProviderId;
  final NetworkService _networkService;
  final IntegrationManager _integrationManager;

  BaseConnector({
    required this.id,
    required this.integrationProviderId,
    required NetworkService networkService,
    required IntegrationManager integrationManager,
  });

  // Common network operations with retry logic
  Future<T> execute<T>(Future<T> Function() operation, String operationName) {
    return _networkService.execute(
      operation,
      operationName,
      onAuthRefreshNeeded: () async {
        final provider = _integrationManager.getProvider(integrationProviderId);
        return await provider?.ensureValidAuthentication() ?? false;
      },
    );
  }

  // Lifecycle management
  Future<void> initialize();
  void dispose();
}
```

### Google Integration Details

#### OAuth2 Flow

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│   Flutter   │    │   Native     │    │   Google    │    │   Flutter   │
│   UI        │    │   iOS        │    │   OAuth2    │    │   Service   │
│             │    │              │    │   Server    │    │             │
├─────────────┤    ├──────────────┤    ├─────────────┤    ├─────────────┤
│ 1. User     │    │ 2. Open      │    │ 3. User     │    │ 4. Receive  │
│    taps     │    │    Safari    │    │    signs    │    │    tokens   │
│    "Sign    │    │    browser   │    │    in       │    │             │
│    In"      │    │              │    │             │    │             │
│             │    │              │    │             │    │             │
│ 5. Update   │    │              │    │             │    │ 6. Store    │
│    UI       │    │              │    │             │    │    tokens   │
│    state    │    │              │    │             │    │    securely │
└─────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
```

#### Service Architecture

```dart
// New Integration Architecture
IntegrationManager
├── GoogleIntegrationProvider (OAuth2, token management)
│   ├── GoogleSignIn (Native iOS integration)
│   ├── Token Storage (Flutter Secure Storage)
│   ├── Service Management (Tasks, Calendar, Gmail toggles)
│   └── State Management (Riverpod StateNotifier)
├── AppleNotesIntegrationProvider (iOS Notes)
├── EvernoteIntegrationProvider (Evernote API)
└── Future Providers (Microsoft, Fantastical, etc.)

ConnectorManager
├── GoogleTasksConnector (Google Tasks API)
├── GoogleCalendarConnector (Google Calendar API)
├── AppleNotesConnector (iOS Notes)
├── EvernoteConnector (Evernote API)
└── Future Connectors (Gmail, etc.)
```

### Token Management

```dart
class GoogleAuthService {
  // Token storage
  static const _storage = FlutterSecureStorage();
  
  // Token refresh
  Future<bool> ensureValidTokens() async {
    if (_needsRefresh()) {
      return await _refreshTokens();
    }
    return true;
  }
  
  // Secure storage
  Future<void> _storeTokens(AccessCredentials credentials) async {
    await _storage.write(key: _accessTokenKey, value: credentials.accessToken.data);
    // ... store other token data
  }
}
```

## Error Handling Architecture

### Hybrid Error Reporting

The app implements a sophisticated error handling system that combines Flutter and native iOS error reporting:

#### Flutter Error Handling
```dart
// Global error handlers
FlutterError.onError = (FlutterErrorDetails details) {
  Sentry.captureException(details.exception, stackTrace: details.stack);
};

PlatformDispatcher.instance.onError = (error, stack) {
  Sentry.captureException(error, stackTrace: stack);
  return true;
};

// Service-level error handling
try {
  final result = await apiCall();
  return result;
} catch (e, stackTrace) {
  Logger.error('API call failed', error: e, stackTrace: stackTrace);
  Sentry.captureException(e, stackTrace: stackTrace);
  rethrow;
}
```

#### Native iOS Error Handling
```swift
// Error reporting with queue system
func reportError(_ error: Error, context: String = "") {
  if SentrySDK.isEnabled {
    SentrySDK.capture(error: error) { scope in
      // Configure error context
    }
  } else {
    errorQueue.append(error) // Queue for later
  }
}

// Method channel for Flutter communication
func safeGoogleSignIn(completion: @escaping (Bool, String?) -> Void) {
  do {
    // Google Sign-In logic
  } catch {
    reportError(error, context: "Google Sign-In")
    completion(false, error.localizedDescription)
  }
}
```

### Error Queue System

```dart
// Flutter side - Queue flushing
await RetryMechanism.execute(
  () async {
    final result = await errorQueueChannel.invokeMethod('flushQueue');
    final flushedCount = result['count'] as int;
    
    if (flushedCount == 0) {
      throw Exception('No errors were flushed');
    }
  },
);
```

## Data Architecture

### RealmDB Schema

```dart
// Command model
@RealmModel()
class _QueuedCommandRealm {
  @PrimaryKey()
  late String id;
  late String text;
  late String type;
  late DateTime createdAt;
  late bool isProcessed;
  late String? audioPath;
  late String? result;
}

// Migration handling
class RealmService {
  static const _schemaVersion = 1;
  
  static Realm openRealm() {
    final config = Configuration.local(
      [QueuedCommandRealm.schema],
      schemaVersion: _schemaVersion,
      migrationCallback: _migrate,
    );
    return Realm(config);
  }
}
```

### Data Flow

```
Voice Input → Speech Recognition → NLP Processing → Command Storage
     ↓              ↓                    ↓              ↓
  Audio File → Text Transcription → AI Interpretation → RealmDB
```

## Performance Architecture

### Sentry Performance Monitoring

```dart
// App startup monitoring
final appStartTransaction = Sentry.startTransaction('app.startup', 'app.lifecycle');

// Service operation monitoring
final transaction = Sentry.startTransaction('google.signin', 'auth');
final span = transaction.startChild('google.signin.call');

try {
  final result = await operation();
  span.finish(status: const SpanStatus.ok());
  transaction.finish(status: const SpanStatus.ok());
  return result;
} catch (e) {
  span.finish(status: const SpanStatus.internalError());
  transaction.finish(status: const SpanStatus.internalError());
  rethrow;
}
```

### UI Performance Optimizations

```dart
// Microtask for smooth animations
onTap: () {
  Future.microtask(() => onTap());
},

// Pre-warming for first-tap responsiveness
void _preWarmCriticalWidgets() {
  // Create off-screen widgets to compile shaders
}
```

## Localization Architecture

### Multi-Language Support

The app supports multiple languages with instant switching and build validation:

```dart
// Language Provider
class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(LanguageState(locale: const Locale('en'))) {
    _loadPreferredLanguage();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredLanguageCode', newLocale.languageCode);
    state = state.copyWith(locale: newLocale);
  }
}

// Usage in UI
Text(AppLocalizations.of(context)!.readyToRecord)
```

### Translation System

- **ARB Files**: `app_en.arb` and `app_lt.arb` for translations
- **Build Validation**: Automatic checking for missing translations
- **CI/CD Integration**: Build fails if translations are incomplete
- **Developer Tools**: VS Code tasks, Git hooks, Makefile integration

### Supported Languages

- ✅ **English**: Complete translation coverage
- ✅ **Lithuanian**: Complete translation coverage
- 🔄 **Future Languages**: Easy to add new languages

## Theme Architecture

### Dynamic Theme System

The app supports system/light/dark themes with persistence:

```dart
// Theme Provider
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(mode: AppThemeMode.system)) {
    _loadPreferredThemeMode();
  }

  Future<void> changeThemeMode(AppThemeMode newMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredThemeMode', newMode.toString().split('.').last);
    state = state.copyWith(mode: newMode);
  }
}

// Usage in MaterialApp
MaterialApp(
  themeMode: currentThemeMode,
  theme: _buildLightTheme(),
  darkTheme: _buildDarkTheme(),
)
```

### Design Token System

Consistent styling through design tokens:

```dart
class DesignTokens {
  // Spacing
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  
  // Colors
  static const Color primary = Color(0xFF007AFF);
  static const Color background = Color(0xFFFFFFFF);
  
  // Typography
  static const TextStyle title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
}
```

## Security Architecture

### Token Security

```dart
// Secure token storage
class GoogleAuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}
```

### OAuth2 Security

- **PKCE**: Proof Key for Code Exchange
- **State Parameter**: CSRF protection
- **Secure Storage**: Encrypted token storage
- **Token Refresh**: Automatic token renewal
- **Scope Management**: Minimal required permissions

## Testing Architecture

### Unit Testing

```dart
// Service testing
class MockGoogleAuthService extends GoogleAuthService {
  @override
  Future<bool> authenticate() async => true;
}

// Provider testing
void main() {
  group('GoogleAuthService', () {
    test('should authenticate successfully', () async {
      final container = ProviderContainer(
        overrides: [
          googleAuthServiceProvider.overrideWith(() => MockGoogleAuthService()),
        ],
      );
      
      final service = container.read(googleAuthServiceProvider.notifier);
      final result = await service.authenticate();
      
      expect(result, true);
    });
  });
}
```

### Integration Testing

```dart
// Widget testing
testWidgets('Google Sign-In flow', (WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    child: SettingsScreen(),
  ));
  
  await tester.tap(find.text('Google Account'));
  await tester.pumpAndSettle();
  
  expect(find.text('Connected as:'), findsOneWidget);
});
```

## Deployment Architecture

### Build Configuration

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  sentry_flutter: ^7.0.0
  google_sign_in: ^6.2.1
  realm: ^0.5.0
  riverpod: ^2.4.0
```

### iOS Configuration

```xml
<!-- Info.plist -->
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### Environment Configuration

```dart
// .env file
SENTRY_DSN=https://your-dsn@sentry.io/project-id
GOOGLE_CLIENT_ID=your-client-id
```

## Monitoring and Observability

### Error Monitoring

- **Sentry Integration**: Comprehensive error tracking
- **Error Queue**: Handles pre-initialization errors
- **Performance Monitoring**: Transaction and span tracking
- **Release Tracking**: Error correlation with releases

### Logging Strategy

```dart
// Structured logging
Logger.info('User authenticated successfully', 
  tag: 'GOOGLE_AUTH',
  data: {'userEmail': userEmail}
);

Logger.error('API call failed',
  tag: 'GOOGLE_TASKS',
  error: e,
  stackTrace: stackTrace
);
```

### Performance Metrics

- **App Startup Time**: Complete initialization duration
- **Authentication Flow**: Google Sign-In performance
- **API Response Times**: Service integration latency
- **UI Responsiveness**: Critical user interaction timing

This architecture provides a robust, scalable, and maintainable foundation for the Finally Done app while ensuring excellent user experience and comprehensive monitoring capabilities.
