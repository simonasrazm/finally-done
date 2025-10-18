import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasks_connection_service.dart';

/// Service responsible for managing background polling of tasks
class TaskPollingService {

  TaskPollingService(this._ref);
  final Ref _ref;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(minutes: 2);
  final bool _isFetching = false;

  /// Start polling for tasks updates
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (!_isFetching) {
        _fetchTasksSilently();
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
  }

  /// Fetch tasks silently without showing loading state
  Future<void> _fetchTasksSilently() async {
    // Respect concurrency control
    if (_isFetching) {
      return;
    }

    final connectionService = _ref.read(tasksConnectionServiceProvider);
    final isConnected = connectionService.isConnected();
    
    if (!isConnected) {
      final service = connectionService.getService();
      if (service == null) {
        return; // No service available, skip silently
      }
    }

    // For now, just check connectivity - the actual polling will be handled by the provider
    // This service is mainly for managing the timer
  }
}

/// Provider for TaskPollingService
final taskPollingServiceProvider = Provider<TaskPollingService>((ref) {
  return TaskPollingService(ref);
});
