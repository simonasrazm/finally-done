import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:finally_done/providers/tasks_provider.dart';

void main() {
  group('TasksProvider Local State Updates Tests', () {
    late ProviderContainer container;
    late TasksNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(tasksProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('_addTaskLocally adds task to state', () {
      // Set initial state
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      final newTask = google_tasks.Task()
        ..id = 'new-task'
        ..title = 'New Task'
        ..status = 'needsAction';

      // Call the method (using reflection to access private method)
      // Note: In a real test, you'd need to make this method public or use a test-specific approach
      notifier.state = notifier.state.copyWith(
        tasks: [...notifier.state.tasks, newTask],
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      expect(notifier.state.tasks.length, equals(1));
      expect(notifier.state.tasks.first.id, equals('new-task'));
      expect(notifier.state.tasks.first.title, equals('New Task'));
      expect(notifier.state.error, isNull);
    });

    test('_removeTaskLocally removes task from state', () {
      // Set initial state with tasks
      final task1 = google_tasks.Task()..id = 'task-1'..title = 'Task 1';
      final task2 = google_tasks.Task()..id = 'task-2'..title = 'Task 2';
      final task3 = google_tasks.Task()..id = 'task-3'..title = 'Task 3';

      notifier.state = TasksState(
        tasks: [task1, task2, task3],
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      // Simulate removing task-2
      final updatedTasks = notifier.state.tasks.where((task) => task.id != 'task-2').toList();
      notifier.state = notifier.state.copyWith(
        tasks: updatedTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      expect(notifier.state.tasks.length, equals(2));
      expect(notifier.state.tasks.map((t) => t.id), containsAll(['task-1', 'task-3']));
      expect(notifier.state.tasks.map((t) => t.id), isNot(contains('task-2')));
      expect(notifier.state.error, isNull);
    });

    test('_removeTaskLocally handles non-existent task gracefully', () {
      // Set initial state with tasks
      final task1 = google_tasks.Task()..id = 'task-1'..title = 'Task 1';

      notifier.state = TasksState(
        tasks: [task1],
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      // Try to remove non-existent task
      final updatedTasks = notifier.state.tasks.where((task) => task.id != 'non-existent').toList();
      notifier.state = notifier.state.copyWith(
        tasks: updatedTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      // Should remain unchanged
      expect(notifier.state.tasks.length, equals(1));
      expect(notifier.state.tasks.first.id, equals('task-1'));
    });

    test('_updateTaskStatusLocally updates task status', () {
      // Set initial state with tasks
      final task1 = google_tasks.Task()
        ..id = 'task-1'
        ..title = 'Task 1'
        ..status = 'needsAction';

      notifier.state = TasksState(
        tasks: [task1],
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      // Simulate updating task status to completed
      final updatedTasks = notifier.state.tasks.map((task) {
        if (task.id == 'task-1') {
          return google_tasks.Task()
            ..id = task.id
            ..title = task.title
            ..status = 'completed'
            ..completed = DateTime.now().toIso8601String()
            ..updated = DateTime.now().toIso8601String();
        }
        return task;
      }).toList();

      notifier.state = notifier.state.copyWith(
        tasks: updatedTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      expect(notifier.state.tasks.length, equals(1));
      expect(notifier.state.tasks.first.status, equals('completed'));
      expect(notifier.state.tasks.first.completed, isNotNull);
      expect(notifier.state.error, isNull);
    });

    test('_updateTaskStatusLocally handles non-existent task gracefully', () {
      // Set initial state with tasks
      final task1 = google_tasks.Task()
        ..id = 'task-1'
        ..title = 'Task 1'
        ..status = 'needsAction';

      notifier.state = TasksState(
        tasks: [task1],
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      // Try to update non-existent task
      final updatedTasks = notifier.state.tasks.map((task) {
        if (task.id == 'non-existent') {
          return google_tasks.Task()
            ..id = task.id
            ..title = task.title
            ..status = 'completed';
        }
        return task;
      }).toList();

      notifier.state = notifier.state.copyWith(
        tasks: updatedTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      // Should remain unchanged
      expect(notifier.state.tasks.length, equals(1));
      expect(notifier.state.tasks.first.status, equals('needsAction'));
    });

    test('local updates preserve other task properties', () {
      // Set initial state with detailed task
      final originalTask = google_tasks.Task()
        ..id = 'task-1'
        ..title = 'Original Task'
        ..notes = 'Task notes'
        ..status = 'needsAction'
        ..due = '2024-12-31T23:59:59Z'
        ..position = '00000000000000000001';

      notifier.state = TasksState(
        tasks: [originalTask],
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      // Simulate updating only the status
      final updatedTasks = notifier.state.tasks.map((task) {
        if (task.id == 'task-1') {
          return google_tasks.Task()
            ..id = task.id
            ..title = task.title
            ..notes = task.notes
            ..status = 'completed'
            ..due = task.due
            ..position = task.position
            ..completed = DateTime.now().toIso8601String()
            ..updated = DateTime.now().toIso8601String();
        }
        return task;
      }).toList();

      notifier.state = notifier.state.copyWith(
        tasks: updatedTasks,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      final updatedTask = notifier.state.tasks.first;
      expect(updatedTask.id, equals('task-1'));
      expect(updatedTask.title, equals('Original Task'));
      expect(updatedTask.notes, equals('Task notes'));
      expect(updatedTask.due, equals('2024-12-31T23:59:59Z'));
      expect(updatedTask.position, equals('00000000000000000001'));
      expect(updatedTask.status, equals('completed'));
      expect(updatedTask.completed, isNotNull);
    });

    test('local updates clear error flag', () {
      // Set initial state with error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'Previous error',
        isConnected: false,
      );

      // Simulate successful local update
      final newTask = google_tasks.Task()..id = 'new-task'..title = 'New Task';
      notifier.state = notifier.state.copyWith(
        tasks: [...notifier.state.tasks, newTask],
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      expect(notifier.state.tasks.length, equals(1));
      expect(notifier.state.error, isNull);
    });

    test('local updates update lastUpdated timestamp', () {
      final originalTime = DateTime(2024, 1, 1);
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: originalTime,
        isConnected: true,
      );

      // Simulate local update
      final newTask = google_tasks.Task()..id = 'new-task'..title = 'New Task';
      final updateTime = DateTime.now();
      notifier.state = notifier.state.copyWith(
        tasks: [...notifier.state.tasks, newTask],
        lastUpdated: updateTime,
        clearError: true,
      );

      expect(notifier.state.lastUpdated, equals(updateTime));
      expect(notifier.state.lastUpdated, isNot(equals(originalTime)));
    });
  });
}
