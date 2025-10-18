import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../design_system/tokens.dart';
import '../providers/tasks_provider.dart';
import '../generated/app_localizations.dart';
import 'task_animation_service.dart';

/// Service for handling task user interactions (animations, feedback, UI state)
class TaskInteractionService {
  /// Complete a task with animation support
  static Future<bool> completeTask(
    String taskId,
    WidgetRef ref,
    BuildContext context,
    TaskAnimationManager animationService,
    bool showCompleted,
  ) async {
    // Start animation
    animationService.startCompleting(taskId);
    
    // Monitor task completion performance
    final transaction = Sentry.startTransaction(
      'task.complete',
      'ui.interaction',
      bindToScope: true,
    );
    
    try {
      final success = await ref.read(tasksProvider.notifier).completeTask(taskId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.taskCompleted)),
        );
        
        // Handle animation based on view mode
        if (!showCompleted) {
          // In "incomplete only" mode: animate task out, then remove with animation
          await Future.delayed(animationService.animationDuration);
          // Remove task with animated list animation
          _removeTaskWithAnimation(taskId, ref, animationService);
        } else {
          // In "all items" mode: update state immediately for checkbox animation
          ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'completed');
          await Future.delayed(animationService.normalAnimationDuration);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return success;
    } finally {
      // Always stop animation
      animationService.stopCompleting(taskId);
      
      // Finish Sentry transaction
      transaction.setData('view_mode', showCompleted ? 'all_items' : 'incomplete_only');
      transaction.setData('animation_duration', showCompleted ? 200 : 300);
      transaction.finish(status: const SpanStatus.ok());
    }
  }

  /// Uncomplete a task with animation support
  static Future<bool> uncompleteTask(
    String taskId,
    WidgetRef ref,
    BuildContext context,
    TaskAnimationManager animationService,
    bool showCompleted,
  ) async {
    // Start animation
    animationService.startUncompleting(taskId);
    
    // Monitor task uncompletion performance
    final transaction = Sentry.startTransaction(
      'task.uncomplete',
      'ui.interaction',
      bindToScope: true,
    );
    
    try {
      final success = await ref.read(tasksProvider.notifier).uncompleteTask(taskId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.taskUncompleted)),
        );
        
        // Handle animation based on view mode
        if (!showCompleted) {
          // In "incomplete only" mode: animate task in, then add with animation
          await Future.delayed(animationService.animationDuration);
          // Add task with animated list animation
          _addTaskWithAnimation(taskId, ref, animationService);
        } else {
          // In "all items" mode: update state immediately for checkbox animation
          ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'needsAction');
          await Future.delayed(animationService.normalAnimationDuration);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUncompleteTask),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return success;
    } finally {
      // Always stop animation
      animationService.stopUncompleting(taskId);
      
      // Finish Sentry transaction
      transaction.setData('view_mode', showCompleted ? 'all_items' : 'incomplete_only');
      transaction.setData('animation_duration', showCompleted ? 200 : 300);
      transaction.finish(status: const SpanStatus.ok());
    }
  }

  /// Toggle task status (complete/uncomplete) with animation support
  static Future<bool> toggleTaskStatus(
    String taskId,
    WidgetRef ref,
    BuildContext context,
    TaskAnimationManager animationService,
    bool showCompleted,
  ) async {
    final tasksState = ref.read(tasksProvider);
    final task = tasksState.tasks.firstWhere((t) => t.id == taskId);
    final isCompleted = task.status == 'completed';
    
    // Start the appropriate animation
    if (isCompleted) {
      print('DEBUG: Starting uncompleting animation for task $taskId');
      animationService.startUncompleting(taskId);
    } else {
      print('DEBUG: Starting completing animation for task $taskId');
      animationService.startCompleting(taskId);
    }
    
    // Small delay to ensure UI has time to register the animation state
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Monitor task completion performance
    final transaction = Sentry.startTransaction(
      'task.toggle',
      'ui.interaction',
      bindToScope: true,
    );
    
    try {
      bool success;
      if (isCompleted) {
        success = await ref.read(tasksProvider.notifier).uncompleteTask(taskId);
      } else {
        success = await ref.read(tasksProvider.notifier).completeTask(taskId);
      }
      
        if (success) {
          // Clear any existing snackbars and show only the latest action
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCompleted
                  ? AppLocalizations.of(context)!.taskUncompleted
                  : AppLocalizations.of(context)!.taskCompleted
              ),
              duration: const Duration(milliseconds: DesignTokens.delaySnackbarQuick), // Shorter duration for rapid actions
            ),
          );
        
        // Handle animation based on view mode
        if (!showCompleted) {
          // In "incomplete only" mode: animate task out, then remove with animation
          _removeTaskWithAnimation(taskId, ref, animationService);
        } else {
          // In "all items" mode: update state immediately for checkbox animation
          if (isCompleted) {
            ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'needsAction');
          } else {
            ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'completed');
          }
          
          // Start uncompleting animation for visual feedback
          animationService.startUncompleting(taskId);
          
          // Stop uncompleting animation after it completes
          Future.delayed(animationService.animationDuration, () {
            animationService.stopUncompleting(taskId);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isCompleted ? 'uncomplete' : 'complete'} task'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return success;
    } catch (e, stackTrace) {
      print('Error toggling task status: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete a task with confirmation dialog
  static Future<void> deleteTask(
    String taskId,
    WidgetRef ref,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTask),
        content: Text(AppLocalizations.of(context)!.deleteTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tasksProvider.notifier).deleteTask(taskId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.taskDeleted)),
      );
    }
  }

  /// Create a new task
  static Future<void> createTask(
    String taskText,
    WidgetRef ref,
    BuildContext context,
    TextEditingController controller,
  ) async {
    if (taskText.trim().isEmpty) return;

    await ref.read(tasksProvider.notifier).createTask(taskText.trim());
    
    controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.taskCreated)),
    );
  }

  /// Remove task with animation
  static void _removeTaskWithAnimation(
    String taskId,
    WidgetRef ref,
    TaskAnimationManager animationService,
  ) {
    // Start completing animation
    animationService.startCompleting(taskId);
    
    // Schedule the removal after animation completes
    Future.delayed(animationService.animationDuration, () {
      // Update the state to actually remove the task from the list
      ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'completed');
      
      // Stop completing animation
      animationService.stopCompleting(taskId);
    });
  }

  /// Add task with animation
  static void _addTaskWithAnimation(
    String taskId,
    WidgetRef ref,
    TaskAnimationManager animationService,
  ) async {
    // Update the state first to add the task back
    ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'needsAction');
    
    // Start adding animation
    animationService.startAdding(taskId);
    
    // Wait for the fade-in animation to complete
    await Future.delayed(animationService.animationDuration);
    
    // Stop adding animation
    animationService.stopAdding(taskId);
  }
}