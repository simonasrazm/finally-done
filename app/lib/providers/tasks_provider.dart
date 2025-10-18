import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../integration_manager.dart';
import '../infrastructure/external_apis/google_tasks_service.dart';
import '../core/tasks/tasks_connection_service.dart';
import '../core/tasks/task_business_service.dart';
import '../core/tasks/task_list_service.dart';
import '../infrastructure/storage/task_local_state_service.dart';
import '../core/tasks/task_polling_service.dart';
import '../utils/sentry_performance.dart';
import '../design_system/tokens.dart';

/// State for tasks management
class TasksState {

  const TasksState({
    this.tasks = const [],
    this.selectedTaskListId,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
    this.isConnected = false,
  });
  final List<google_tasks.Task> tasks;
  final String? selectedTaskListId;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;
  final bool isConnected;

  TasksState copyWith({
    List<google_tasks.Task>? tasks,
    String? selectedTaskListId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
    bool? isConnected,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      selectedTaskListId: selectedTaskListId ?? this.selectedTaskListId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Get only incomplete tasks
  List<google_tasks.Task> get incompleteTasks => 
      tasks.where((task) => task.status != 'completed').toList();

  /// Get only completed tasks
  List<google_tasks.Task> get completedTasks => 
      tasks.where((task) => task.status == 'completed').toList();

  /// Get tasks due today
  List<google_tasks.Task> get tasksDueToday {
    final today = DateTime.now();
    return tasks.where((task) {
      if (task.due == null) return false;
      final dueDate = DateTime.tryParse(task.due!);
      if (dueDate == null) return false;
      return dueDate.year == today.year && 
             dueDate.month == today.month && 
             dueDate.day == today.day;
    }).toList();
  }

  /// Get overdue tasks
  List<google_tasks.Task> get overdueTasks {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.due == null || task.status == 'completed') return false;
      final dueDate = DateTime.tryParse(task.due!);
      if (dueDate == null) return false;
      return dueDate.isBefore(now);
    }).toList();
  }
}

/// Notifier for managing tasks state
class TasksNotifier extends StateNotifier<TasksState> {

  TasksNotifier(this._ref) : super(TasksState(lastUpdated: DateTime.now())) {
    _initializeServices();
    _waitForIntegrationManager();
  }
  final Ref _ref;
  late final TasksConnectionService _connectionService;
  late final TaskListService _listService;
  late final TaskLocalStateService _localStateService;
  late final TaskPollingService _pollingService;

  /// Initialize all services
  void _initializeServices() {
    _connectionService = _ref.read(tasksConnectionServiceProvider);
    _listService = _ref.read(taskListServiceProvider);
    _localStateService = _ref.read(taskLocalStateServiceProvider);
    _pollingService = _ref.read(taskPollingServiceProvider);
  }

  /// Wait for integration manager to be ready before initializing tasks
  void _waitForIntegrationManager() async {
    // Wait for integration manager to have providers
    while (_ref.read(integrationManagerProvider).isEmpty) {
      await Future.delayed(const Duration(milliseconds: DesignTokens.delayPolling));
    }
    
    // Wait for Google integration to be fully initialized
    int attempts = 0;
    while (attempts < 20) { // Max 5 seconds (20 * 250ms)
      final googleState = _ref.read(integrationManagerProvider)['google'];
      if (googleState != null && googleState.isAuthenticated) {
        final isServiceConnected = googleState.isServiceConnected('tasks');
        final tasksService = _ref.read(googleTasksServiceProvider);
        
        if (isServiceConnected || tasksService != null) {
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: DesignTokens.delayPolling));
      attempts++;
    }
    
    _startPolling();
    _checkInitialConnection();
    
    // Listen to integration manager state changes
    _ref.listen(integrationManagerProvider, (previous, next) {
      final googleState = next['google'];
      if (googleState != null && googleState.isAuthenticated) {
        final wasConnected = previous?['google']?.isServiceConnected('tasks') ?? false;
        final isNowConnected = googleState.isServiceConnected('tasks');
        
        if (isNowConnected && !wasConnected) {
          _checkInitialConnection();
        } else if (!state.isConnected && isNowConnected) {
          _checkInitialConnection();
        }
      }
    });
  }

  /// Check initial connection status
  void _checkInitialConnection() {
    final isConnected = _connectionService.isConnected();
    state = state.copyWith(isConnected: isConnected);
    if (isConnected) {
      _fetchTasks();
    }
  }

  @override
  void dispose() {
    _pollingService.dispose();
    super.dispose();
  }

  /// Start polling for tasks updates
  void _startPolling() {
    _pollingService.startPolling();
  }

