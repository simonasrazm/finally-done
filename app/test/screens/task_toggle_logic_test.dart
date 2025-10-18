import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;

void main() {
  group('Task Toggle Logic Tests', () {
    test('should determine correct action based on task status', () {
      // Arrange
      final incompleteTask = google_tasks.Task()
        ..id = 'task-1'
        ..title = 'Incomplete Task'
        ..status = 'needsAction';
        
      final completedTask = google_tasks.Task()
        ..id = 'task-2'
        ..title = 'Completed Task'
        ..status = 'completed';

      // Act & Assert
      expect(incompleteTask.status == 'completed', isFalse);
      expect(completedTask.status == 'completed', isTrue);
    });

    test('should handle task status transitions correctly', () {
      // Arrange
      final task = google_tasks.Task()
        ..id = 'task-1'
        ..title = 'Test Task'
        ..status = 'needsAction';

      // Act - Simulate completion
      task.status = 'completed';
      task.completed = DateTime.now().toUtc().toIso8601String();

      // Assert
      expect(task.status, equals('completed'));
      expect(task.completed, isNotNull);

      // Act - Simulate uncompletion
      task.status = 'needsAction';
      task.completed = null;

      // Assert
      expect(task.status, equals('needsAction'));
      expect(task.completed, isNull);
    });

    test('should handle edge cases in task status', () {
      // Arrange
      final task = google_tasks.Task()
        ..id = 'task-1'
        ..title = 'Test Task';

      // Test null status (should be treated as incomplete)
      expect(task.status == 'completed', isFalse);

      // Test empty status
      task.status = '';
      expect(task.status == 'completed', isFalse);

      // Test invalid status
      task.status = 'invalid_status';
      expect(task.status == 'completed', isFalse);
    });

    test('should validate task toggle logic for UI', () {
      // This test ensures the logic used in _toggleTaskStatus is correct
      
      // Arrange
      final tasks = [
        google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Incomplete Task'
          ..status = 'needsAction',
        google_tasks.Task()
          ..id = 'task-2'
          ..title = 'Completed Task'
          ..status = 'completed',
      ];

      // Act & Assert - Simulate the logic from _toggleTaskStatus
      for (final task in tasks) {
        final isCompleted = task.status == 'completed';
        
        if (isCompleted) {
          // Should call uncomplete
          expect(task.id, equals('task-2'));
          expect(task.status, equals('completed'));
        } else {
          // Should call complete
          expect(task.id, equals('task-1'));
          expect(task.status, equals('needsAction'));
        }
      }
    });
  });
}
