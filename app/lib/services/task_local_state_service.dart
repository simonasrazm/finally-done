import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;

/// Service responsible for managing local state updates without full API calls
class TaskLocalStateService {
  /// Add a task to the local state
  List<google_tasks.Task> addTaskLocally(List<google_tasks.Task> currentTasks, google_tasks.Task newTask) {
    final updatedTasks = List<google_tasks.Task>.from(currentTasks);
    updatedTasks.add(newTask);
    return updatedTasks;
  }

  /// Remove a task from the local state
  List<google_tasks.Task> removeTaskLocally(List<google_tasks.Task> currentTasks, String taskId) {
    final updatedTasks = List<google_tasks.Task>.from(currentTasks);
    final taskIndex = updatedTasks.indexWhere((task) => task.id == taskId);
    
    if (taskIndex != -1) {
      updatedTasks.removeAt(taskIndex);
    }
    
    return updatedTasks;
  }

  /// Update task status in the local state
  List<google_tasks.Task> updateTaskStatusLocally(
    List<google_tasks.Task> currentTasks,
    String taskId,
    String newStatus,
  ) {
    final updatedTasks = List<google_tasks.Task>.from(currentTasks);
    final taskIndex = updatedTasks.indexWhere((task) => task.id == taskId);
    
    if (taskIndex != -1) {
      // Update the task with new status
      final updatedTask = google_tasks.Task(
        id: updatedTasks[taskIndex].id,
        title: updatedTasks[taskIndex].title,
        notes: updatedTasks[taskIndex].notes,
        status: newStatus,
        due: updatedTasks[taskIndex].due,
        completed: newStatus == 'completed' ? DateTime.now().toIso8601String() : null,
        updated: DateTime.now().toIso8601String(),
        selfLink: updatedTasks[taskIndex].selfLink,
        position: updatedTasks[taskIndex].position,
        parent: updatedTasks[taskIndex].parent,
        links: updatedTasks[taskIndex].links,
        etag: updatedTasks[taskIndex].etag,
        kind: updatedTasks[taskIndex].kind,
      );
      
      updatedTasks[taskIndex] = updatedTask;
    }
    
    return updatedTasks;
  }

  /// Compare two task lists to avoid unnecessary updates
  bool areTasksEqual(List<google_tasks.Task> tasks1, List<google_tasks.Task> tasks2) {
    if (tasks1.length != tasks2.length) {
      return false;
    }
    
    for (int i = 0; i < tasks1.length; i++) {
      final task1 = tasks1[i];
      final task2 = tasks2[i];
      
      // Compare key fields that affect UI
      if (task1.id != task2.id ||
          task1.title != task2.title ||
          task1.status != task2.status ||
          task1.updated != task2.updated) {
        return false;
      }
    }
    return true;
  }
}

/// Provider for TaskLocalStateService
final taskLocalStateServiceProvider = Provider<TaskLocalStateService>((ref) {
  return TaskLocalStateService();
});