  /// Fetch tasks from Google
  Future<void> _fetchTasks() async {
    try {
      return await sentryPerformance.monitorTransaction(
        PerformanceTransactions.apiTasksFetch,
        PerformanceOps.apiCall,
        () async {
          // Check connection status
          final isConnected = _connectionService.isConnected();
          
          if (!isConnected) {
            final service = await _connectionService.getOrCreateService();
            if (service == null) {
              state = state.copyWith(
                isConnected: false,
                error: 'Google Tasks not connected',
              );
              return;
            }
            await _performTaskFetch(service);
            return;
          }

          state = state.copyWith(isLoading: true, clearError: true);

          try {
            final service = await _connectionService.getOrCreateService();
            if (service == null) {
              throw Exception('Google Tasks service not available');
            }
            
            await _performTaskFetch(service);
          } catch (e, stackTrace) {
            Sentry.captureException(e, stackTrace: stackTrace);
            
            // If it's an authentication error, try to refresh the connection
            if (e.toString().contains('invalid_token') || e.toString().contains('Authentication expired')) {
              _checkInitialConnection();
              return;
            }
            
            state = state.copyWith(
              isLoading: false,
              error: e.toString(),
              isConnected: _connectionService.isConnected(),
            );
          }
        },
        data: {
          'api': 'google_tasks',
          'operation': 'fetch_tasks',
          'task_list_id': state.selectedTaskListId ?? 'unknown',
        },
      );
    } finally {
      // Reset loading state if not already set
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Perform the actual task fetch with a given service
  Future<void> _performTaskFetch(dynamic service) async {
    try {
      // Get task list ID - use selected one or get default
      final taskListId = await _listService.ensureTaskListId(service, state.selectedTaskListId);
      
      final tasks = await TaskBusinessService.fetchTasks(service, taskListId);
      
      // Update state with fetched tasks
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        error: null,
        isConnected: true,
        lastUpdated: DateTime.now(),
        selectedTaskListId: taskListId,
      );
      
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isConnected: false,
      );
    }
  }

  /// Fetch tasks (public method)
  Future<void> fetchTasks() async {
    await _fetchTasks();
  }

