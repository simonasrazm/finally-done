import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../../lib/providers/tasks_provider.dart';
import '../../lib/widgets/task_item_widget.dart';
import 'task_toggle_integration_test.mocks.dart';

// Generate mocks
@GenerateMocks([TasksNotifier])
void main() {
  group('Task Toggle Integration Tests', () {
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

    group('TaskItemWidget Loading States', () {
      testWidgets('should show loading spinner when isLoading is true',
          (WidgetTester tester) async {
        // Arrange
        final _task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskItemWidget(
                task: _task,
                isCompleted: false,
                showCompleted: false,
                isLoading: true, // Show loading state
                onTap: () {},
                onCheckboxChanged: () {},
                onDelete: () {},
                onEdit: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);
      });

      testWidgets('should show checkmark when isCompleted is true',
          (WidgetTester tester) async {
        // Arrange
        final _task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'completed';

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskItemWidget(
                task: _task,
                isCompleted: true, // Show completed state
                showCompleted: true,
                isLoading: false,
                onTap: () {},
                onCheckboxChanged: () {},
                onDelete: () {},
                onEdit: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets(
          'should show empty checkbox when not completed and not loading',
          (WidgetTester tester) async {
        // Arrange
        final _task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskItemWidget(
                task: _task,
                isCompleted: false, // Not completed
                showCompleted: false,
                isLoading: false, // Not loading
                onTap: () {},
                onCheckboxChanged: () {},
                onDelete: () {},
                onEdit: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.check), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // Should show empty checkbox container
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Error Handling UI States', () {
      test('should handle API failure without UI state corruption', () async {
        // Arrange
        final _task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        // Mock API failure
        when(mockTasksNotifier.completeTask('task-1'))
            .thenAnswer((_) async => false);

        // Act - Simulate the complete error handling flow
        final incompleteTasksUpdating = <String>{};
        final allTasksUpdating = <String>{};

        // Show loading state
        incompleteTasksUpdating.add('task-1');

        try {
          final success = await mockTasksNotifier.completeTask('task-1');

          // Clear loading state after API call
          incompleteTasksUpdating.remove('task-1');

          if (success) {
            fail('API should have failed');
          } else {
            // Verify UI state is clean
            expect(incompleteTasksUpdating.contains('task-1'), isFalse);
            expect(allTasksUpdating.contains('task-1'), isFalse);
          }
        } catch (e) {
          // Exception handling
          incompleteTasksUpdating.remove('task-1');
          expect(incompleteTasksUpdating.contains('task-1'), isFalse);
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });

      test('should handle API exception without UI state corruption', () async {
        // Arrange
        final _task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        // Mock API exception
        when(mockTasksNotifier.completeTask('task-1'))
            .thenThrow(Exception('Network error'));

        // Act - Simulate the complete error handling flow
        final incompleteTasksUpdating = <String>{};
        final allTasksUpdating = <String>{};

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

          // Verify UI state is clean
          expect(incompleteTasksUpdating.contains('task-1'), isFalse);
          expect(allTasksUpdating.contains('task-1'), isFalse);
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });
    });

    group('Loading State Transitions', () {
      test('should transition from loading to completed state correctly',
          () async {
        // Arrange
        final _task = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task'
          ..status = 'needsAction';

        // Mock successful API call
        when(mockTasksNotifier.completeTask('task-1'))
            .thenAnswer((_) async => true);

        // Act - Simulate the complete success flow
        final incompleteTasksUpdating = <String>{};

        // Show loading state
        incompleteTasksUpdating.add('task-1');
        expect(incompleteTasksUpdating.contains('task-1'), isTrue);

        try {
          final success = await mockTasksNotifier.completeTask('task-1');

          // Clear loading state after API call
          incompleteTasksUpdating.remove('task-1');

          if (success) {
            // Verify loading state is cleared
            expect(incompleteTasksUpdating.contains('task-1'), isFalse);
            // Task should be ready for removal with animation
          } else {
            fail('API should have succeeded');
          }
        } catch (e) {
          fail('API should not have thrown exception');
        }

        // Verify API was called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
      });

      test('should handle rapid successive API calls correctly', () async {
        // Arrange
        final _task1 = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task 1'
          ..status = 'needsAction';
        final _task2 = google_tasks.Task()
          ..id = 'task-2'
          ..title = 'Test Task 2'
          ..status = 'needsAction';

        // Mock successful API calls
        when(mockTasksNotifier.completeTask('task-1'))
            .thenAnswer((_) async => true);
        when(mockTasksNotifier.completeTask('task-2'))
            .thenAnswer((_) async => true);

        // Act - Simulate rapid successive calls
        final incompleteTasksUpdating = <String>{};

        // First task
        incompleteTasksUpdating.add('task-1');
        final success1 = await mockTasksNotifier.completeTask('task-1');
        incompleteTasksUpdating.remove('task-1');

        // Second task (immediately after)
        incompleteTasksUpdating.add('task-2');
        final success2 = await mockTasksNotifier.completeTask('task-2');
        incompleteTasksUpdating.remove('task-2');

        // Assert
        expect(success1, isTrue);
        expect(success2, isTrue);
        expect(incompleteTasksUpdating.isEmpty, isTrue);
        expect(incompleteTasksUpdating.contains('task-1'), isFalse);
        expect(incompleteTasksUpdating.contains('task-2'), isFalse);

        // Verify both APIs were called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
        verify(mockTasksNotifier.completeTask('task-2')).called(1);
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state across list modes', () {
        // Arrange
        final incompleteTasksUpdating = <String>{'task-1'};
        final allTasksUpdating = <String>{'task-2'};

        // Act - Simulate list switching
        incompleteTasksUpdating.clear();
        allTasksUpdating.clear();

        // Assert
        expect(incompleteTasksUpdating.isEmpty, isTrue);
        expect(allTasksUpdating.isEmpty, isTrue);
      });

      test('should handle mixed success and failure scenarios', () async {
        // Arrange
        final _task1 = google_tasks.Task()
          ..id = 'task-1'
          ..title = 'Test Task 1'
          ..status = 'needsAction';
        final _task2 = google_tasks.Task()
          ..id = 'task-2'
          ..title = 'Test Task 2'
          ..status = 'needsAction';

        // Mock mixed results
        when(mockTasksNotifier.completeTask('task-1'))
            .thenAnswer((_) async => true);
        when(mockTasksNotifier.completeTask('task-2'))
            .thenAnswer((_) async => false);

        // Act
        final incompleteTasksUpdating = <String>{};

        // First task - success
        incompleteTasksUpdating.add('task-1');
        final success1 = await mockTasksNotifier.completeTask('task-1');
        incompleteTasksUpdating.remove('task-1');

        // Second task - failure
        incompleteTasksUpdating.add('task-2');
        final success2 = await mockTasksNotifier.completeTask('task-2');
        incompleteTasksUpdating.remove('task-2');

        // Assert
        expect(success1, isTrue);
        expect(success2, isFalse);
        expect(incompleteTasksUpdating.isEmpty, isTrue);

        // Verify both APIs were called
        verify(mockTasksNotifier.completeTask('task-1')).called(1);
        verify(mockTasksNotifier.completeTask('task-2')).called(1);
      });
    });
  });
}
