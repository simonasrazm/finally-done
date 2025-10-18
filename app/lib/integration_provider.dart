import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a specific service within an integration provider
class IntegrationService {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isConnected;
  final Map<String, dynamic> permissions;
  final String? scope;

  const IntegrationService({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isConnected = false,
    this.permissions = const {},
    this.scope,
  });

  IntegrationService copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isConnected,
    Map<String, dynamic>? permissions,
    String? scope,
  }) {
    return IntegrationService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isConnected: isConnected ?? this.isConnected,
      permissions: permissions ?? this.permissions,
      scope: scope ?? this.scope,
    );
  }
}

/// Represents the state of an integration provider
class IntegrationProviderState {
  final bool isAuthenticated;
  final String? userEmail;
  final String? userName;
  final String? userId;
  final Map<String, IntegrationService> services;
  final bool isLoading;
  final bool isConnecting;
  final bool isSyncing;
  final String? lastSyncTime;

  const IntegrationProviderState({
    this.isAuthenticated = false,
    this.userEmail,
    this.userName,
    this.userId,
    this.services = const {},
    this.isLoading = false,
    this.isConnecting = false,
    this.isSyncing = false,
    this.lastSyncTime,
  });

  IntegrationProviderState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? userName,
    String? userId,
    Map<String, IntegrationService>? services,
    bool? isLoading,
    bool? isConnecting,
    bool? isSyncing,
    String? lastSyncTime,
  }) {
    return IntegrationProviderState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      isConnecting: isConnecting ?? this.isConnecting,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  /// Get list of connected services
  List<IntegrationService> get connectedServices => 
      services.values.where((service) => service.isConnected).toList();

  /// Check if a specific service is connected
  bool isServiceConnected(String serviceId) => 
      services[serviceId]?.isConnected ?? false;

  /// Get count of connected services
  int get connectedServicesCount => connectedServices.length;
}

/// Abstract base class for integration providers
abstract class IntegrationProvider extends StateNotifier<IntegrationProviderState> {
  final String id;
  final String displayName;
  final String icon;
  final String description;

  IntegrationProvider({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.description,
  }) : super(const IntegrationProviderState());

  /// Get list of available services for this provider
  List<IntegrationService> get availableServices;

  /// Initialize the provider (check for stored tokens, etc.)
  Future<void> initialize() async {
    // Default implementation does nothing
    // Subclasses can override to perform initialization
  }

  /// Authenticate with the provider (basic authentication)
  Future<bool> authenticate();

  /// Connect to specific services (request additional permissions)
  Future<bool> connectServices(List<String> serviceIds);

  /// Disconnect from specific services
  Future<bool> disconnectServices(List<String> serviceIds);

  /// Toggle a single service connection
  Future<bool> toggleService(String serviceId);

  /// Sign out completely from the provider
  Future<void> signOut();

  /// Check if provider is ready for use
  bool get isReady => state.isAuthenticated;

  /// Get connected services count
  int get connectedServicesCount => state.connectedServices.length;

  /// Check if any services are connected
  bool get hasConnectedServices => connectedServicesCount > 0;
}