  /// Create a new task
  Future<void> createTask(String title, {String? taskListId}) async {
    try {
      if (!_connectionService.isConnected()) {
        state = state.copyWith(error: 'Google Tasks not connected [createTask]');
        return;
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return;
    }

    try {
      final service = await _connectionService.getOrCreateService();
      if (service == null) {
        state = state.copyWith(error: 'Google Tasks service not available');
        return;
      }
      
      final taskListIdToUse = taskListId ?? state.selectedTaskListId;
      if (taskListIdToUse == null) {
        state = state.copyWith(error: 'No task list selected');
        return;
      }

      final createdTask = await TaskBusinessService.createTask(service, taskListIdToUse, title);
      
      // Add task locally immediately for better UX
      if (createdTask != null) {
        _addTaskLocally(createdTask);
      } else {
        // Fallback to full refresh if we don't get the created task back
        await _fetchTasks();
      }
      
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to create task: ${e.toString()}');
    }
  }

  /// Complete a task
  Future<bool> completeTask(String taskId) async {
    if (taskId.isEmpty) {
      state = state.copyWith(error: 'Task ID is missing');
      return false;
    }
    
    try {
      if (!_connectionService.isConnected()) {
        state = state.copyWith(error: 'Google Tasks not connected [completeTask]');
        return false;
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return false;
    }

    final service = await _connectionService.getOrCreateService();
    if (service == null) {
      state = state.copyWith(error: 'Google Tasks service not available');
      return false;
    }
    
    // Get task list ID
    String? taskListId = state.selectedTaskListId;
    if (taskListId == null || taskListId.isEmpty) {
      try {
        taskListId = await _listService.getDefaultTaskListId(service);
        state = state.copyWith(selectedTaskListId: taskListId);
      } catch (e, stackTrace) {
        Sentry.captureException(e, stackTrace: stackTrace);
        state = state.copyWith(error: 'Failed to get task list: $e');
        return false;
      }
    }
    
    await TaskBusinessService.completeTask(service, taskListId, taskId);
    return true;
  }

  /// Uncomplete a task (mark as not completed)
  Future<bool> uncompleteTask(String taskId) async {
    if (taskId.isEmpty) {
      return false;
    }
    
    try {
      if (!_connectionService.isConnected()) {
        state = state.copyWith(error: 'Google Tasks not connected [uncompleteTask]');
        return false;
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return false;
    }

    final service = await _connectionService.getOrCreateService();
    if (service == null) {
      state = state.copyWith(error: 'Google Tasks service not available');
      return false;
    }
    
    // Get task list ID
    String? taskListId = state.selectedTaskListId;
    if (taskListId == null || taskListId.isEmpty) {
      try {
        taskListId = await _listService.getDefaultTaskListId(service);
        state = state.copyWith(selectedTaskListId: taskListId);
      } catch (e, stackTrace) {
        Sentry.captureException(e, stackTrace: stackTrace);
        state = state.copyWith(error: 'Failed to get task list: $e');
        return false;
      }
    }
    
    await TaskBusinessService.uncompleteTask(service, taskListId, taskId);
    return true;
  }

  /// Update task status locally without full refresh
  void updateTaskStatusLocally(String taskId, String newStatus) {
    final updatedTasks = _localStateService.updateTaskStatusLocally(state.tasks, taskId, newStatus);
    
    // Update state with modified tasks list
    state = state.copyWith(
      tasks: updatedTasks,
      lastUpdated: DateTime.now(),
      clearError: true,
    );
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (!_connectionService.isConnected()) {
        state = state.copyWith(error: 'Google Tasks not connected [deleteTask]');
        return;
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return;
    }

    final service = await _connectionService.getOrCreateService();
    if (service == null) {
      state = state.copyWith(error: 'Google Tasks service not available');
      return;
    }
    
    // Get task list ID
    String? taskListId = state.selectedTaskListId;
    if (taskListId == null || taskListId.isEmpty) {
      try {
        taskListId = await _listService.getDefaultTaskListId(service);
        state = state.copyWith(selectedTaskListId: taskListId);
      } catch (e, stackTrace) {
        Sentry.captureException(e, stackTrace: stackTrace);
        state = state.copyWith(error: 'Failed to get task list: $e');
        return;
      }
    }
    
    try {
      await TaskBusinessService.deleteTask(service, taskListId, taskId);
      _removeTaskLocally(taskId);
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      // Task deletion failed, but we already removed it locally
      // This is acceptable for optimistic updates
    }
  }

  /// Add task locally without full refresh
  void _addTaskLocally(google_tasks.Task newTask) {
    final updatedTasks = _localStateService.addTaskLocally(state.tasks, newTask);
    
    // Update state with modified tasks list
    state = state.copyWith(
      tasks: updatedTasks,
      lastUpdated: DateTime.now(),
      clearError: true,
    );
  }

  /// Remove task locally without full refresh
  void _removeTaskLocally(String taskId) {
    final updatedTasks = _localStateService.removeTaskLocally(state.tasks, taskId);
    
    // Update state with modified tasks list
    state = state.copyWith(
      tasks: updatedTasks,
      lastUpdated: DateTime.now(),
      clearError: true,
    );
  }

  /// Set selected task list
  void setSelectedTaskList(String? taskListId) {
    state = state.copyWith(selectedTaskListId: taskListId);
    if (state.isConnected) {
      _fetchTasks();
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear error and retry fetching tasks
  Future<void> retryTasks() async {
    clearError();
    await fetchTasks();
  }

  /// Force connectivity check and recovery
  Future<void> checkConnectivity() async {
    await refreshTasks();
  }

  /// Set selected task list (alias for setSelectedTaskList)
  void setTaskList(String? taskListId) {
    setSelectedTaskList(taskListId);
  }

  /// Refresh tasks (alias for fetchTasks)
  Future<void> refreshTasks() async {
    await fetchTasks();
  }
}

/// Provider for tasks notifier
final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(ref);
});

/// Provider for task lists
final taskListsProvider = FutureProvider<List<google_tasks.TaskList>>((ref) async {
  final manager = ref.read(integrationManagerProvider.notifier);
  
  if (!manager.isServiceConnected('google', 'tasks')) {
    return [];
  }

  try {
    final tasksService = ref.read(googleTasksServiceProvider);
    if (tasksService == null) {
      return [];
    }
    return await tasksService.getTaskLists();
  } catch (e, stackTrace) {
    Sentry.captureException(e, stackTrace: stackTrace);
    return [];
  }
});

/// Provider for default task list
final defaultTaskListProvider = FutureProvider<google_tasks.TaskList?>((ref) async {
  final taskLists = await ref.watch(taskListsProvider.future);
  return taskLists.isNotEmpty ? taskLists.first : null;
});

/// Get the default task list ID
final defaultTaskListIdProvider = FutureProvider<String?>((ref) async {
  final tasksService = ref.read(googleTasksServiceProvider);
  if (tasksService == null) {
    return null;
  }
  
  final taskLists = await tasksService.getTaskLists();
  return taskLists.isNotEmpty ? taskLists.first.id : null;
});

/// Provider for the task business service
final taskBusinessServiceProvider = Provider<TaskBusinessService>((ref) {
  return TaskBusinessService();
});
