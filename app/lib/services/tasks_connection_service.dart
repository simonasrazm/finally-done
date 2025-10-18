import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/integrations/integration_manager.dart';
import '../services/integrations/google_integration_provider.dart';
import '../services/google_tasks_service.dart';
import '../services/connectors/connector_manager.dart';

/// Service responsible for managing Google Tasks connection status and service creation
class TasksConnectionService {
  final Ref _ref;

  TasksConnectionService(this._ref);

  /// Check if Google Tasks is connected
  bool isConnected() {
    try {
      // Check if integration manager notifier is available
      final manager = _ref.read(integrationManagerProvider.notifier);
      if (manager == null) {
        return false;
      }
      
      final isConnected = manager.isServiceConnected('google', 'tasks');
      
      // If already connected, return true
      if (isConnected) {
        return true;
      }
      
      // Additional check: if the Google Tasks service is available, consider it connected
      // This handles the race condition where the service is working but state hasn't updated yet
      final tasksService = _ref.read(googleTasksServiceProvider);
      if (tasksService != null) {
        return true;
      }
      
      // Final fallback: check if Google integration is authenticated (even if service not marked as connected)
      final integrationState = _ref.read(integrationManagerProvider);
      if (integrationState == null) {
        return false;
      }
      
      final googleState = integrationState['google'];
      if (googleState != null && googleState.isAuthenticated) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get the Google Tasks service if available
  GoogleTasksService? getService() {
    return _ref.read(googleTasksServiceProvider);
  }

  /// Create a direct Google Tasks service using available auth client
  Future<GoogleTasksService?> createDirectService() async {
    try {
      final manager = _ref.read(integrationManagerProvider.notifier);
      final connectorManager = _ref.read(connectorManagerProvider.notifier);
      final googleProvider = manager.getProvider('google') as GoogleIntegrationProvider?;
      
      if (googleProvider?.authClient != null) {
        return GoogleTasksService(manager, connectorManager, googleProvider!.authClient!);
      }
      
      return null;
    } catch (e) {
      // Let the exception bubble up - this is a critical service creation failure
      rethrow;
    }
  }

  /// Get or create a Google Tasks service
  Future<GoogleTasksService?> getOrCreateService() async {
    // First try to get existing service
    final existingService = getService();
    if (existingService != null) {
      return existingService;
    }

    // If no existing service, try to create one directly
    return await createDirectService();
  }

  /// Check if an error indicates connectivity issues
  bool isConnectivityError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable') ||
           errorString.contains('socket') ||
           errorString.contains('dns');
  }
}

/// Provider for TasksConnectionService
final tasksConnectionServiceProvider = Provider<TasksConnectionService>((ref) {
  return TasksConnectionService(ref);
});
