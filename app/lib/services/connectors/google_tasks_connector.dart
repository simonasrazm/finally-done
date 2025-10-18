import 'dart:async';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'base_connector.dart';
import '../network/network_service.dart';

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
        
        final response = await _tasksApi.tasklists.list();
        final taskLists = response.items ?? [];
        
        return taskLists;
      },
      operationName: 'fetch task lists',
    );
  }

  /// Get tasks from a specific list
  Future<List<tasks.Task>> getTasks(String taskListId) async {
    return await executeWithAuthRefresh(
      () async {
        
        final response = await _tasksApi.tasks.list(taskListId);
        final taskList = response.items ?? [];
        
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
        
        final task = tasks.Task()
          ..title = title
          ..notes = notes
          ..due = due?.toUtc().toIso8601String();

        final createdTask = await _tasksApi.tasks.insert(task, taskListId);
        
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
        
        final updatedTask = await _tasksApi.tasks.update(task, taskListId, taskId);
        
        return updatedTask;
      },
      operationName: 'update task: $taskId',
    );
  }

  /// Complete a task
  Future<void> completeTask(String taskListId, String taskId) async {
    await executeWithAuthRefresh(
      () async {
        
        final task = tasks.Task()..status = 'completed';
        await _tasksApi.tasks.update(task, taskListId, taskId);
        
      },
      operationName: 'complete task: $taskId',
    );
  }

  /// Delete a task
  Future<void> deleteTask(String taskListId, String taskId) async {
    await executeWithAuthRefresh(
      () async {
        
        await _tasksApi.tasks.delete(taskListId, taskId);
        
      },
      operationName: 'delete task: $taskId',
    );
  }

  /// Get the default task list
  Future<tasks.TaskList?> getDefaultTaskList() async {
    return await executeWithAuthRefresh(
      () async {
        
        final taskLists = await getTaskLists();
        final defaultList = taskLists.isNotEmpty ? taskLists.first : null;
        
        if (defaultList != null) {
        } else {
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
        
        return filteredTasks;
      },
      operationName: 'search tasks with query: $query',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
