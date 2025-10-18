import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';
import 'integration_provider.dart';
import 'google_integration_provider.dart';
import 'apple_notes_integration_provider.dart';
import 'evernote_integration_provider.dart';
import '../../utils/sentry_performance.dart';

/// Manages all integration providers and their services
class IntegrationManager extends StateNotifier<Map<String, IntegrationProviderState>> {
  final Map<String, IntegrationProvider> _providers = {};

  IntegrationManager() : super({}) {
    // Initialize providers immediately with "not connected" state
    _initializeProvidersImmediately();
    
    // Then initialize them properly in the background (no delay)
    Future.microtask(() {
      _initializeProviders();
    });
  }
  
  void _initializeProvidersImmediately() {
    // Create providers immediately with "not connected" state so UI can show them
    _providers['google'] = GoogleIntegrationProvider();
    _providers['apple_notes'] = AppleNotesIntegrationProvider();
    _providers['evernote'] = EvernoteIntegrationProvider();
    
    // Set initial states for all providers
    for (final providerId in _providers.keys) {
      _updateProviderState(providerId);
    }
  }

  void _initializeProviders() async {
    // Initialize all providers in parallel (non-blocking)
    final futures = _providers.entries.map((entry) async {
      final providerId = entry.key;
      final provider = entry.value;
      
      try {
        // Call the provider's initialization method
        await provider.initialize();
      } catch (e) {
        // Error initializing provider - handled silently
      }
      
      // Update the state after initialization
      _updateProviderState(providerId);
    });
    
    // Wait for all providers to initialize in parallel
    await Future.wait(futures);
  }

  /// Check if initialization is complete
  bool get isInitialized => _providers.isNotEmpty;
  
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
        state = {
          ...state,
          providerId: provider.state,
        };
      }
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
