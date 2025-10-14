# Finally Done - AI-Powered Personal Organization App

Finally Done is an iOS app that helps you organize your personal life by capturing tasks, events, and notes through voice commands. It uses AI to understand your commands and route them to the appropriate services.

## Features

- **Voice Recording**: Record commands in Lithuanian or English using iOS native speech recognition
- **AI Processing**: Intelligent command interpretation using cloud-based LLM
- **Mission Control**: Review and manage all your commands in one place
- **Multi-Provider Integration**: Connect to Google Tasks, Apple Notes, Evernote, and more
- **Offline-First**: Record commands offline, process when online
- **Multi-Language Support**: Full localization in English and Lithuanian with instant language switching
- **Theme System**: System/light/dark mode selection with persistent preferences
- **Error Monitoring**: Comprehensive error tracking with Sentry
- **Performance Monitoring**: Real-time performance insights
- **Connector Architecture**: Scalable system for adding new service integrations

## Architecture

- **Framework**: Flutter 3.35.6 with native iOS extensions
- **Speech Recognition**: iOS SFSpeechRecognizer (on-device, zero app size cost)
- **AI Processing**: Cloud-based LLM with laptop Ollama fallback for development
- **Local Storage**: RealmDB for offline-first data storage
- **State Management**: Flutter Riverpod with StateNotifier
- **Connector System**: Scalable architecture for service integrations
- **Localization**: Flutter's built-in i18n with build validation
- **Theme Management**: Dynamic theme switching with persistence
- **Error Monitoring**: Sentry with hybrid Flutter + native iOS reporting
- **Performance Monitoring**: Sentry performance transactions and spans
- **Network Layer**: Centralized retry logic and authentication refresh

## Setup Instructions

1. **Prerequisites**:
   - Flutter 3.35.6+
   - Xcode 15+
   - iOS 13+ device or simulator

2. **Install Dependencies**:
   ```bash
   cd finally_done
   flutter pub get
   ```

3. **Run on iOS**:
   ```bash
   flutter run
   ```

4. **Grant Permissions**:
   - Microphone access
   - Speech recognition access

## Testing

Before building the full app, test Lithuanian speech recognition:

1. **Run the test app**:
   ```bash
   cd ../speech_test
   flutter run
   ```

2. **Test Lithuanian phrases**:
   - "Nupirk pieno rytoj" (Buy milk tomorrow)
   - "Susitikimas pirmadienį pusę trijų" (Meeting Monday half past two)
   - "Pastaba: slaptažodis yra vienas du trys" (Note: password is one two three)

3. **If accuracy is good (>80%)**: Use iOS SFSpeechRecognizer
4. **If accuracy is poor (<80%)**: Consider Whisper Tiny fallback

## Error Monitoring & Sentry Integration

### Architecture Overview

The app uses a **hybrid error reporting system** that combines Flutter and native iOS error handling:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Native iOS     │    │   Sentry SDK    │
│                 │    │   (Swift)        │    │                 │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ • Flutter errors│    │ • Native errors  │    │ • Error storage │
│ • UI exceptions │    │ • Google Sign-In │    │ • Performance   │
│ • Async errors  │    │ • System crashes │    │ • Session Replay│
│ • Business logic│    │ • Memory issues  │    │ • Release track │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    Error Queue System   │
                    │                         │
                    │ • Queues errors when    │
                    │   Sentry not ready      │
                    │ • Flushes on init       │
                    │ • Retry mechanism       │
                    └─────────────────────────┘
