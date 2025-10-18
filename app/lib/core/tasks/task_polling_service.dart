import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasks_connection_service.dart';
import 'task_operations_service.dart';
import 'task_list_service.dart';
import '../../infrastructure/storage/task_local_state_service.dart';
import '../../utils/sentry_performance.dart';
import '../../design_system/tokens.dart';

/// Service responsible for managing background polling of tasks
class TaskPollingService {
  final Ref _ref;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(minutes: 2);
  bool _isFetching = false;

  TaskPollingService(this._ref);

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
