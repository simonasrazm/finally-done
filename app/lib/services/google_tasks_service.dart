import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis_auth/auth_io.dart';
import '../utils/logger.dart';
import 'integrations/integration_manager.dart';
import 'integrations/google_integration_provider.dart';
import 'connectors/connector_manager.dart';
import 'connectors/google_tasks_connector.dart';

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
    // Try to use the new connector architecture first
    final connector = _connectorManager.getConnector<GoogleTasksConnector>('google_tasks');
    if (connector != null && connector.isInitialized) {
      return await connector.getTaskLists();
    }

    // Fallback to legacy implementation
    return await _getTaskListsLegacy();
  }

  /// Legacy implementation for getting task lists
  Future<List<tasks.TaskList>> _getTaskListsLegacy() async {
    return await _retryOperation(() async {
      Logger.info('Fetching Google task lists (legacy)', tag: 'GOOGLE_TASKS');
      
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
      
      Logger.info('Retrieved ${taskLists.length} task lists (legacy)', tag: 'GOOGLE_TASKS');
      return taskLists;
    }, 'fetch task lists');
  }

  /// Get tasks from a specific list
  Future<List<tasks.Task>> getTasks(String taskListId) async {
    return await _retryOperation(() async {
      Logger.info('Fetching tasks from list: $taskListId', tag: 'GOOGLE_TASKS');
      
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
      
      final response = await _tasksApi.tasks.list(taskListId);
      final taskList = response.items ?? [];
      
      Logger.info('Retrieved ${taskList.length} tasks', tag: 'GOOGLE_TASKS');
      return taskList;
    }, 'fetch tasks from list: $taskListId');
  }

  /// Create a new task
  Future<tasks.Task> createTask(String taskListId, String title, {String? notes, DateTime? due}) async {
    try {
      Logger.info('Creating task: $title in list: $taskListId', tag: 'GOOGLE_TASKS');
      
      final task = tasks.Task()
        ..title = title
        ..notes = notes
        ..due = due?.toUtc().toIso8601String();

      final createdTask = await _tasksApi.tasks.insert(task, taskListId);
      
      Logger.info('Successfully created task: ${createdTask.id}', tag: 'GOOGLE_TASKS');
      return createdTask;
    } catch (e, stackTrace) {
      Logger.error('Failed to create task: $title', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Update an existing task
  Future<tasks.Task> updateTask(String taskListId, String taskId, {
    String? title,
    String? notes,
    DateTime? due,
    String? status,
  }) async {
    try {
      Logger.info('Updating task: $taskId in list: $taskListId', tag: 'GOOGLE_TASKS');
      
      // First get the current task
      final currentTask = await _tasksApi.tasks.get(taskListId, taskId);
      
      // Update only the provided fields
      if (title != null) currentTask.title = title;
      if (notes != null) currentTask.notes = notes;
      if (due != null) currentTask.due = due.toUtc().toIso8601String();
      if (status != null) currentTask.status = status;

      final updatedTask = await _tasksApi.tasks.update(currentTask, taskListId, taskId);
      
      Logger.info('Successfully updated task: $taskId', tag: 'GOOGLE_TASKS');
      return updatedTask;
    } catch (e, stackTrace) {
      Logger.error('Failed to update task: $taskId', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Mark a task as completed
  Future<tasks.Task> completeTask(String taskListId, String taskId) async {
    try {
      Logger.info('Completing task: $taskId in list: $taskListId', tag: 'GOOGLE_TASKS');
      
      final task = tasks.Task()
        ..status = 'completed'
        ..completed = DateTime.now().toUtc().toIso8601String();

      final completedTask = await _tasksApi.tasks.update(task, taskListId, taskId);
      
      Logger.info('Successfully completed task: $taskId', tag: 'GOOGLE_TASKS');
      return completedTask;
    } catch (e, stackTrace) {
      Logger.error('Failed to complete task: $taskId', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskListId, String taskId) async {
    try {
      Logger.info('Deleting task: $taskId from list: $taskListId', tag: 'GOOGLE_TASKS');
      
      await _tasksApi.tasks.delete(taskListId, taskId);
      
      Logger.info('Successfully deleted task: $taskId', tag: 'GOOGLE_TASKS');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete task: $taskId', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Get the default task list (usually "My Tasks")
  Future<tasks.TaskList?> getDefaultTaskList() async {
    try {
      Logger.info('Getting default task list', tag: 'GOOGLE_TASKS');
      
      final taskLists = await getTaskLists();
      if (taskLists.isEmpty) {
        Logger.warning('No task lists found', tag: 'GOOGLE_TASKS');
        return null;
      }
      
      final defaultList = taskLists.firstWhere(
        (list) => list.title == 'My Tasks' || list.title == 'Default',
        orElse: () => taskLists.first,
      );
      
      Logger.info('Found default task list: ${defaultList.title}', tag: 'GOOGLE_TASKS');
      return defaultList;
    } catch (e, stackTrace) {
      Logger.error('Failed to get default task list', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      return null;
    }
  }

  /// Search tasks by title
  Future<List<tasks.Task>> searchTasks(String taskListId, String query) async {
    try {
      Logger.info('Searching tasks with query: $query in list: $taskListId', tag: 'GOOGLE_TASKS');
      
      final allTasks = await getTasks(taskListId);
      final matchingTasks = allTasks.where((task) => 
        task.title?.toLowerCase().contains(query.toLowerCase()) ?? false
      ).toList();
      
      Logger.info('Found ${matchingTasks.length} matching tasks', tag: 'GOOGLE_TASKS');
      return matchingTasks;
    } catch (e, stackTrace) {
      Logger.error('Failed to search tasks with query: $query', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
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
      } catch (e, stackTrace) {
        retryCount++;
        
        // Check if this is a retryable error
        if (_isRetryableError(e) && retryCount < maxRetries) {
          final delay = Duration(milliseconds: 1000 * retryCount); // Exponential backoff
          Logger.warning('Retrying $operationName (attempt $retryCount/$maxRetries) after ${delay.inMilliseconds}ms', 
            tag: 'GOOGLE_TASKS');
          await Future.delayed(delay);
          continue;
        }
        
        // Log the final error and rethrow
        Logger.error('Failed to $operationName after $retryCount attempts', 
          tag: 'GOOGLE_TASKS', 
          error: e, 
          stackTrace: stackTrace
        );
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

/// Provider for Google Tasks Service
final googleTasksServiceProvider = Provider<GoogleTasksService?>((ref) {
  final manager = ref.watch(integrationManagerProvider.notifier);
  final connectorManager = ref.watch(connectorManagerProvider.notifier);
  final googleProvider = manager.getProvider('google') as GoogleIntegrationProvider?;
  
  print('🔵 GOOGLE TASKS SERVICE: Provider called - isAuthenticated: ${googleProvider?.state.isAuthenticated}, authClient: ${googleProvider?.authClient != null}');
  
  if (googleProvider?.state.isAuthenticated == true && googleProvider?.authClient != null) {
    print('🔵 GOOGLE TASKS SERVICE: Creating GoogleTasksService');
    return GoogleTasksService(manager, connectorManager, googleProvider!.authClient!);
  }
  
  print('🔵 GOOGLE TASKS SERVICE: Returning null - not authenticated or no auth client');
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
