import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_connector.dart';
import 'google_tasks_connector.dart';
import '../network/network_service.dart';
import '../../utils/logger.dart';

/// Manages all API connectors
/// Provides centralized access to connectors with proper lifecycle management
class ConnectorManager extends StateNotifier<Map<String, BaseConnector>> {
  final NetworkService _networkService = NetworkService();

  ConnectorManager() : super({}) {
    _initializeConnectors();
  }

  /// Initialize all available connectors
  void _initializeConnectors() {
    Logger.info('Initializing connector manager', tag: 'CONNECTOR_MANAGER');
    
    // Register available connectors
    state = {
      'google_tasks': GoogleTasksConnector(),
      // Future connectors can be added here:
      // 'google_calendar': GoogleCalendarConnector(),
      // 'google_gmail': GoogleGmailConnector(),
      // 'apple_notes': AppleNotesConnector(),
      // 'evernote': EvernoteConnector(),
    };
    
    Logger.info('Initialized ${state.length} connectors', tag: 'CONNECTOR_MANAGER');
  }

  /// Get a specific connector
  T? getConnector<T extends BaseConnector>(String connectorId) {
    final connector = state[connectorId];
    if (connector is T) {
      return connector;
    }
    return null;
  }

  /// Initialize a connector with authentication credentials
  Future<void> initializeConnector(
    String connectorId, {
    required String accessToken,
    required List<String> scopes,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    final connector = state[connectorId];
    if (connector == null) {
      throw ConnectorException('Connector not found: $connectorId');
    }

    await connector.initialize(
      accessToken: accessToken,
      scopes: scopes,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
    );

    Logger.info('Initialized connector: $connectorId', tag: 'CONNECTOR_MANAGER');
  }

  /// Update authentication credentials for a connector
  Future<void> updateConnectorCredentials(
    String connectorId, {
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
    List<String>? scopes,
  }) async {
    final connector = state[connectorId];
    if (connector == null) {
      throw ConnectorException('Connector not found: $connectorId');
    }

    await connector.updateCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
      scopes: scopes,
    );

    Logger.info('Updated credentials for connector: $connectorId', tag: 'CONNECTOR_MANAGER');
  }

  /// Check if a connector is initialized
  bool isConnectorInitialized(String connectorId) {
    final connector = state[connectorId];
    return connector?.isInitialized ?? false;
  }

  /// Get all initialized connectors
  List<BaseConnector> get initializedConnectors {
    return state.values.where((connector) => connector.isInitialized).toList();
  }

  /// Get all available connector IDs
  List<String> get availableConnectorIds => state.keys.toList();

  /// Dispose a specific connector
  void disposeConnector(String connectorId) {
    final connector = state[connectorId];
    if (connector != null) {
      connector.dispose();
      Logger.info('Disposed connector: $connectorId', tag: 'CONNECTOR_MANAGER');
    }
  }

  @override
  void dispose() {
    // Dispose all connectors
    for (final connector in state.values) {
      connector.dispose();
    }
    state.clear();
    Logger.info('Disposed connector manager', tag: 'CONNECTOR_MANAGER');
    super.dispose();
  }
}

/// Provider for ConnectorManager
final connectorManagerProvider = StateNotifierProvider<ConnectorManager, Map<String, BaseConnector>>((ref) {
  return ConnectorManager();
});

/// Provider for Google Tasks connector
final googleTasksConnectorProvider = Provider<GoogleTasksConnector?>((ref) {
  final manager = ref.watch(connectorManagerProvider.notifier);
  return manager.getConnector<GoogleTasksConnector>('google_tasks');
});

/// Provider to check if Google Tasks connector is initialized
final isGoogleTasksConnectorInitializedProvider = Provider<bool>((ref) {
  final manager = ref.watch(connectorManagerProvider.notifier);
  return manager.isConnectorInitialized('google_tasks');
});
