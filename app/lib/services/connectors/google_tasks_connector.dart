import 'dart:async';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis_auth/auth_io.dart';
import 'base_connector.dart';
import '../network/network_service.dart';
import '../../utils/logger.dart';

/// Google Tasks API connector
/// Handles all Google Tasks operations with automatic retry and error handling
class GoogleTasksConnector extends BaseConnector {
  late tasks.TasksApi _tasksApi;

  GoogleTasksConnector({
    NetworkConfig? networkConfig,
  }) : super(
          connectorName: 'Google Tasks',
          networkConfig: networkConfig,
        );

  @override
  Future<void> initialize({
    required String accessToken,
    required List<String> scopes,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) async {
    await super.initialize(
      accessToken: accessToken,
      scopes: scopes,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
    );
    
    // Initialize the Tasks API
    _tasksApi = tasks.TasksApi(authClient!);
  }

  /// Get all task lists
  Future<List<tasks.TaskList>> getTaskLists() async {
    return await executeWithAuthRefresh(
      () async {
        Logger.info('Fetching Google task lists', tag: 'GOOGLE_TASKS');
        
        final response = await _tasksApi.tasklists.list();
        final taskLists = response.items ?? [];
        
        Logger.info('Retrieved ${taskLists.length} task lists', tag: 'GOOGLE_TASKS');
        return taskLists;
      },
      operationName: 'fetch task lists',
    );
  }

  /// Get tasks from a specific list
  Future<List<tasks.Task>> getTasks(String taskListId) async {
    return await executeWithAuthRefresh(
      () async {
        Logger.info('Fetching tasks from list: $taskListId', tag: 'GOOGLE_TASKS');
        
        final response = await _tasksApi.tasks.list(taskListId);
        final taskList = response.items ?? [];
        
        Logger.info('Retrieved ${taskList.length} tasks', tag: 'GOOGLE_TASKS');
        return taskList;
      },
      operationName: 'fetch tasks from list: $taskListId',
    );
  }

  /// Create a new task
  Future<tasks.Task> createTask(
    String taskListId,
    String title, {
    String? notes,
    DateTime? due,
  }) async {
    return await executeWithAuthRefresh(
      () async {
        Logger.info('Creating task: $title in list: $taskListId', tag: 'GOOGLE_TASKS');
        
        final task = tasks.Task()
          ..title = title
          ..notes = notes
          ..due = due?.toUtc().toIso8601String();

        final createdTask = await _tasksApi.tasks.insert(task, taskListId);
        
        Logger.info('Successfully created task: ${createdTask.id}', tag: 'GOOGLE_TASKS');
        return createdTask;
      },
      operationName: 'create task: $title',
    );
  }

  /// Update an existing task
  Future<tasks.Task> updateTask(
    String taskListId,
    String taskId,
    tasks.Task task,
  ) async {
    return await executeWithAuthRefresh(
      () async {
        Logger.info('Updating task: $taskId in list: $taskListId', tag: 'GOOGLE_TASKS');
        
        final updatedTask = await _tasksApi.tasks.update(task, taskListId, taskId);
        
        Logger.info('Successfully updated task: $taskId', tag: 'GOOGLE_TASKS');
        return updatedTask;
      },
      operationName: 'update task: $taskId',
    );
  }

  /// Complete a task
  Future<void> completeTask(String taskListId, String taskId) async {
    await executeWithAuthRefresh(
      () async {
        Logger.info('Completing task: $taskId in list: $taskListId', tag: 'GOOGLE_TASKS');
        
        final task = tasks.Task()..status = 'completed';
        await _tasksApi.tasks.update(task, taskListId, taskId);
        
        Logger.info('Successfully completed task: $taskId', tag: 'GOOGLE_TASKS');
      },
      operationName: 'complete task: $taskId',
    );
  }

  /// Delete a task
  Future<void> deleteTask(String taskListId, String taskId) async {
    await executeWithAuthRefresh(
      () async {
        Logger.info('Deleting task: $taskId from list: $taskListId', tag: 'GOOGLE_TASKS');
        
        await _tasksApi.tasks.delete(taskListId, taskId);
        
        Logger.info('Successfully deleted task: $taskId', tag: 'GOOGLE_TASKS');
      },
      operationName: 'delete task: $taskId',
    );
  }

  /// Get the default task list
  Future<tasks.TaskList?> getDefaultTaskList() async {
    return await executeWithAuthRefresh(
      () async {
        Logger.info('Fetching default task list', tag: 'GOOGLE_TASKS');
        
        final taskLists = await getTaskLists();
        final defaultList = taskLists.isNotEmpty ? taskLists.first : null;
        
        if (defaultList != null) {
          Logger.info('Found default task list: ${defaultList.id}', tag: 'GOOGLE_TASKS');
        } else {
          Logger.warning('No default task list found', tag: 'GOOGLE_TASKS');
        }
        
        return defaultList;
      },
      operationName: 'fetch default task list',
    );
  }

  /// Search tasks with a query
  Future<List<tasks.Task>> searchTasks(String query) async {
    return await executeWithAuthRefresh(
      () async {
        Logger.info('Searching tasks with query: $query', tag: 'GOOGLE_TASKS');
        
        final taskLists = await getTaskLists();
        final allTasks = <tasks.Task>[];
        
        for (final taskList in taskLists) {
          final tasks = await getTasks(taskList.id!);
          allTasks.addAll(tasks);
        }
        
        // Filter tasks based on query (simple text search)
        final filteredTasks = allTasks.where((task) {
          final title = task.title?.toLowerCase() ?? '';
          final notes = task.notes?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          
          return title.contains(searchQuery) || notes.contains(searchQuery);
        }).toList();
        
        Logger.info('Found ${filteredTasks.length} tasks matching query: $query', tag: 'GOOGLE_TASKS');
        return filteredTasks;
      },
      operationName: 'search tasks with query: $query',
    );
  }

  @override
  void dispose() {
    super.dispose();
    Logger.info('Disposed Google Tasks connector', tag: 'GOOGLE_TASKS');
  }
}
