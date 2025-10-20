import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../../infrastructure/external_apis/google_tasks_service.dart';

/// Service for handling task business logic operations (API calls, data operations)
class TaskBusinessService {
  /// Fetch tasks from the API
  static Future<List<google_tasks.Task>> fetchTasks(
    GoogleTasksService service,
    String taskListId,
  ) async {
    return service.getTasks(taskListId);
  }

  /// Create a new task
  static Future<google_tasks.Task?> createTask(
    GoogleTasksService service,
    String taskListId,
    String title,
  ) async {
    return service.createTask(taskListId, title);
  }

  /// Complete a task
  static Future<void> completeTask(
    GoogleTasksService service,
    String taskListId,
    String taskId,
  ) async {
    await service.completeTask(taskListId, taskId);
  }

  /// Uncomplete a task
  static Future<void> uncompleteTask(
    GoogleTasksService service,
    String taskListId,
    String taskId,
  ) async {
    await service.uncompleteTask(taskListId, taskId);
  }

  /// Delete a task
  static Future<void> deleteTask(
    GoogleTasksService service,
    String taskListId,
    String taskId,
  ) async {
    await service.deleteTask(taskListId, taskId);
  }
}
