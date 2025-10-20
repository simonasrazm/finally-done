import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/external_apis/google_tasks_service.dart';

/// Service responsible for managing task list operations
class TaskListService {
  /// Get the default task list ID from the service
  Future<String> getDefaultTaskListId(GoogleTasksService service) async {
    final taskLists = await service.getTaskLists();
    if (taskLists.isNotEmpty) {
      return taskLists.first.id!;
    } else {
      throw Exception('No task lists found');
    }
  }

  /// Ensure we have a valid task list ID, getting default if needed
  Future<String> ensureTaskListId(GoogleTasksService service, String? currentId) async {
    if (currentId != null && currentId.isNotEmpty) {
      return currentId;
    }
    
    return getDefaultTaskListId(service);
  }

  /// Get all available task lists
  Future<List<dynamic>> getTaskLists(GoogleTasksService service) async {
    return service.getTaskLists();
  }
}

/// Provider for TaskListService
final taskListServiceProvider = Provider<TaskListService>((ref) {
  return TaskListService();
});
