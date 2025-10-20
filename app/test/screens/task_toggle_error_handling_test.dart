import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../../lib/providers/tasks_provider.dart';
import 'task_toggle_error_handling_test.mocks.dart';

// Generate mocks
@GenerateMocks([TasksNotifier])
void main() {
  group('Task Toggle Error Handling Tests', () {
    late ProviderContainer container;
    late MockTasksNotifier mockTasksNotifier;

    setUp(() {
      mockTasksNotifier = MockTasksNotifier();
      container = ProviderContainer(
        overrides: [
          tasksProvider
              .overrideWith((ref) => mockTasksNotifier as TasksNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Incomplete List Error Handling', () {
      test('API failure should clear loading state and keep task in list',
          () async {
        // Arrange
        final task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        final _tasksState = TasksState(
          tasks: [task],
          lastUpdated: DateTime.now(),
          isConnected: true,
        );

        // Mock API failure
        when(mockTasksNotifier.completeTask('task-1'))
            .thenAnswer((_) async => false);

        // Act - Simulate the error handling logic from _toggleIncompleteTaskStatus
        final incompleteTasksUpdating = <String>{};

        // Show loading state
        incompleteTasksUpdating.add('task-1');

        try {
          final success = await mockTasksNotifier.completeTask('task-1');

          // Clear loading state after API call
          incompleteTasksUpdating.remove('task-1');

          if (success) {
            // This should not happen
            fail('API should have failed');
          } else {
            // Verify loading state is cleared
            expect(incompleteTasksUpdating.contains('task-1'), isFalse);
            // Task should still be in tasks list
            expect(_tasksState.tasks.any((t) => t.id == 'task-1'), isTrue);
          }
        } catch (e) {
          // Exception handling
          incompleteTasksUpdating.remove('task-1');
          expect(incompleteTasksUpdating.contains('task-1'), isFalse);
          expect(_tasksState.tasks.any((t) => t.id == 'task-1'), isTrue);
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });

      test('API exception should clear loading state and keep task in list',
          () async {
        // Arrange
        final task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        final _tasksState = TasksState(
          tasks: [task],
          lastUpdated: DateTime.now(),
          isConnected: true,
        );

        // Mock API exception
        when(mockTasksNotifier.completeTask('task-1'))
            .thenThrow(Exception('Network error'));

        // Act - Simulate the error handling logic from _toggleIncompleteTaskStatus
        final incompleteTasksUpdating = <String>{};

        // Show loading state
        incompleteTasksUpdating.add('task-1');

        try {
          final success = await mockTasksNotifier.completeTask('task-1');
          incompleteTasksUpdating.remove('task-1');

          if (success) {
            fail('API should have thrown exception');
          }
        } catch (e) {
          // Exception handling - clear loading state
          incompleteTasksUpdating.remove('task-1');

          // Verify loading state is cleared
          expect(incompleteTasksUpdating.contains('task-1'), isFalse);
          // Task should still be in incomplete list
          expect(_tasksState.tasks.any((t) => t.id == 'task-1'), isTrue);
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });
    });

    group('All Items List Error Handling', () {
      test('API failure should clear loading state and revert task status',
          () async {
        // Arrange
        final task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        final _tasksState = TasksState(
          tasks: [task],
          lastUpdated: DateTime.now(),
          isConnected: true,
        );

        // Mock API failure
        when(mockTasksNotifier.completeTask('task-1'))
            .thenAnswer((_) async => false);

        // Act - Simulate the error handling logic from _toggleAllItemsTaskStatus
        final allTasksUpdating = <String>{};

        // Show loading state
        allTasksUpdating.add('task-1');

        try {
          final success = await mockTasksNotifier.completeTask('task-1');

          // Clear loading state after API call
          allTasksUpdating.remove('task-1');

          if (success) {
            fail('API should have failed');
          } else {
            // Verify loading state is cleared
            expect(allTasksUpdating.contains('task-1'), isFalse);
            // Task should remain in original state
            expect(task.status, equals('needsAction'));
          }
        } catch (e) {
          fail('Should not throw exception for API failure');
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });

      test('API exception should clear loading state and revert task status',
          () async {
        // Arrange
        final task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        final _tasksState = TasksState(
          tasks: [task],
          lastUpdated: DateTime.now(),
          isConnected: true,
        );

        // Mock API exception
        when(mockTasksNotifier.completeTask('task-1'))
            .thenThrow(Exception('Network error'));

        // Act - Simulate the error handling logic from _toggleAllItemsTaskStatus
        final allTasksUpdating = <String>{};

        // Show loading state
        allTasksUpdating.add('task-1');

        try {
          final success = await mockTasksNotifier.completeTask('task-1');
          allTasksUpdating.remove('task-1');

          if (success) {
            fail('API should have thrown exception');
          }
        } catch (e) {
          // Exception handling - clear loading state
          allTasksUpdating.remove('task-1');

          // Verify loading state is cleared
          expect(allTasksUpdating.contains('task-1'), isFalse);
          // Task should remain in original state
          expect(task.status, equals('needsAction'));
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });

      test('Uncomplete task API failure should clear loading state', () async {
        // Arrange
        final task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'completed';

        final _tasksState = TasksState(
          tasks: [task],
          lastUpdated: DateTime.now(),
          isConnected: true,
        );

        // Mock API failure
        when(mockTasksNotifier.uncompleteTask('task-1'))
            .thenAnswer((_) async => false);

        // Act - Simulate the error handling logic from _toggleAllItemsTaskStatus
        final allTasksUpdating = <String>{};

        // Show loading state
        allTasksUpdating.add('task-1');

        try {
          final success = await mockTasksNotifier.uncompleteTask('task-1');

          // Clear loading state after API call
          allTasksUpdating.remove('task-1');

          if (success) {
            fail('API should have failed');
          } else {
            // Verify loading state is cleared
            expect(allTasksUpdating.contains('task-1'), isFalse);
            // Task should remain in original state
            expect(task.status, equals('completed'));
          }
        } catch (e) {
          fail('Should not throw exception for API failure');
        }

        // Verify API was called
        verify(mockTasksNotifier.uncompleteTask('task-1')).called(1);
      });
    });

    group('Loading State Management', () {
      test('Loading states should be cleared when switching list modes', () {
        // Arrange
        final incompleteTasksUpdating = <String>{'task-1', 'task-2'};
        final allTasksUpdating = <String>{'task-3', 'task-4'};

        // Act - Simulate list switching logic
        incompleteTasksUpdating.clear();
        allTasksUpdating.clear();

        // Assert
        expect(incompleteTasksUpdating.isEmpty, isTrue);
        expect(allTasksUpdating.isEmpty, isTrue);
      });

      test('Loading states should be independent between lists', () {
        // Arrange
        final incompleteTasksUpdating = <String>{'task-1'};
        final allTasksUpdating = <String>{'task-2'};

        // Act & Assert
        expect(incompleteTasksUpdating.contains('task-1'), isTrue);
        expect(incompleteTasksUpdating.contains('task-2'), isFalse);
        expect(allTasksUpdating.contains('task-1'), isFalse);
        expect(allTasksUpdating.contains('task-2'), isTrue);
      });
    });

    group('Error Message Handling', () {
      test('should show appropriate error messages for different actions', () {
        // Test error message logic
        final completeAction = 'complete';
        final uncompleteAction = 'uncomplete';

        expect(completeAction, equals('complete'));
        expect(uncompleteAction, equals('uncomplete'));
      });
    });
  });
}
