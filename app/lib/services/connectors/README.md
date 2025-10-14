# Connector Architecture

This directory contains the new connector architecture that centralizes network operations, retry logic, and error handling for all API integrations.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Connector Architecture                    │
├─────────────────────────────────────────────────────────────┤
│  ConnectorManager                                           │
│  ├── GoogleTasksConnector                                  │
│  ├── GoogleCalendarConnector                               │
│  ├── GoogleGmailConnector                                  │
│  ├── AppleNotesConnector                                   │
│  └── EvernoteConnector                                     │
├─────────────────────────────────────────────────────────────┤
│  BaseConnector (Abstract)                                  │
│  ├── NetworkService integration                            │
│  ├── Automatic retry logic                                 │
│  ├── Authentication refresh                                │
│  └── Error handling                                        │
├─────────────────────────────────────────────────────────────┤
│  NetworkService (Singleton)                                │
│  ├── Retry logic with exponential backoff                  │
│  ├── HTTP client management                                │
│  ├── Authentication error handling                         │
│  └── Network error classification                          │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Benefits

### 1. **Centralized Network Logic**
- All retry logic, error handling, and network operations are centralized
- Consistent behavior across all connectors
- Easy to update network policies globally

### 2. **Automatic Error Recovery**
- Exponential backoff retry for network errors
- Automatic authentication token refresh
- Graceful handling of connection issues

### 3. **Easy to Extend**
- Add new connectors by extending `BaseConnector`
- All network challenges are handled automatically
- Focus on business logic, not infrastructure

### 4. **Better Error Handling**
- Classified error types (retryable vs non-retryable)
- Comprehensive logging and monitoring
- Sentry integration for error tracking

## 📁 File Structure

```
lib/services/
├── network/
│   └── network_service.dart          # Centralized network operations
├── connectors/
│   ├── base_connector.dart           # Abstract base class
│   ├── connector_manager.dart        # Manages all connectors
│   ├── google_tasks_connector.dart   # Google Tasks implementation
│   ├── google_calendar_connector.dart # Google Calendar implementation
│   └── README.md                     # This documentation
└── google_tasks_service.dart         # Legacy service (with fallback)
```

## 🔧 Usage Examples

### Creating a New Connector

```dart
class MyNewConnector extends BaseConnector {
  MyNewConnector({NetworkConfig? networkConfig})
      : super(connectorName: 'My New Service', networkConfig: networkConfig);

  @override
  Future<void> initialize({
    required String accessToken,
    required List<String> scopes,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    await super.initialize(
      accessToken: accessToken,
      scopes: scopes,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
    );
    
    // Initialize your API client here
    _myApiClient = MyApiClient(authClient!);
  }

  Future<List<MyData>> getData() async {
    return await executeWithAuthRefresh(
      () async {
        // Your API call here - retry logic is automatic!
        return await _myApiClient.getData();
      },
      operationName: 'fetch data',
    );
  }
}
```

### Using a Connector

```dart
// Get the connector
final connector = ref.watch(connectorManagerProvider.notifier)
    .getConnector<GoogleTasksConnector>('google_tasks');

// Use it - all network issues are handled automatically
if (connector?.isInitialized == true) {
  final tasks = await connector!.getTasks(taskListId);
}
```

## 🛠️ Configuration

### Network Configuration

```dart
// Default configuration
const NetworkConfig.defaultConfig = NetworkConfig(
  maxRetries: 3,
  baseDelay: Duration(milliseconds: 1000),
  maxDelay: Duration(seconds: 10),
  connectionTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 60),
);

// Critical operations (more retries)
const NetworkConfig.criticalConfig = NetworkConfig(
  maxRetries: 5,
  baseDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 15),
);

// Quick operations (fewer retries)
const NetworkConfig.quickConfig = NetworkConfig(
  maxRetries: 2,
  baseDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 5),
);
```

## 🔄 Migration Strategy

The new architecture is designed to work alongside the existing code:

1. **Phase 1**: New connectors use the new architecture
2. **Phase 2**: Existing services fall back to new connectors when available
3. **Phase 3**: Gradually migrate all operations to use connectors
4. **Phase 4**: Remove legacy code

### Current Status

- ✅ `GoogleTasksConnector` - Fully implemented
- ✅ `GoogleCalendarConnector` - Example implementation
- 🔄 `GoogleTasksService` - Uses connector when available, falls back to legacy
- ⏳ Other connectors - To be implemented as needed

## 🐛 Error Handling

### Automatic Retry Logic

The system automatically retries on these error types:
- `OSError` (Bad file descriptor, etc.)
- `HandshakeException` (SSL/TLS issues)
- `SocketException` (Network connectivity)
- `TimeoutException` (Request timeouts)
- Connection-related errors

### Authentication Refresh

When authentication errors occur:
1. System detects authentication failure
2. Attempts to refresh the token
3. Retries the original operation
4. Falls back gracefully if refresh fails

## 📊 Monitoring

All operations are logged with:
- Operation name and timing
- Retry attempts and delays
- Success/failure status
- Error details for Sentry

## 🚀 Future Enhancements

1. **Circuit Breaker Pattern** - Prevent cascading failures
2. **Rate Limiting** - Respect API rate limits
3. **Caching** - Cache responses for better performance
4. **Metrics** - Detailed performance metrics
5. **Health Checks** - Monitor connector health

## 💡 Best Practices

1. **Always use `executeWithAuthRefresh`** for operations that need authentication
2. **Use `executeOperation`** for operations that don't need auth refresh
3. **Provide meaningful operation names** for better logging
4. **Handle connector initialization** properly in your providers
5. **Use appropriate network configurations** for different operation types

This architecture ensures that all future connectors will automatically benefit from robust network handling, retry logic, and error recovery without duplicating code.
