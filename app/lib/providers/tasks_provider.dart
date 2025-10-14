import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../services/integrations/integration_manager.dart';
import '../services/integrations/google_integration_provider.dart';
import '../services/google_tasks_service.dart';
import '../services/connectors/connector_manager.dart';
import '../utils/logger.dart';

/// State for tasks management
class TasksState {
  final List<google_tasks.Task> tasks;
  final String? selectedTaskListId;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;
  final bool isConnected;

  const TasksState({
    this.tasks = const [],
    this.selectedTaskListId,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
    this.isConnected = false,
  });

  TasksState copyWith({
    List<google_tasks.Task>? tasks,
    String? selectedTaskListId,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    bool? isConnected,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      selectedTaskListId: selectedTaskListId ?? this.selectedTaskListId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
  final Ref _ref;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);

  TasksNotifier(this._ref) : super(TasksState(lastUpdated: DateTime.now())) {
    print('🔵 TASKS PROVIDER: Constructor called');
    // Defer heavy initialization to avoid blocking UI - use post frame callback for lightest load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔵 TASKS PROVIDER: Starting initialization');
      _startPolling();
      _checkInitialConnection();
      
      // Listen to integration manager state changes
      _ref.listen(integrationManagerProvider, (previous, next) {
        final googleState = next['google'];
        if (googleState != null && googleState.isAuthenticated && !state.isConnected) {
          print('🔵 TASKS PROVIDER: Google state changed, rechecking connection...');
          _checkInitialConnection();
        }
      });
    });
  }

  /// Check initial connection status
  void _checkInitialConnection() {
    print('🔵 TASKS PROVIDER: _checkInitialConnection called');
    final isConnected = _isGoogleTasksConnected();
    print('🔵 TASKS PROVIDER: Connection check result: $isConnected');
    Logger.info('Tasks provider checking connection: $isConnected', tag: 'TASKS');
    state = state.copyWith(isConnected: isConnected);
    if (isConnected) {
      print('🔵 TASKS PROVIDER: Google Tasks connected, fetching tasks...');
      Logger.info('Google Tasks connected, fetching tasks...', tag: 'TASKS');
      _fetchTasks();
    } else {
      print('🔵 TASKS PROVIDER: Google Tasks not connected');
      Logger.info('Google Tasks not connected', tag: 'TASKS');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Start polling for tasks updates
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (state.isConnected && !state.isLoading) {
        _fetchTasks();
      }
    });
  }

  /// Check if Google Tasks is connected
  bool _isGoogleTasksConnected() {
    final manager = _ref.read(integrationManagerProvider.notifier);
    return manager.isServiceConnected('google', 'tasks');
  }

  /// Fetch tasks from Google
  Future<void> _fetchTasks() async {
    if (!_isGoogleTasksConnected()) {
      state = state.copyWith(
        isConnected: false,
        error: 'Google Tasks not connected',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final tasksService = _ref.read(googleTasksServiceProvider);
      print('🔵 TASKS PROVIDER: Got tasks service: ${tasksService != null}');
      
      if (tasksService == null) {
        throw Exception('Google Tasks service not available');
      }
      
      // Get task list ID - use selected one or get default
      String taskListId = state.selectedTaskListId ?? '';
      if (taskListId.isEmpty) {
        print('🔵 TASKS PROVIDER: No task list selected, getting default task list...');
        try {
          final taskLists = await tasksService.getTaskLists();
          print('🔵 TASKS PROVIDER: Got ${taskLists.length} task lists');
          if (taskLists.isNotEmpty) {
            taskListId = taskLists.first.id!;
            print('🔵 TASKS PROVIDER: Using default task list: $taskListId');
            state = state.copyWith(selectedTaskListId: taskListId);
          } else {
            throw Exception('No task lists found');
          }
        } catch (e) {
          print('🔵 TASKS PROVIDER: Error getting task lists: $e');
          throw Exception('Failed to get task lists: $e');
        }
      }
      
      print('🔵 TASKS PROVIDER: Fetching tasks from task list: $taskListId');
      final tasks = await tasksService.getTasks(taskListId);
      print('🔵 TASKS PROVIDER: Got ${tasks.length} tasks');
      
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        lastUpdated: DateTime.now(),
        isConnected: true,
        error: null,
      );

      Logger.info('Fetched ${tasks.length} tasks from task list: $taskListId', tag: 'TASKS');
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch tasks', tag: 'TASKS', error: e, stackTrace: stackTrace);
      
      // If it's an authentication error, try to refresh the connection
      if (e.toString().contains('invalid_token') || e.toString().contains('Authentication expired')) {
        print('🔵 TASKS PROVIDER: Authentication error detected, attempting to refresh connection...');
        Logger.info('Authentication error detected, attempting to refresh connection...', tag: 'TASKS');
        _checkInitialConnection();
        return;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isConnected: _isGoogleTasksConnected(),
      );
    }
  }

  /// Fetch tasks (public method)
  Future<void> fetchTasks() async {
    await _fetchTasks();
  }

  /// Create a new task
  Future<void> createTask(String title, {String? taskListId}) async {
    if (!_isGoogleTasksConnected()) {
      state = state.copyWith(error: 'Google Tasks not connected');
      return;
    }

    try {
      final tasksService = _ref.read(googleTasksServiceProvider);
      final taskListIdToUse = taskListId ?? state.selectedTaskListId;
      
      if (taskListIdToUse == null) {
        state = state.copyWith(error: 'No task list selected');
        return;
      }

      await tasksService.createTask(taskListIdToUse, title);
      
      // Refresh tasks after creating
      await _fetchTasks();
      
      Logger.info('Created task: $title', tag: 'TASKS');
    } catch (e, stackTrace) {
      Logger.error('Failed to create task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to create task: ${e.toString()}');
    }
  }

  /// Complete a task
  Future<void> completeTask(String taskId) async {
    if (!_isGoogleTasksConnected()) {
      state = state.copyWith(error: 'Google Tasks not connected');
      return;
    }

    try {
      final tasksService = _ref.read(googleTasksServiceProvider);
      await tasksService.completeTask(state.selectedTaskListId!, taskId);
      
      // Refresh tasks after completing
      await _fetchTasks();
      
      Logger.info('Completed task: $taskId', tag: 'TASKS');
    } catch (e, stackTrace) {
      Logger.error('Failed to complete task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to complete task: ${e.toString()}');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    if (!_isGoogleTasksConnected()) {
      state = state.copyWith(error: 'Google Tasks not connected');
      return;
    }

    try {
      final tasksService = _ref.read(googleTasksServiceProvider);
      await tasksService.deleteTask(state.selectedTaskListId!, taskId);
      
      // Refresh tasks after deleting
      await _fetchTasks();
      
      Logger.info('Deleted task: $taskId', tag: 'TASKS');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to delete task: ${e.toString()}');
    }
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
    state = state.copyWith(error: null);
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
    return await tasksService.getTaskLists();
  } catch (e) {
    Logger.error('Failed to fetch task lists', tag: 'TASKS', error: e);
    return [];
  }
});

/// Provider for default task list
final defaultTaskListProvider = FutureProvider<google_tasks.TaskList?>((ref) async {
  final taskLists = await ref.watch(taskListsProvider.future);
  return taskLists.isNotEmpty ? taskLists.first : null;
});

/// Provider for Google Tasks service
final googleTasksServiceProvider = Provider<GoogleTasksService>((ref) {
  final manager = ref.read(integrationManagerProvider.notifier);
  final connectorManager = ref.read(connectorManagerProvider.notifier);
  final googleProvider = manager.getProvider('google') as GoogleIntegrationProvider?;
  
  if (googleProvider?.authClient == null) {
    throw Exception('Google not authenticated');
  }
  
    return GoogleTasksService(manager, connectorManager, googleProvider!.authClient!);
});