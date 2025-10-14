import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'integration_provider.dart';
import 'google_integration_provider.dart';
import 'apple_notes_integration_provider.dart';
import 'evernote_integration_provider.dart';

/// Manages all integration providers and their services
class IntegrationManager extends StateNotifier<Map<String, IntegrationProviderState>> {
  final Map<String, IntegrationProvider> _providers = {};

  IntegrationManager() : super({}) {
    print('🔵 INTEGRATION MANAGER: Constructor called');
    // Defer heavy initialization to avoid blocking UI - use post frame callback for lightest load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔵 INTEGRATION MANAGER: _initializeProviders called');
      _initializeProviders();
    });
  }

  void _initializeProviders() async {
    print('🔵 INTEGRATION MANAGER: _initializeProviders starting');
    // Add a small delay to spread out initialization work
    await Future.delayed(Duration(milliseconds: 50));
    // Register all available integration providers
    _providers['google'] = GoogleIntegrationProvider();
    print('🔵 INTEGRATION MANAGER: GoogleIntegrationProvider created');
    _providers['apple_notes'] = AppleNotesIntegrationProvider();
    _providers['evernote'] = EvernoteIntegrationProvider();
    
    // Initialize states for all providers
    for (final providerId in _providers.keys) {
      print('🔵 INTEGRATION MANAGER: Updating state for provider: $providerId');
      _updateProviderState(providerId);
    }
    
    // Wait a bit for Google provider to initialize, then update its state again
    Future.delayed(Duration(milliseconds: 100), () {
      print('🔵 INTEGRATION MANAGER: Updating Google state after initialization');
      _updateProviderState('google');
    });
    
    // Set up periodic state updates for Google provider to catch state changes
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_providers['google'] != null) {
        final googleState = _providers['google']!.state;
        final currentState = state['google'];
        if (currentState == null || currentState.isAuthenticated != googleState.isAuthenticated) {
          print('🔵 INTEGRATION MANAGER: Google state changed, updating...');
          _updateProviderState('google');
        }
      }
    });
    
    print('🔵 INTEGRATION MANAGER: _initializeProviders completed');
  }

  /// Get all available providers
  List<IntegrationProvider> get availableProviders => _providers.values.toList();

  /// Get a specific provider
  IntegrationProvider? getProvider(String providerId) => _providers[providerId];

  /// Get all connected services across all providers
  List<IntegrationService> get allConnectedServices {
    return _providers.values
        .expand((provider) => provider.state.connectedServices)
        .toList();
  }

  /// Get connected services for a specific provider
  List<IntegrationService> getConnectedServices(String providerId) {
    return _providers[providerId]?.state.connectedServices ?? [];
  }

  /// Check if a provider is authenticated
  bool isProviderAuthenticated(String providerId) {
    return _providers[providerId]?.state.isAuthenticated ?? false;
  }

  /// Check if a specific service is connected
  bool isServiceConnected(String providerId, String serviceId) {
    return _providers[providerId]?.state.isServiceConnected(serviceId) ?? false;
  }

  /// Authenticate with a provider
  Future<bool> authenticateProvider(String providerId) async {
    final provider = _providers[providerId];
    if (provider == null) return false;

    final success = await provider.authenticate();
    if (success) {
      _updateProviderState(providerId);
    }
    return success;
  }

  /// Connect to specific services within a provider
  Future<bool> connectServices(String providerId, List<String> serviceIds) async {
    final provider = _providers[providerId];
    if (provider == null) return false;

    final success = await provider.connectServices(serviceIds);
    if (success) {
      _updateProviderState(providerId);
    }
    return success;
  }

  /// Toggle a single service connection
  Future<bool> toggleService(String providerId, String serviceId) async {
    final provider = _providers[providerId];
    if (provider == null) return false;

    final success = await provider.toggleService(serviceId);
    if (success) {
      _updateProviderState(providerId);
    }
    return success;
  }

  /// Disconnect from specific services
  Future<bool> disconnectServices(String providerId, List<String> serviceIds) async {
    final provider = _providers[providerId];
    if (provider == null) return false;

    final success = await provider.disconnectServices(serviceIds);
    if (success) {
      _updateProviderState(providerId);
    }
    return success;
  }

  /// Sign out from a provider
  Future<void> signOutProvider(String providerId) async {
    final provider = _providers[providerId];
    if (provider == null) return;

    await provider.signOut();
    _updateProviderState(providerId);
  }

  /// Update the state for a specific provider
  void _updateProviderState(String providerId) {
    // Check if the manager is still mounted to prevent dispose errors
    if (mounted) {
      final provider = _providers[providerId];
      if (provider != null) {
        print('🔵 INTEGRATION MANAGER: Updating state for $providerId - isAuthenticated: ${provider.state.isAuthenticated}');
        state = {
          ...state,
          providerId: provider.state,
        };
        print('🔵 INTEGRATION MANAGER: State updated for $providerId');
      }
    } else {
      print('🔵 INTEGRATION MANAGER: Skipping state update - manager is disposed');
    }
  }

  /// Get providers that have connected services
  List<IntegrationProvider> get providersWithConnectedServices {
    return _providers.values
        .where((provider) => provider.hasConnectedServices)
        .toList();
  }

  /// Get total connected services count
  int get totalConnectedServices => allConnectedServices.length;

  @override
  void dispose() {
    print('🔵 INTEGRATION MANAGER: Disposing IntegrationManager');
    // Clean up any resources
    _providers.clear();
    super.dispose();
  }
}

/// Provider for IntegrationManager
final integrationManagerProvider = StateNotifierProvider<IntegrationManager, Map<String, IntegrationProviderState>>((ref) {
  return IntegrationManager();
});

/// Provider for available providers list
final availableProvidersProvider = Provider<List<IntegrationProvider>>((ref) {
  final manager = ref.watch(integrationManagerProvider.notifier);
  return manager.availableProviders;
});

/// Provider for connected services across all providers
final allConnectedServicesProvider = Provider<List<IntegrationService>>((ref) {
  final manager = ref.watch(integrationManagerProvider.notifier);
  return manager.allConnectedServices;
});

/// Provider for a specific provider's state
final providerStateProvider = Provider.family<IntegrationProviderState?, String>((ref, providerId) {
  final states = ref.watch(integrationManagerProvider);
  return states[providerId];
});

/// Provider for a specific provider's connected services
final providerConnectedServicesProvider = Provider.family<List<IntegrationService>, String>((ref, providerId) {
  final manager = ref.watch(integrationManagerProvider.notifier);
  return manager.getConnectedServices(providerId);
});
