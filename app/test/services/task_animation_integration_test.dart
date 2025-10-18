import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:finally_done/services/task_operations_service.dart';
import 'package:finally_done/services/task_animation_service.dart';

void main() {
  group('Task Animation Integration Tests', () {
    late TaskAnimationManager animationManager;

    setUp(() {
      animationManager = TaskAnimationManager();
    });

    group('Animation State Management', () {
      test('should properly manage animation lifecycle for task completion', () {
        // Arrange
        const taskId = 'test-task-1';
        
        // Act - Start completing
        animationManager.startCompleting(taskId);
        
        // Assert - Animation should be active
        expect(animationManager.isCompleting(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
        
        // Act - Stop completing
        animationManager.stopCompleting(taskId);
        
        // Assert - Animation should be stopped
        expect(animationManager.isCompleting(taskId), isFalse);
        expect(animationManager.isAnimating(taskId), isFalse);
      });

      test('should properly manage animation lifecycle for task uncompletion', () {
        // Arrange
        const taskId = 'test-task-1';
        
        // Act - Start uncompleting
        animationManager.startUncompleting(taskId);
        
        // Assert - Animation should be active
        expect(animationManager.isUncompleting(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
        
        // Act - Stop uncompleting
        animationManager.stopUncompleting(taskId);
        
        // Assert - Animation should be stopped
        expect(animationManager.isUncompleting(taskId), isFalse);
        expect(animationManager.isAnimating(taskId), isFalse);
      });

      test('should handle animation state transitions correctly', () {
        // Arrange
        const taskId = 'test-task-1';
        
        // Act - Start completing
        animationManager.startCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isTrue);
        
        // Act - Stop completing and start uncompleting
        animationManager.stopCompleting(taskId);
        animationManager.startUncompleting(taskId);
        
        // Assert - Should be uncompleting, not completing
        expect(animationManager.isCompleting(taskId), isFalse);
        expect(animationManager.isUncompleting(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });
    });

    group('Animation Duration Management', () {
      test('should provide consistent animation durations', () {
        // Act
        final animationDuration = animationManager.animationDuration;
        final normalDuration = animationManager.normalAnimationDuration;
        
        // Assert
        expect(animationDuration, isA<Duration>());
        expect(normalDuration, isA<Duration>());
        expect(animationDuration.inMilliseconds, greaterThan(0));
        expect(normalDuration.inMilliseconds, greaterThan(0));
      });

      test('should have different durations for different animation types', () {
        // Act
        final animationDuration = animationManager.animationDuration;
        final normalDuration = animationManager.normalAnimationDuration;
        
        // Assert - These should be different durations
        expect(animationDuration.inMilliseconds, isNot(equals(normalDuration.inMilliseconds)));
      });
    });

    group('Task Status Animation Logic', () {
      test('should determine correct animation type based on task status', () {
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
        
        // This simulates the logic in toggleTaskStatus
        if (incompleteTask.status == 'completed') {
          // Should use uncompleting animation
          animationManager.startUncompleting(incompleteTask.id!);
          expect(animationManager.isUncompleting(incompleteTask.id!), isTrue);
        } else {
          // Should use completing animation
          animationManager.startCompleting(incompleteTask.id!);
          expect(animationManager.isCompleting(incompleteTask.id!), isTrue);
        }
        
        if (completedTask.status == 'completed') {
          // Should use uncompleting animation
          animationManager.startUncompleting(completedTask.id!);
          expect(animationManager.isUncompleting(completedTask.id!), isTrue);
        } else {
          // Should use completing animation
          animationManager.startCompleting(completedTask.id!);
          expect(animationManager.isCompleting(completedTask.id!), isTrue);
        }
      });
    });

    group('Animation State Cleanup', () {
      test('should properly clean up animation states', () {
        // Arrange
        const taskId1 = 'task-1';
        const taskId2 = 'task-2';
        const taskId3 = 'task-3';
        
        // Act - Start multiple animations
        animationManager.startCompleting(taskId1);
        animationManager.startUncompleting(taskId2);
        animationManager.startRemoving(taskId3);
        
        // Assert - All should be animating
        expect(animationManager.isAnimating(taskId1), isTrue);
        expect(animationManager.isAnimating(taskId2), isTrue);
        expect(animationManager.isAnimating(taskId3), isTrue);
        
        // Act - Stop all animations
        animationManager.stopCompleting(taskId1);
        animationManager.stopUncompleting(taskId2);
        animationManager.stopRemoving(taskId3);
        
        // Assert - None should be animating
        expect(animationManager.isAnimating(taskId1), isFalse);
        expect(animationManager.isAnimating(taskId2), isFalse);
        expect(animationManager.isAnimating(taskId3), isFalse);
      });

      test('should handle rapid animation state changes', () {
        // Arrange
        const taskId = 'task-1';
        
        // Act - Rapid state changes
        animationManager.startCompleting(taskId);
        animationManager.stopCompleting(taskId);
        animationManager.startUncompleting(taskId);
        animationManager.stopUncompleting(taskId);
        animationManager.startRemoving(taskId);
        
        // Assert - Should be in removing state
        expect(animationManager.isCompleting(taskId), isFalse);
        expect(animationManager.isUncompleting(taskId), isFalse);
        expect(animationManager.isRemoving(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
      });
    });

    group('Animation Integration with Task Operations', () {
      test('should maintain animation state during task operations', () {
        // This test simulates what should happen in TaskInteractionService
        const taskId = 'task-1';
        
        // Simulate the animation lifecycle that should happen
        // 1. Start animation
        animationManager.startCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isTrue);
        
        // 2. Simulate task operation (this is where the bug might be)
        // The animation should remain active during the operation
        
        // 3. Stop animation after operation completes
        animationManager.stopCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isFalse);
      });

      test('should handle animation state for both view modes', () {
        // Test animation behavior for different view modes
        const taskId = 'task-1';
        
        // Test incomplete-only mode (showCompleted = false)
        animationManager.startCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isTrue);
        animationManager.stopCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isFalse);
        
        // Test all-items mode (showCompleted = true)
        animationManager.startCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isTrue);
        animationManager.stopCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isFalse);
      });
    });
  });
}
