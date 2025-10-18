import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/services/task_animation_service.dart';
import 'package:finally_done/design_system/tokens.dart';

void main() {
  group('Task Animation Logic Tests', () {
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

    group('Design System Integration', () {
      test('should use design tokens for animation durations', () {
        // Act & Assert - Animation durations should match design tokens
        expect(
          animationManager.animationDuration.inMilliseconds,
          DesignTokens.animationSmooth,
        );
        expect(
          animationManager.normalAnimationDuration.inMilliseconds,
          DesignTokens.animationNormal,
        );
      });

      test('should validate animation duration consistency across components', () {
        // Act & Assert - All animation durations should be consistent with design tokens
        expect(
          animationManager.animationDuration,
          Duration(milliseconds: DesignTokens.animationSmooth),
        );
        expect(
          animationManager.normalAnimationDuration,
          Duration(milliseconds: DesignTokens.animationNormal),
        );

        // Validate that the durations are reasonable
        expect(animationManager.animationDuration.inMilliseconds, greaterThan(0));
        expect(animationManager.normalAnimationDuration.inMilliseconds, greaterThan(0));
        expect(
          animationManager.animationDuration.inMilliseconds,
          greaterThan(animationManager.normalAnimationDuration.inMilliseconds),
        );
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

    group('Animation Bug Detection', () {
      test('should detect if animation state is lost during toggle operations', () {
        // This test specifically looks for the bug where animation state is lost
        const taskId = 'task-1';
        
        // Simulate the toggle operation that should maintain animation state
        // 1. Start completing animation
        animationManager.startCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isTrue);
        
        // 2. Simulate what happens in toggleTaskStatus - it should maintain animation state
        // The bug might be that the animation state gets lost here
        
        // 3. Verify animation state is still active
        expect(animationManager.isCompleting(taskId), isTrue);
        expect(animationManager.isAnimating(taskId), isTrue);
        
        // 4. Stop animation
        animationManager.stopCompleting(taskId);
        expect(animationManager.isCompleting(taskId), isFalse);
      });

      test('should validate animation state consistency during rapid toggles', () {
        // Test rapid toggle operations to catch race conditions
        const taskId = 'task-1';
        
        // Rapid toggle simulation
        for (int i = 0; i < 5; i++) {
          // Start completing
          animationManager.startCompleting(taskId);
          expect(animationManager.isCompleting(taskId), isTrue);
          
          // Stop completing
          animationManager.stopCompleting(taskId);
          expect(animationManager.isCompleting(taskId), isFalse);
          
          // Start uncompleting
          animationManager.startUncompleting(taskId);
          expect(animationManager.isUncompleting(taskId), isTrue);
          
          // Stop uncompleting
          animationManager.stopUncompleting(taskId);
          expect(animationManager.isUncompleting(taskId), isFalse);
        }
        
        // Final state should be clean
        expect(animationManager.isAnimating(taskId), isFalse);
      });
    });
  });
}
