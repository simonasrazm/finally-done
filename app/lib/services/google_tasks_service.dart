import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis_auth/auth_io.dart';
import '../utils/logger.dart';
import 'google_auth_service.dart';

/// Google Tasks Service
/// Handles task management through Google Tasks API
class GoogleTasksService {
  final AuthClient _authClient;
  final tasks.TasksApi _tasksApi;

  GoogleTasksService(this._authClient) : _tasksApi = tasks.TasksApi(_authClient);

  /// Get all task lists
  Future<List<tasks.TaskList>> getTaskLists() async {
    try {
      Logger.info('Fetching Google task lists', tag: 'GOOGLE_TASKS');
      
      final response = await _tasksApi.tasklists.list();
      final taskLists = response.items ?? [];
      
      Logger.info('Retrieved ${taskLists.length} task lists', tag: 'GOOGLE_TASKS');
      return taskLists;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch task lists', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Get tasks from a specific list
  Future<List<tasks.Task>> getTasks(String taskListId) async {
    try {
      Logger.info('Fetching tasks from list: $taskListId', tag: 'GOOGLE_TASKS');
      
      final response = await _tasksApi.tasks.list(taskListId);
      final taskList = response.items ?? [];
      
      Logger.info('Retrieved ${taskList.length} tasks', tag: 'GOOGLE_TASKS');
      return taskList;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch tasks from list: $taskListId', 
        tag: 'GOOGLE_TASKS', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
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
}

/// Provider for Google Tasks Service
final googleTasksServiceProvider = Provider<GoogleTasksService?>((ref) {
  final authService = ref.watch(googleAuthServiceProvider.notifier);
  if (authService.isAuthenticated && authService.authClient != null) {
    return GoogleTasksService(authService.authClient!);
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
