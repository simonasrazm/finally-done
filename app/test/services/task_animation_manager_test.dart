import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/services/task_animation_service.dart';

void main() {
  group('TaskAnimationManager Tests', () {
    late TaskAnimationManager animationManager;

    setUp(() {
      animationManager = TaskAnimationManager();
    });

    group('Animation State Management', () {
      test('should track completing tasks', () {
        // Arrange
        const taskId = 'test-task-1';

        // Act
        animationManager.startCompleting(taskId);

        // Assert
        expect(animationManager.isCompleting(taskId), isTrue);
        expect(animationManager.completingTasks.contains(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });

      test('should track uncompleting tasks', () {
        // Arrange
        const taskId = 'test-task-1';

        // Act
        animationManager.startUncompleting(taskId);

        // Assert
        expect(animationManager.isUncompleting(taskId), isTrue);
        expect(animationManager.uncompletingTasks.contains(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });

      test('should track removing tasks', () {
        // Arrange
        const taskId = 'test-task-1';

        // Act
        animationManager.startRemoving(taskId);

        // Assert
        expect(animationManager.isRemoving(taskId), isTrue);
        expect(animationManager.removingTasks.contains(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });

      test('should track adding tasks', () {
        // Arrange
        const taskId = 'test-task-1';

        // Act
        animationManager.startAdding(taskId);

        // Assert
        expect(animationManager.isAdding(taskId), isTrue);
        expect(animationManager.addingTasks.contains(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });
    });

    group('Animation State Clearing', () {
      test('should clear completing state', () {
        // Arrange
        const taskId = 'test-task-1';
        animationManager.startCompleting(taskId);

        // Act
        animationManager.stopCompleting(taskId);

        // Assert
        expect(animationManager.isCompleting(taskId), isFalse);
        expect(animationManager.completingTasks.contains(taskId), isFalse);
        expect(animationManager.isAnimating(taskId), isFalse);
      });

      test('should clear uncompleting state', () {
        // Arrange
        const taskId = 'test-task-1';
        animationManager.startUncompleting(taskId);

        // Act
        animationManager.stopUncompleting(taskId);

        // Assert
        expect(animationManager.isUncompleting(taskId), isFalse);
        expect(animationManager.uncompletingTasks.contains(taskId), isFalse);
        expect(animationManager.isAnimating(taskId), isFalse);
      });

      test('should clear removing state', () {
        // Arrange
        const taskId = 'test-task-1';
        animationManager.startRemoving(taskId);

        // Act
        animationManager.stopRemoving(taskId);

        // Assert
        expect(animationManager.isRemoving(taskId), isFalse);
        expect(animationManager.removingTasks.contains(taskId), isFalse);
        expect(animationManager.isAnimating(taskId), isFalse);
      });

      test('should clear adding state', () {
        // Arrange
        const taskId = 'test-task-1';
        animationManager.startAdding(taskId);

        // Act
        animationManager.stopAdding(taskId);

        // Assert
        expect(animationManager.isAdding(taskId), isFalse);
        expect(animationManager.addingTasks.contains(taskId), isFalse);
        expect(animationManager.isAnimating(taskId), isFalse);
      });
    });

    group('Multiple Animation States', () {
      test('should handle multiple tasks in different states', () {
        // Arrange
        const task1 = 'test-task-1';
        const task2 = 'test-task-2';
        const task3 = 'test-task-3';
        const task4 = 'test-task-4';

        // Act
        animationManager.startCompleting(task1);
        animationManager.startUncompleting(task2);
        animationManager.startRemoving(task3);
        animationManager.startAdding(task4);

        // Assert
        expect(animationManager.isCompleting(task1), isTrue);
        expect(animationManager.isUncompleting(task2), isTrue);
        expect(animationManager.isRemoving(task3), isTrue);
        expect(animationManager.isAdding(task4), isTrue);

        expect(animationManager.completingTasks.length, equals(1));
        expect(animationManager.uncompletingTasks.length, equals(1));
        expect(animationManager.removingTasks.length, equals(1));
        expect(animationManager.addingTasks.length, equals(1));
      });

      test('should correctly identify animating tasks', () {
        // Arrange
        const animatingTask = 'test-task-1';
        const nonAnimatingTask = 'test-task-2';
        animationManager.startCompleting(animatingTask);

        // Assert
        expect(animationManager.isAnimating(animatingTask), isTrue);
        expect(animationManager.isAnimating(nonAnimatingTask), isFalse);
      });
    });

    group('Animation Durations', () {
      test('should provide animation duration', () {
        // Act
        final duration = animationManager.animationDuration;

        // Assert
        expect(duration, isA<Duration>());
        expect(duration.inMilliseconds, greaterThan(0));
      });

      test('should provide normal animation duration', () {
        // Act
        final duration = animationManager.normalAnimationDuration;

        // Assert
        expect(duration, isA<Duration>());
        expect(duration.inMilliseconds, greaterThan(0));
      });
    });

    group('State Transitions', () {
      test('should allow transitioning from one state to another', () {
        // Arrange
        const taskId = 'test-task-1';
        animationManager.startCompleting(taskId);

        // Act
        animationManager.stopCompleting(taskId);
        animationManager.startRemoving(taskId);

        // Assert
        expect(animationManager.isCompleting(taskId), isFalse);
        expect(animationManager.isRemoving(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });

      test('should handle rapid state changes', () {
        // Arrange
        const taskId = 'test-task-1';

        // Act
        animationManager.startCompleting(taskId);
        animationManager.stopCompleting(taskId);
        animationManager.startUncompleting(taskId);
        animationManager.stopUncompleting(taskId);
        animationManager.startAdding(taskId);

        // Assert
        expect(animationManager.isCompleting(taskId), isFalse);
        expect(animationManager.isUncompleting(taskId), isFalse);
        expect(animationManager.isAdding(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });
    });
  });
}
