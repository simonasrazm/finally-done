import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../services/integrations/integration_manager.dart';
import '../services/integrations/google_integration_provider.dart';
import '../services/google_tasks_service.dart';
import '../services/connectors/connector_manager.dart';
import '../utils/logger.dart';
import '../utils/sentry_performance.dart';
import '../design_system/tokens.dart';

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
  final Ref _ref;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(minutes: 2); // Reduced from 30 seconds to 2 minutes
  bool _isFetching = false;

  TasksNotifier(this._ref) : super(TasksState(lastUpdated: DateTime.now())) {
    print('🔵 TASKS PROVIDER: Constructor called');
    // Wait for integration manager to be fully initialized
    _waitForIntegrationManager();
  }

  /// Wait for integration manager to be ready before initializing tasks
  void _waitForIntegrationManager() async {
    // Wait for integration manager to have providers
    while (_ref.read(integrationManagerProvider).isEmpty) {
      await Future.delayed(Duration(milliseconds: DesignTokens.delayPolling));
    }
    
    // Wait for Google integration to be fully initialized
    int attempts = 0;
    while (attempts < 20) { // Max 5 seconds (20 * 250ms)
      final googleState = _ref.read(integrationManagerProvider)['google'];
      if (googleState != null && googleState.isAuthenticated) {
        // Check if tasks service is connected OR if Google Tasks service is available
        final isServiceConnected = googleState.isServiceConnected('tasks');
        final tasksService = _ref.read(googleTasksServiceProvider);
        
        if (isServiceConnected || tasksService != null) {
          print('🔵 TASKS PROVIDER: Google integration fully ready - authenticated: ${googleState.isAuthenticated}, serviceConnected: $isServiceConnected, tasksService: ${tasksService != null}');
          break;
        }
      }
      await Future.delayed(Duration(milliseconds: DesignTokens.delayPolling)); // 250ms delay
      attempts++;
    }
    
    print('🔵 TASKS PROVIDER: Starting initialization');
    _startPolling();
    _checkInitialConnection();
    
    // Listen to integration manager state changes
    _ref.listen(integrationManagerProvider, (previous, next) {
      final googleState = next['google'];
      if (googleState != null && googleState.isAuthenticated) {
        // Check if tasks service connection status changed
        final wasConnected = previous?['google']?.isServiceConnected('tasks') ?? false;
        final isNowConnected = googleState.isServiceConnected('tasks');
        
        if (isNowConnected && !wasConnected) {
          print('🔵 TASKS PROVIDER: Google Tasks service just became connected, rechecking...');
          _checkInitialConnection();
        } else if (!state.isConnected && isNowConnected) {
          print('🔵 TASKS PROVIDER: Google state changed, rechecking connection...');
          _checkInitialConnection();
        }
      }
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
      // Always try to fetch tasks, regardless of connection state
      // This handles dynamic connectivity changes
      if (!state.isLoading) {
        _fetchTasksSilently(); // Use silent fetch to avoid UI flicker
      }
    });
  }

  /// Fetch tasks silently without showing loading state
  Future<void> _fetchTasksSilently() async {
    // Respect concurrency control - don't run if _fetchTasks is already running
    if (_isFetching) {
      print('🔍 TASKS PROVIDER: Silent fetch skipped - _fetchTasks already running');
      return;
    }
    
    // Always try to fetch, even if connection check fails
    // This handles cases where connectivity was restored
    final isConnected = _isGoogleTasksConnected();
    if (!isConnected) {
      // Try to get the service anyway - connectivity might have been restored
      final tasksService = _ref.read(googleTasksServiceProvider);
      if (tasksService == null) {
        return; // No service available, skip silently
      } else {
        print('🔍 TASKS PROVIDER: Silent fetch - service available despite connection check failure, proceeding');
      }
    }

    return await sentryPerformance.monitorTransaction(
      PerformanceTransactions.backgroundTasksPoll,
      PerformanceOps.backgroundPoll,
      () async {
        try {
          final tasksService = _ref.read(googleTasksServiceProvider);
          if (tasksService == null) return;

          // Get task list ID - use selected one or get default
          String taskListId = state.selectedTaskListId ?? '';
          if (taskListId.isEmpty) {
            final taskLists = await sentryPerformance.monitorOperation(
              PerformanceTransactions.backgroundTasksPoll,
              'get_task_lists',
              PerformanceOps.apiCall,
              () async => await tasksService.getTaskLists(),
            );
            if (taskLists.isNotEmpty) {
              taskListId = taskLists.first.id!;
            } else {
              return;
            }
          }

          final tasks = await sentryPerformance.monitorOperation(
            PerformanceTransactions.backgroundTasksPoll,
            'get_tasks',
            PerformanceOps.apiCall,
            () async => await tasksService.getTasks(taskListId),
          );
          
          // Only update if tasks actually changed
          if (!_areTasksEqual(tasks, state.tasks)) {
            print('🔍 TASKS PROVIDER: Tasks changed, updating state');
            state = state.copyWith(
              tasks: tasks,
              lastUpdated: DateTime.now(),
              clearError: true,
              isConnected: true, // Mark as connected since we successfully fetched tasks
            );
          } else {
            print('🔍 TASKS PROVIDER: Tasks unchanged, skipping state update');
            // Even if tasks didn't change, mark as connected since we successfully fetched
            if (!state.isConnected) {
              print('🔍 TASKS PROVIDER: Connectivity restored, updating connection state');
              state = state.copyWith(
                isConnected: true,
                clearError: true,
              );
            }
          }
        } catch (e) {
          // Silent fail for background polling, but check if this indicates connectivity loss
          print('🔴 TASKS PROVIDER: Silent fetch failed: $e');
          print('🔴 SILENT EXCEPTION TYPE: ${e.runtimeType}');
          print('🔴 SILENT EXCEPTION MESSAGE: ${e.toString()}');
          
          // If we were previously connected and now getting errors, mark as disconnected
          if (state.isConnected && _isConnectivityError(e)) {
            print('🔍 TASKS PROVIDER: Connectivity lost, updating state');
            state = state.copyWith(
              isConnected: false,
              error: 'Connection lost',
            );
          }
        }
      },
      data: {
        'operation': 'background_poll',
        'polling_type': 'silent',
        'task_list_id': state.selectedTaskListId,
      },
    );
  }

  /// Check if an error indicates connectivity issues
  bool _isConnectivityError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable') ||
           errorString.contains('socket') ||
           errorString.contains('dns');
  }

  /// Compare two task lists to avoid unnecessary updates
  bool _areTasksEqual(List<google_tasks.Task> tasks1, List<google_tasks.Task> tasks2) {
    if (tasks1.length != tasks2.length) {
      print('🔍 TASKS PROVIDER: Task count changed: ${tasks1.length} vs ${tasks2.length}');
      return false;
    }
    
    for (int i = 0; i < tasks1.length; i++) {
      final task1 = tasks1[i];
      final task2 = tasks2[i];
      
      // Compare key fields that affect UI
      if (task1.id != task2.id) {
        print('🔍 TASKS PROVIDER: Task ID changed at index $i: ${task1.id} vs ${task2.id}');
        return false;
      }
      if (task1.title != task2.title) {
        print('🔍 TASKS PROVIDER: Task title changed at index $i: ${task1.title} vs ${task2.title}');
        return false;
      }
      if (task1.status != task2.status) {
        print('🔍 TASKS PROVIDER: Task status changed at index $i: ${task1.status} vs ${task2.status}');
        return false;
      }
      if (task1.updated != task2.updated) {
        print('🔍 TASKS PROVIDER: Task updated time changed at index $i: ${task1.updated} vs ${task2.updated}');
        return false;
      }
    }
    return true;
  }

  /// Check if Google Tasks is connected
  bool _isGoogleTasksConnected() {
    try {
      // Check if integration manager notifier is available
      final manager = _ref.read(integrationManagerProvider.notifier);
      if (manager == null) {
        print('🔍 TASKS PROVIDER: Integration manager notifier is null');
        return false;
      }
      
      final isConnected = manager.isServiceConnected('google', 'tasks');
      
      // Debug logging to track the race condition
      final callTime = DateTime.now();
      final stackTrace = StackTrace.current.toString().split('\n').take(5).join('\n');
      print('🔍 TASKS PROVIDER: _isGoogleTasksConnected() called at $callTime - result: $isConnected');
      print('🔍 TASKS PROVIDER: Call stack: $stackTrace');
      
      // If already connected, return true
      if (isConnected) {
        return true;
      }
      
      // Additional check: if the Google Tasks service is available, consider it connected
      // This handles the race condition where the service is working but state hasn't updated yet
      final tasksService = _ref.read(googleTasksServiceProvider);
      if (tasksService != null) {
        print('🔍 TASKS PROVIDER: Service available but not marked as connected - treating as connected');
        return true;
      }
      
      // Final fallback: check if Google integration is authenticated (even if service not marked as connected)
      final integrationState = _ref.read(integrationManagerProvider);
      if (integrationState == null) {
        print('🔍 TASKS PROVIDER: Integration manager state is null');
        return false;
      }
      
      final googleState = integrationState['google'];
      if (googleState != null && googleState.isAuthenticated) {
        print('🔍 TASKS PROVIDER: Google authenticated but service not marked as connected - treating as connected');
        return true;
      }
      
      print('🔍 TASKS PROVIDER: All connection checks failed - not connected');
      return false;
    } catch (e) {
      print('🔴 TASKS PROVIDER: Error in _isGoogleTasksConnected(): $e');
      print('🔴 TASKS PROVIDER: Exception type: ${e.runtimeType}');
      return false;
    }
  }

  /// Fetch tasks from Google
  Future<void> _fetchTasks() async {
    final threadId = DateTime.now().millisecondsSinceEpoch;
    final instanceId = hashCode;
    
    // Prevent concurrent calls with atomic check-and-set
    print('🔵 TASKS PROVIDER: _fetchTasks called - _isFetching: $_isFetching [Thread: $threadId, Instance: $instanceId]');
    
    // Atomic check-and-set to prevent race condition
    if (_isFetching) {
      print('🔵 TASKS PROVIDER: Already fetching tasks, skipping concurrent call [Thread: $threadId, Instance: $instanceId]');
      return;
    }
    
    // Set flag immediately to prevent race condition
    _isFetching = true;
    print('🔵 TASKS PROVIDER: Set _isFetching = true [Thread: $threadId, Instance: $instanceId]');
    String? taskListId;
    
    print('🔵 TASKS PROVIDER: Starting _fetchTasks [Thread: $threadId, Instance: $instanceId]');
    
    try {
      return await sentryPerformance.monitorTransaction(
        PerformanceTransactions.apiTasksFetch,
        PerformanceOps.apiCall,
        () async {
      // Check connection status but don't fail immediately
      final isConnected = _isGoogleTasksConnected();
      print('🔍 TASKS PROVIDER: _fetchTasks - connection check result: $isConnected');
      
      if (!isConnected) {
        // Try to get the service anyway - it might be available even if state is not updated
        final tasksService = _ref.read(googleTasksServiceProvider);
        if (tasksService == null) {
          // Instead of immediately failing, try to create the service directly
          print('🔍 TASKS PROVIDER: No service from provider, attempting direct service creation [Thread: $threadId, Instance: $instanceId]');
          
          final manager = _ref.read(integrationManagerProvider.notifier);
          final connectorManager = _ref.read(connectorManagerProvider.notifier);
          final googleProvider = manager.getProvider('google') as GoogleIntegrationProvider?;
          
          if (googleProvider?.authClient != null) {
            // We have auth client, create service directly
            print('🔍 TASKS PROVIDER: Creating service directly with available auth client [Thread: $threadId, Instance: $instanceId]');
            final directService = GoogleTasksService(manager, connectorManager, googleProvider!.authClient!);
            
            // Use the direct service for the fetch
            await _performTaskFetch(directService, taskListId, threadId, instanceId);
            return;
          } else {
            print('🔴 SETTING ERROR: Google Tasks not connected (no auth client available)');
            print('🔴 SETTING ERROR STATE: Google Tasks not connected (no auth client)');
            state = state.copyWith(
              isConnected: false,
              error: 'Google Tasks not connected',
            );
            return;
          }
        } else {
          print('🔍 TASKS PROVIDER: Tasks service available despite connection check failure, proceeding [Thread: $threadId, Instance: $instanceId]');
        }
      }

      state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tasksService = _ref.read(googleTasksServiceProvider);
      print('🔵 TASKS PROVIDER: Got tasks service: ${tasksService != null}');
      
      if (tasksService == null) {
        throw Exception('Google Tasks service not available');
      }
      
      // Get task list ID - use selected one or get default
      taskListId = state.selectedTaskListId ?? '';
      if (taskListId!.isEmpty) {
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
      
      print('🔵 TASKS PROVIDER: Fetching tasks from task list: $taskListId [Thread: $threadId, Instance: $instanceId]');
      final tasks = await tasksService.getTasks(taskListId!);
      print('🔵 TASKS PROVIDER: Got ${tasks.length} tasks [Thread: $threadId, Instance: $instanceId]');
      
      print('🔵 TASKS PROVIDER: About to update state... [Thread: $threadId, Instance: $instanceId]');
      // Clear any previous error state and update with successful fetch
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        lastUpdated: DateTime.now(),
        isConnected: true,
        clearError: true, // Explicitly clear any error state
      );
      
      print('🔵 TASKS PROVIDER: State updated with ${tasks.length} tasks, error cleared [Thread: $threadId, Instance: $instanceId]');
      print('🔵 TASKS PROVIDER: State updated successfully [Thread: $threadId, Instance: $instanceId]');

      print('🔵 TASKS PROVIDER: Successfully fetched ${tasks.length} tasks from task list: $taskListId [Thread: $threadId, Instance: $instanceId]');
    } catch (e, stackTrace) {
      print('🔴 TASKS ERROR: $e [Thread: $threadId, Instance: $instanceId]');
      print('🔴 EXCEPTION TYPE: ${e.runtimeType}');
      print('🔴 EXCEPTION MESSAGE: ${e.toString()}');
      print('🔴 STACK TRACE: $stackTrace');
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
      },
      data: {
        'api': 'google_tasks',
        'operation': 'fetch_tasks',
        'task_list_id': taskListId ?? 'unknown',
      },
    );
    } finally {
      _isFetching = false;
      print('🔵 TASKS PROVIDER: Set _isFetching = false [Thread: $threadId, Instance: $instanceId]');
      print('🔵 TASKS PROVIDER: Finished _fetchTasks [Thread: $threadId, Instance: $instanceId]');
    }
  }

  /// Perform the actual task fetch with a given service
  Future<void> _performTaskFetch(GoogleTasksService tasksService, String? taskListId, int threadId, int instanceId) async {
    try {
      // Get task list ID - use selected one or get default
      String taskListIdToUse = taskListId ?? state.selectedTaskListId ?? '';
      if (taskListIdToUse.isEmpty) {
        final taskLists = await tasksService.getTaskLists();
        if (taskLists.isNotEmpty) {
          taskListIdToUse = taskLists.first.id!;
          state = state.copyWith(selectedTaskListId: taskListIdToUse);
        } else {
          throw Exception('No task lists available');
        }
      }

      print('🔵 TASKS PROVIDER: Fetching tasks from list: $taskListIdToUse [Thread: $threadId, Instance: $instanceId]');
      
      final tasks = await tasksService.getTasks(taskListIdToUse);
      
      print('🔵 TASKS PROVIDER: Successfully fetched ${tasks.length} tasks from task list: $taskListIdToUse [Thread: $threadId, Instance: $instanceId]');
      
      // Update state with fetched tasks
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        error: null,
        isConnected: true,
        lastUpdated: DateTime.now(),
      );
      
      print('🔵 TASKS PROVIDER: State updated with ${tasks.length} tasks, error cleared [Thread: $threadId, Instance: $instanceId]');
      print('🔵 TASKS PROVIDER: State updated successfully [Thread: $threadId, Instance: $instanceId]');
      
    } catch (e) {
      print('🔴 TASKS PROVIDER: Error in _performTaskFetch: $e [Thread: $threadId, Instance: $instanceId]');
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
      if (!_isGoogleTasksConnected()) {
        print('🔴 SETTING ERROR: Google Tasks not connected (from createTask)');
        print('🔴 STACK TRACE: ${StackTrace.current}');
        state = state.copyWith(error: 'Google Tasks not connected [createTask]');
        return;
      }
    } catch (e) {
      print('🔴 TASKS PROVIDER: Error checking connection in createTask: $e');
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return;
    }

    try {
      final tasksService = _ref.read(googleTasksServiceProvider);
      if (tasksService == null) {
        state = state.copyWith(error: 'Google Tasks service not available');
        return;
      }
      
      final taskListIdToUse = taskListId ?? state.selectedTaskListId;
      
      if (taskListIdToUse == null) {
        state = state.copyWith(error: 'No task list selected');
        return;
      }

      final createdTask = await tasksService.createTask(taskListIdToUse, title);
      
      // Add task locally immediately for better UX
      if (createdTask != null) {
        _addTaskLocally(createdTask);
      } else {
        // Fallback to full refresh if we don't get the created task back
        await _fetchTasks();
      }
      
      Logger.info('Created task: $title', tag: 'TASKS');
    } catch (e, stackTrace) {
      Logger.error('Failed to create task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to create task: ${e.toString()}');
    }
  }

  /// Complete a task
  /// Returns true if successful, false if failed
  Future<bool> completeTask(String taskId) async {
    if (taskId.isEmpty) {
      state = state.copyWith(error: 'Task ID is missing');
      return false;
    }
    
    try {
      if (!_isGoogleTasksConnected()) {
        print('🔴 SETTING ERROR: Google Tasks not connected (from completeTask)');
        print('🔴 STACK TRACE: ${StackTrace.current}');
        state = state.copyWith(error: 'Google Tasks not connected [completeTask]');
        return false;
      }
    } catch (e) {
      print('🔴 TASKS PROVIDER: Error checking connection in completeTask: $e');
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return false;
    }

    final tasksService = _ref.read(googleTasksServiceProvider);
    if (tasksService == null) {
      state = state.copyWith(error: 'Google Tasks service not available');
      return false;
    }
    
    // Get task list ID - use selected one or get default
    String? taskListId = state.selectedTaskListId;
    if (taskListId == null || taskListId.isEmpty) {
      print('🔵 TASKS PROVIDER: No task list selected for complete, getting default task list...');
      try {
        final taskLists = await tasksService.getTaskLists();
        if (taskLists.isNotEmpty) {
          taskListId = taskLists.first.id!;
          print('🔵 TASKS PROVIDER: Using default task list for complete: $taskListId');
          state = state.copyWith(selectedTaskListId: taskListId);
        } else {
          throw Exception('No task lists found');
        }
      } catch (e) {
        state = state.copyWith(error: 'Failed to get task list: $e');
        return false;
      }
    }
    
    bool success = false;
    try {
      await tasksService.completeTask(taskListId, taskId);
      Logger.info('Completed task: $taskId', tag: 'TASKS');
      success = true;
    } catch (e, stackTrace) {
      Logger.error('Failed to complete task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      // Don't set error state for task completion failures - just log it
      // The task list should still be displayed
      success = false;
    }
    
    // Don't update local state immediately - let the UI handle the animation timing
    
    return success;
  }

  /// Uncomplete a task (mark as not completed)
  Future<bool> uncompleteTask(String taskId) async {
    if (taskId.isEmpty) {
      return false;
    }
    
    try {
      if (!_isGoogleTasksConnected()) {
        print('🔴 SETTING ERROR: Google Tasks not connected (from uncompleteTask)');
        print('🔴 STACK TRACE: ${StackTrace.current}');
        state = state.copyWith(error: 'Google Tasks not connected [uncompleteTask]');
        return false;
      }
    } catch (e) {
      print('🔴 TASKS PROVIDER: Error checking connection in uncompleteTask: $e');
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return false;
    }

    final tasksService = _ref.read(googleTasksServiceProvider);
    if (tasksService == null) {
      state = state.copyWith(error: 'Google Tasks service not available');
      return false;
    }
    
    // Get task list ID - use selected one or get default
    String? taskListId = state.selectedTaskListId;
    if (taskListId == null || taskListId.isEmpty) {
      print('🔵 TASKS PROVIDER: No task list selected for uncomplete, getting default task list...');
      try {
        final taskLists = await tasksService.getTaskLists();
        if (taskLists.isNotEmpty) {
          taskListId = taskLists.first.id!;
          print('🔵 TASKS PROVIDER: Using default task list for uncomplete: $taskListId');
          state = state.copyWith(selectedTaskListId: taskListId);
        } else {
          throw Exception('No task lists found');
        }
      } catch (e) {
        state = state.copyWith(error: 'Failed to get task list: $e');
        return false;
      }
    }
    
    bool success = false;
    try {
      await tasksService.uncompleteTask(taskListId, taskId);
      Logger.info('Uncompleted task: $taskId', tag: 'TASKS');
      success = true;
    } catch (e, stackTrace) {
      Logger.error('Failed to uncomplete task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      // Don't set error state for task uncompletion failures - just log it
      // The task list should still be displayed
      success = false;
    }
    
    // Don't update local state immediately - let the UI handle the animation timing
    
    return success;
  }

  /// Update task status locally without full refresh
  void updateTaskStatusLocally(String taskId, String newStatus) {
    final currentTasks = List<google_tasks.Task>.from(state.tasks);
    final taskIndex = currentTasks.indexWhere((task) => task.id == taskId);
    
    if (taskIndex != -1) {
      // Update the task with new status
      final updatedTask = google_tasks.Task(
        id: currentTasks[taskIndex].id,
        title: currentTasks[taskIndex].title,
        notes: currentTasks[taskIndex].notes,
        status: newStatus,
        due: currentTasks[taskIndex].due,
        completed: newStatus == 'completed' ? DateTime.now().toIso8601String() : null,
        updated: DateTime.now().toIso8601String(),
        selfLink: currentTasks[taskIndex].selfLink,
        position: currentTasks[taskIndex].position,
        parent: currentTasks[taskIndex].parent,
        links: currentTasks[taskIndex].links,
        etag: currentTasks[taskIndex].etag,
        kind: currentTasks[taskIndex].kind,
      );
      
      currentTasks[taskIndex] = updatedTask;
      
      // Update state with modified tasks list
      state = state.copyWith(
        tasks: currentTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
      
    } else {
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (!_isGoogleTasksConnected()) {
        print('🔴 SETTING ERROR: Google Tasks not connected (from deleteTask)');
        print('🔴 STACK TRACE: ${StackTrace.current}');
        state = state.copyWith(error: 'Google Tasks not connected [deleteTask]');
        return;
      }
    } catch (e) {
      print('🔴 TASKS PROVIDER: Error checking connection in deleteTask: $e');
      state = state.copyWith(error: 'Connection check failed: ${e.toString()}');
      return;
    }

    final tasksService = _ref.read(googleTasksServiceProvider);
    if (tasksService == null) {
      state = state.copyWith(error: 'Google Tasks service not available');
      return;
    }
    
    // Get task list ID - use selected one or get default
    String? taskListId = state.selectedTaskListId;
    if (taskListId == null || taskListId.isEmpty) {
      print('🔵 TASKS PROVIDER: No task list selected for delete, getting default task list...');
      try {
        final taskLists = await tasksService.getTaskLists();
        if (taskLists.isNotEmpty) {
          taskListId = taskLists.first.id!;
          print('🔵 TASKS PROVIDER: Using default task list for delete: $taskListId');
          state = state.copyWith(selectedTaskListId: taskListId);
        } else {
          throw Exception('No task lists found');
        }
      } catch (e) {
        state = state.copyWith(error: 'Failed to get task list: $e');
        return;
      }
    }
    
    bool success = false;
    try {
      await tasksService.deleteTask(taskListId, taskId);
      Logger.info('Deleted task: $taskId', tag: 'TASKS');
      success = true;
    } catch (e, stackTrace) {
      Logger.error('Failed to delete task', tag: 'TASKS', error: e, stackTrace: stackTrace);
      // Don't set error state for task deletion failures - just log it
      // The task list should still be displayed
      success = false;
    }
    
    // Update local state optimistically instead of full refresh
    if (success) {
      _removeTaskLocally(taskId);
    }
  }

  /// Add task locally without full refresh
  void _addTaskLocally(google_tasks.Task newTask) {
    final currentTasks = List<google_tasks.Task>.from(state.tasks);
    currentTasks.add(newTask);
    
    // Update state with modified tasks list
    state = state.copyWith(
      tasks: currentTasks,
      lastUpdated: DateTime.now(),
      clearError: true,
    );
    
  }

  /// Remove task locally without full refresh
  void _removeTaskLocally(String taskId) {
    final currentTasks = List<google_tasks.Task>.from(state.tasks);
    final taskIndex = currentTasks.indexWhere((task) => task.id == taskId);
    
    if (taskIndex != -1) {
      currentTasks.removeAt(taskIndex);
      
      // Update state with modified tasks list
      state = state.copyWith(
        tasks: currentTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
      
    } else {
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
    state = state.copyWith(clearError: true);
  }

  /// Clear error and retry fetching tasks
  Future<void> retryTasks() async {
    clearError();
    await fetchTasks();
  }

  /// Force connectivity check and recovery
  Future<void> checkConnectivity() async {
    print('🔍 TASKS PROVIDER: Manual connectivity check triggered');
    
    // Just call refreshTasks - it handles connectivity internally
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

/// Get the default task list ID
final defaultTaskListIdProvider = FutureProvider<String?>((ref) async {
  final tasksService = ref.read(googleTasksServiceProvider);
  if (tasksService == null) {
    return null;
  }
  
  final taskLists = await tasksService.getTaskLists();
  return taskLists.isNotEmpty ? taskLists.first.id : null;
});

/// Provider for Google Tasks service
// Use the existing googleTasksServiceProvider from google_tasks_service.dart
// which properly returns null when not authenticated