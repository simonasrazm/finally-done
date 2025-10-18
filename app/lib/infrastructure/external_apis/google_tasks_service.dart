import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis_auth/auth_io.dart';
import '../../utils/sentry_performance.dart';
import '../../integration_manager.dart';
import '../../google_integration_provider.dart';
import '../../connectors/connector_manager.dart';
import '../../connectors/google_tasks_connector.dart';

/// Google Tasks Service
/// Handles task management through Google Tasks API using the new connector architecture
class GoogleTasksService {
  final IntegrationManager _integrationManager;
  final ConnectorManager _connectorManager;
  AuthClient _authClient;
  late tasks.TasksApi _tasksApi;

  GoogleTasksService(this._integrationManager, this._connectorManager, this._authClient) {
    _tasksApi = tasks.TasksApi(_authClient);
  }

  /// Get all task lists using the new connector architecture
  Future<List<tasks.TaskList>> getTaskLists() async {
    return await sentryPerformance.monitorTransaction(
      PerformanceTransactions.apiTaskListsFetch,
      PerformanceOps.apiCall,
      () async {
        // Try to use the new connector architecture first
        final connector = _connectorManager.getConnector<GoogleTasksConnector>('google_tasks');
        if (connector != null && connector.isInitialized) {
          return await sentryPerformance.monitorOperation(
            PerformanceTransactions.apiTaskListsFetch,
            'connector_get_task_lists',
            PerformanceOps.apiCall,
            () async => await connector.getTaskLists(),
          );
        }

        // Fallback to legacy implementation
        return await sentryPerformance.monitorOperation(
          PerformanceTransactions.apiTaskListsFetch,
          'legacy_get_task_lists',
          PerformanceOps.apiCall,
          () async => await _getTaskListsLegacy(),
        );
      },
      data: {
        'api': 'google_tasks',
        'operation': 'get_task_lists',
      },
    );
  }

  /// Legacy implementation for getting task lists
  Future<List<tasks.TaskList>> _getTaskListsLegacy() async {
    return await _retryOperation(() async {
      
      // Ensure valid authentication before making API call
      final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
      if (googleProvider != null) {
        final isValid = await googleProvider.ensureValidAuthentication();
        if (!isValid) {
          throw Exception('Authentication expired and could not be refreshed');
        }
        // Update auth client reference
        _authClient = googleProvider.authClient!;
        _tasksApi = tasks.TasksApi(_authClient);
      }
      
      final response = await _tasksApi.tasklists.list();
      final taskLists = response.items ?? [];
      
      return taskLists;
    }, 'fetch task lists');
  }

  /// Get tasks from a specific list
  Future<List<tasks.Task>> getTasks(String taskListId) async {
    return await sentryPerformance.monitorTransaction(
      PerformanceTransactions.apiTasksFetch,
      PerformanceOps.apiCall,
      () async {
        return await _retryOperation(() async {
          
          // Ensure valid authentication before making API call
          final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
          if (googleProvider != null) {
            final isValid = await sentryPerformance.monitorOperation(
              PerformanceTransactions.apiTasksFetch,
              'auth_check',
              PerformanceOps.authCheck,
              () async => await googleProvider.ensureValidAuthentication(),
            );
            if (!isValid) {
              throw Exception('Authentication expired and could not be refreshed');
            }
            // Update auth client reference
            _authClient = googleProvider.authClient!;
            _tasksApi = tasks.TasksApi(_authClient);
          }
          
          final response = await sentryPerformance.monitorOperation(
            PerformanceTransactions.apiTasksFetch,
            'api_call_list_tasks',
            PerformanceOps.apiCall,
            () async => await _tasksApi.tasks.list(taskListId),
          );
          final taskList = response.items ?? [];
          
          return taskList;
        }, 'fetch tasks from list: $taskListId');
      },
      data: {
        'api': 'google_tasks',
        'operation': 'get_tasks',
        'task_list_id': taskListId,
      },
    );
  }

  /// Create a new task
  Future<tasks.Task> createTask(String taskListId, String title, {String? notes, DateTime? due}) async {
    return await sentryPerformance.monitorTransaction(
      PerformanceTransactions.apiTasksCreate,
      PerformanceOps.apiCall,
      () async {
        try {
          
          final task = tasks.Task()
            ..title = title
            ..notes = notes
            ..due = due?.toUtc().toIso8601String();

          final createdTask = await sentryPerformance.monitorOperation(
            PerformanceTransactions.apiTasksCreate,
            'api_call_insert_task',
            PerformanceOps.apiCall,
            () async => await _tasksApi.tasks.insert(task, taskListId),
          );
          
          return createdTask;
        } catch (e) {
          rethrow;
        }
      },
      data: {
        'api': 'google_tasks',
        'operation': 'create_task',
        'task_list_id': taskListId,
        'task_title': title,
        'has_notes': notes != null,
        'has_due_date': due != null,
      },
    );
  }