```

### Error Handling Responsibilities

#### **Flutter Side** (`main.dart`, services)
- **Flutter exceptions**: UI errors, widget crashes, async errors
- **Business logic errors**: Service failures, API errors, validation errors
- **Performance monitoring**: Custom transactions and spans
- **Global error handlers**: `FlutterError.onError`, `PlatformDispatcher.instance.onError`

#### **Native iOS Side** (`AppDelegate.swift`)
- **Native crashes**: Memory access violations, thread deadlocks
- **Google Sign-In errors**: Configuration issues, authentication failures
- **System-level errors**: Keychain access, file system errors
- **Method channel errors**: Swift-to-Flutter communication failures

### Error Queue System

The app implements a sophisticated error queue system to handle cases where Sentry isn't ready:

1. **Error Queuing**: Native errors are queued when `SentrySDK.isEnabled = false`
2. **Queue Flushing**: Flutter polls the queue after Sentry initialization
3. **Retry Mechanism**: Exponential backoff (1s, 3s, 10s, 1m, 5m, 1h)
4. **Error Filtering**: Prevents duplicate reporting and noise

### Configuration

```dart
// Flutter Sentry Configuration
await SentryFlutter.init(
  (options) {
    options.dsn = sentryDsn;
    options.tracesSampleRate = 1.0;
    options.debug = true; // Development only
    options.enableAutoSessionTracking = true;
    options.attachStacktrace = true;
    options.sendDefaultPii = false;
    
    // Session Replay
    options.replay.sessionSampleRate = 1.0;
    options.replay.onErrorSampleRate = 1.0;
    
    // Release tracking
    options.release = 'finally-done@1.0.0+1';
    options.dist = '1';
  },
  appRunner: () => runApp(FinallyDoneApp()),
);
```

### Performance Monitoring

- **App Startup**: Monitored with custom transactions
- **Google Sign-In**: Performance spans for authentication flow
- **API Calls**: Service integration performance tracking
- **UI Interactions**: Critical user journey monitoring

## Development Status

- ✅ Project setup with Flutter 3.35.6
- ✅ Design system (colors, typography, spacing, tokens)
- ✅ Realm data models and migration system
- ✅ Speech recognition service (iOS native)
- ✅ NLP service (cloud LLM + rule-based fallback)
- ✅ Main screens (Home, Mission Control, Settings, Tasks)
- ✅ iOS native speech recognition plugin
- ✅ Multi-provider integration system
- ✅ Google Sign-In integration with OAuth2
- ✅ Google Tasks API integration with connector architecture
- ✅ Localization system (English/Lithuanian) with build validation
- ✅ Theme management (system/light/dark) with persistence
- ✅ Sentry error monitoring and performance tracking
- ✅ State management with Riverpod StateNotifier
- ✅ Error queue system for native iOS errors
- ✅ UI responsiveness optimizations
- ✅ Connector architecture for scalable integrations
- ✅ Network service with retry logic and auth refresh
- ✅ Translation validation system with CI/CD integration
- 🔄 Google Calendar and Gmail integration
- 🔄 Apple Notes integration
- 🔄 Evernote integration
- ⏳ iOS widgets (Lock Screen, Control Center)
- ⏳ Advanced offline queueing system

## Integration System

### Multi-Provider Architecture
The app uses a scalable connector system that supports multiple service providers:

- **Integration Providers**: Abstract base classes for different service types
- **Connector Manager**: Centralized lifecycle management for all connectors
- **Network Service**: Shared retry logic, authentication refresh, and error handling
- **Service Management**: Granular control over which services to connect

### Supported Providers
- ✅ **Google**: Tasks, Calendar, Gmail (with individual service toggles)
- 🔄 **Apple Notes**: Native iOS notes integration (in progress)
- 🔄 **Evernote**: Note-taking service integration (in progress)

### Google Integration Details
- **OAuth2 Authentication**: Users sign in with their personal Google accounts
- **Scope Management**: Dynamic scopes based on connected services
- **Token Management**: Automatic refresh and secure storage
- **Service Connection**: Individual services can be connected/disconnected separately
- **Error Handling**: Robust retry logic and authentication refresh

### Configuration
- **iOS**: `GoogleService-Info.plist` with OAuth client configuration
- **Flutter**: Google Sign-In SDK with method channel for native error handling
- **Security**: Secure token storage using Flutter Secure Storage

## Next Steps

1. Complete Google Calendar and Gmail integration
2. Implement Apple Notes and Evernote connectors
3. Add iOS Lock Screen widget
4. Implement advanced offline queueing system
5. Add photo + note → task feature
6. Polish UI/UX based on user feedback
7. Add comprehensive test coverage
8. Add more language support

## App Size

Current estimated size: ~45 MB
- Flutter framework: ~30 MB
- Assets: ~10 MB
- RealmDB: ~5 MB
- Speech recognition: 0 MB (uses iOS system)

## Key Systems

### Localization System
- **Multi-language Support**: English and Lithuanian with instant switching
- **Build Validation**: Automatic translation checking with CI/CD integration
- **Developer Tools**: VS Code tasks, Git hooks, and Makefile integration
- **Quality Assurance**: Build fails if translations are missing

### Connector Architecture
- **Base Connector**: Abstract class for all service integrations
- **Network Service**: Centralized retry logic and authentication refresh
- **Connector Manager**: Lifecycle management for all connectors
- **Error Handling**: Robust error recovery and logging

### Theme System
- **Dynamic Theming**: System/light/dark mode selection
- **Design Tokens**: Consistent spacing, colors, and typography
- **Persistence**: User preferences saved across app sessions
- **Accessibility**: High contrast and proper color ratios

## Documentation

- **[Technical Architecture](../docs/architecture/TECHNICAL_ARCHITECTURE.md)**: Comprehensive technical overview
- **[Sentry Error Handling](../docs/architecture/SENTRY_ERROR_HANDLING.md)**: Error monitoring system details
- **[Connector System](../app/lib/services/connectors/README.md)**: Connector architecture guide
- **[Translation System](../app/TRANSLATIONS.md)**: Localization setup and usage
- **[API Documentation](../docs/api/)**: Service integration guides (coming soon)

## License

Private project - All rights reserved