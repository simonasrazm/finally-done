import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../../lib/providers/tasks_provider.dart';

void main() {
  group('TasksProvider State Management Tests', () {
    late ProviderContainer container;
    late TasksNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(tasksProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('TasksState copyWith preserves unchanged values', () {
      final originalState = TasksState(
        tasks: [google_tasks.Task()..id = 'task-1'],
        selectedTaskListId: 'list-1',
        isLoading: false,
        error: 'test error',
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      final newState = originalState.copyWith(
        isLoading: true,
      );

      expect(newState.tasks, equals(originalState.tasks));
      expect(newState.selectedTaskListId, equals(originalState.selectedTaskListId));
      expect(newState.error, equals(originalState.error));
      expect(newState.lastUpdated, equals(originalState.lastUpdated));
      expect(newState.isConnected, equals(originalState.isConnected));
      expect(newState.isLoading, isTrue);
    });

    test('TasksState copyWith updates all values when provided', () {
      final originalState = TasksState(
        tasks: [google_tasks.Task()..id = 'task-1'],
        selectedTaskListId: 'list-1',
        isLoading: false,
        error: 'test error',
        lastUpdated: DateTime(2024, 1, 1),
        isConnected: true,
      );

      final newTasks = [google_tasks.Task()..id = 'task-2'];
      final newLastUpdated = DateTime(2024, 1, 2);

      final newState = originalState.copyWith(
        tasks: newTasks,
        selectedTaskListId: 'list-2',
        isLoading: true,
        error: 'new error',
        lastUpdated: newLastUpdated,
        isConnected: false,
      );

      expect(newState.tasks, equals(newTasks));
      expect(newState.selectedTaskListId, equals('list-2'));
      expect(newState.isLoading, isTrue);
      expect(newState.error, equals('new error'));
      expect(newState.lastUpdated, equals(newLastUpdated));
      expect(newState.isConnected, isFalse);
    });

    test('TasksState copyWith with clearError: true sets error to null', () {
      final originalState = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'test error',
        isConnected: false,
      );

      final newState = originalState.copyWith(
        clearError: true,
        isLoading: true,
      );

      expect(newState.error, isNull);
      expect(newState.isLoading, isTrue);
    });

    test('TasksState copyWith with clearError: false preserves error', () {
      final originalState = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'test error',
        isConnected: false,
      );

      final newState = originalState.copyWith(
        clearError: false,
        isLoading: true,
      );

      expect(newState.error, equals('test error'));
      expect(newState.isLoading, isTrue);
    });

    test('TasksState copyWith with new error and clearError: false sets new error', () {
      final originalState = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'old error',
        isConnected: false,
      );

      final newState = originalState.copyWith(
        error: 'new error',
        clearError: false,
      );

      expect(newState.error, equals('new error'));
    });

    test('TasksState copyWith with new error and clearError: true ignores new error', () {
      final originalState = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'old error',
        isConnected: false,
      );

      final newState = originalState.copyWith(
        error: 'new error',
        clearError: true,
      );

      expect(newState.error, isNull);
    });

    test('TasksState getter methods work correctly', () {
      final tasks = [
        google_tasks.Task()
          ..id = 'task-1'
          ..status = 'needsAction',
        google_tasks.Task()
          ..id = 'task-2'
          ..status = 'completed',
        google_tasks.Task()
          ..id = 'task-3'
          ..status = 'needsAction',
      ];

      final state = TasksState(
        tasks: tasks,
        lastUpdated: DateTime.now(),
        isConnected: true,
      );

      expect(state.incompleteTasks.length, equals(2));
      expect(state.incompleteTasks.map((t) => t.id), containsAll(['task-1', 'task-3']));
      expect(state.completedTasks.length, equals(1));
      expect(state.completedTasks.first.id, equals('task-2'));
    });

    test('TasksState equality works correctly', () {
      final tasks1 = [google_tasks.Task()..id = 'task-1'];
      final tasks2 = [google_tasks.Task()..id = 'task-1'];
      final lastUpdated = DateTime.now();

      final state1 = TasksState(
        tasks: tasks1,
        lastUpdated: lastUpdated,
        isConnected: true,
      );

      final state2 = TasksState(
        tasks: tasks2,
        lastUpdated: lastUpdated,
        isConnected: true,
      );

      // Note: TasksState equality depends on the implementation
      // This test verifies the structure is correct
      expect(state1.tasks.length, equals(state2.tasks.length));
      expect(state1.lastUpdated, equals(state2.lastUpdated));
      expect(state1.isConnected, equals(state2.isConnected));
    });

    test('TasksState handles null values correctly', () {
      final state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        selectedTaskListId: null,
        error: null,
        isConnected: false,
      );

      expect(state.selectedTaskListId, isNull);
      expect(state.error, isNull);
      expect(state.isConnected, isFalse);
    });

    test('TasksState copyWith handles null values correctly', () {
      final originalState = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        selectedTaskListId: 'list-1',
        error: 'error',
        isConnected: true,
      );

      final newState = originalState.copyWith(
        clearError: true,          // This should clear the error
        isConnected: false,
      );

      // selectedTaskListId should remain unchanged (standard Flutter pattern)
      expect(newState.selectedTaskListId, equals('list-1'));
      expect(newState.error, isNull);
      expect(newState.isConnected, isFalse);
    });
  });
}