  /// Update an existing task
  Future<tasks.Task> updateTask(String taskListId, String taskId, {
    String? title,
    String? notes,
    DateTime? due,
    String? status,
  }) async {
    try {
      
      // First get the current task
      final currentTask = await _tasksApi.tasks.get(taskListId, taskId);
      
      // Update only the provided fields
      if (title != null) currentTask.title = title;
      if (notes != null) currentTask.notes = notes;
      if (due != null) currentTask.due = due.toUtc().toIso8601String();
      if (status != null) currentTask.status = status;

      final updatedTask = await _tasksApi.tasks.update(currentTask, taskListId, taskId);
      
      return updatedTask;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a task as completed
  Future<tasks.Task> completeTask(String taskListId, String taskId) async {
    try {
      if (taskId.isEmpty) {
        throw ArgumentError('Task ID cannot be empty');
      }
      if (taskListId.isEmpty) {
        throw ArgumentError('Task List ID cannot be empty');
      }
      
      
      // First, get the existing task to preserve its content
      final existingTask = await _tasksApi.tasks.get(taskListId, taskId);
      
      // Update only the status and completion time, preserving all other fields
      final updatedTask = existingTask
        ..status = 'completed'
        ..completed = DateTime.now().toUtc().toIso8601String();

      final completedTask = await _tasksApi.tasks.update(updatedTask, taskListId, taskId);
      
      return completedTask;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a task as not completed (uncomplete)
  Future<tasks.Task> uncompleteTask(String taskListId, String taskId) async {
    try {
      if (taskId.isEmpty) {
        throw ArgumentError('Task ID cannot be empty');
      }
      if (taskListId.isEmpty) {
        throw ArgumentError('Task List ID cannot be empty');
      }
      
      
      // First, get the existing task to preserve its content
      final existingTask = await _tasksApi.tasks.get(taskListId, taskId);
      
      // Update only the status and clear completion time, preserving all other fields
      final updatedTask = existingTask
        ..status = 'needsAction'
        ..completed = null;

      final uncompletedTask = await _tasksApi.tasks.update(updatedTask, taskListId, taskId);
      
      return uncompletedTask;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskListId, String taskId) async {
    try {
      
      await _tasksApi.tasks.delete(taskListId, taskId);
      
    } catch (e) {
      rethrow;
    }
  }

  /// Get the default task list (usually "My Tasks")
  Future<tasks.TaskList?> getDefaultTaskList() async {
    try {
      
      final taskLists = await getTaskLists();
      if (taskLists.isEmpty) {
        return null;
      }
      
      final defaultList = taskLists.firstWhere(
        (list) => list.title == 'My Tasks' || list.title == 'Default',
        orElse: () => taskLists.first,
      );
      
      return defaultList;
    } catch (e) {
      return null;
    }
  }

  /// Search tasks by title
  Future<List<tasks.Task>> searchTasks(String taskListId, String query) async {
    try {
      
      final allTasks = await getTasks(taskListId);
      final matchingTasks = allTasks.where((task) => 
        task.title?.toLowerCase().contains(query.toLowerCase()) ?? false
      ).toList();
      
      return matchingTasks;
    } catch (e) {
      rethrow;
    }
  }

  /// Retry operation with exponential backoff for network errors
  Future<T> _retryOperation<T>(Future<T> Function() operation, String operationName) async {
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        
        // Check if this is a retryable error
        if (_isRetryableError(e) && retryCount < maxRetries) {
          final delay = Duration(milliseconds: 1000 * retryCount); // Exponential backoff
          await Future.delayed(delay);
          continue;
        }
        
        // Log the final error and rethrow
        rethrow;
      }
    }
    
    throw Exception('Max retries exceeded for $operationName');
  }

  /// Check if an error is retryable
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('oserror') ||
           errorString.contains('handshakeexception') ||
           errorString.contains('socketexception') ||
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network');
  }
}

/// Provider for Google Tasks Service with robust state handling
final googleTasksServiceProvider = Provider<GoogleTasksService?>((ref) {
  final manager = ref.watch(integrationManagerProvider.notifier);
  final connectorManager = ref.watch(connectorManagerProvider.notifier);
  final integrationState = ref.watch(integrationManagerProvider);
  
  // Get Google integration state from the watched integration state
  final googleState = integrationState['google'];
  final googleProvider = manager.getProvider('google') as GoogleIntegrationProvider?;
  
  // Only create service if we have both authentication and auth client
  if (googleState?.isAuthenticated == true && googleProvider?.authClient != null) {
    return GoogleTasksService(manager, connectorManager, googleProvider!.authClient!);
  }
  return null;
});

/// Robust provider that handles state transitions gracefully
final robustGoogleTasksServiceProvider = Provider<GoogleTasksService?>((ref) {
  // Watch the base provider
  final baseService = ref.watch(googleTasksServiceProvider);
  
  // If we have a service, return it
  if (baseService != null) {
    return baseService;
  }
  
  // If no service, check if we're in a transitional state
  final integrationState = ref.watch(integrationManagerProvider);
  final googleState = integrationState['google'];
  
  if (googleState?.isAuthenticated == true) {
    // We're authenticated but service is null - this is likely a transitional state
    // Return the last known good service if available, or null
    return null;
  }
  
  return null;
});

/// Provider for task lists
final googleTaskListsProvider = FutureProvider<List<tasks.TaskList>>((ref) async {
  final tasksService = ref.watch(googleTasksServiceProvider);
  if (tasksService == null) {
    throw Exception('Google Tasks not authenticated');
  }
  return await tasksService.getTaskLists();
});

/// Provider for default task list
final googleDefaultTaskListProvider = FutureProvider<tasks.TaskList?>((ref) async {
  final tasksService = ref.watch(googleTasksServiceProvider);
  if (tasksService == null) {
    return null;
  }
  return await tasksService.getDefaultTaskList();
});
