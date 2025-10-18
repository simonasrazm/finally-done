import 'package:flutter/material.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/tokens.dart';
import '../core/tasks/task_animation_service.dart';
import 'task_item_widget.dart';

/// Widget for displaying an animated list of tasks
class AnimatedTaskListWidget extends StatelessWidget {
  final List<google_tasks.Task> tasks;
  final bool showCompleted;
  final TaskAnimationManager animationService;
  final GlobalKey<AnimatedListState> animatedListKey;
  final Function(String) onTaskTap;
  final Function(String) onCheckboxChanged;
  final Function(String) onDelete;
  final Function(google_tasks.Task) onEdit;

  const AnimatedTaskListWidget({
    super.key,
    required this.tasks,
    required this.showCompleted,
    required this.animationService,
    required this.animatedListKey,
    required this.onTaskTap,
    required this.onCheckboxChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: animatedListKey,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
      initialItemCount: tasks.length,
      itemBuilder: (context, index, animation) {
        if (index >= tasks.length) return SizedBox.shrink();
        
        final task = tasks[index];
        final isCompleted = task.status == 'completed';
        final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
        
        return Column(
          key: ValueKey('task_item_${task.id}'),
          children: [
            TaskItemWidget(
              task: task,
              isCompleted: isCompleted,
              showCompleted: showCompleted,
              animationService: animationService,
              onTap: () => onTaskTap(task.id!),
              onCheckboxChanged: () => onCheckboxChanged(task.id!),
              onDelete: () => onDelete(task.id!),
              onEdit: () => onEdit(task),
            ),
            if (index < tasks.length - 1)
              Divider(
                height: hasAdditionalContent ? DesignTokens.spacing1 : DesignTokens.spacing0,
                thickness: 0.5,
                color: AppColors.separatorOpaque.withOpacity(DesignTokens.opacity20),
                indent: DesignTokens.spacing8, // Align with content
              ),
          ],
        );
      },
    );
  }
}

/// Widget for displaying a regular list of tasks
class RegularTaskListWidget extends StatelessWidget {
  final List<google_tasks.Task> tasks;
  final bool showCompleted;
  final TaskAnimationManager animationService;
  final Function(String) onTaskTap;
  final Function(String) onCheckboxChanged;
  final Function(String) onDelete;
  final Function(google_tasks.Task) onEdit;

  const RegularTaskListWidget({
    super.key,
    required this.tasks,
    required this.showCompleted,
    required this.animationService,
    required this.onTaskTap,
    required this.onCheckboxChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isCompleted = task.status == 'completed';
        final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
        
        return Column(
          key: ValueKey('task_item_${task.id}'),
          children: [
            TaskItemWidget(
              task: task,
              isCompleted: isCompleted,
              showCompleted: showCompleted,
              animationService: animationService,
              onTap: () => onTaskTap(task.id!),
              onCheckboxChanged: () => onCheckboxChanged(task.id!),
              onDelete: () => onDelete(task.id!),
              onEdit: () => onEdit(task),
            ),
            if (index < tasks.length - 1)
              Divider(
                height: hasAdditionalContent ? DesignTokens.spacing1 : DesignTokens.spacing0,
                thickness: 0.5,
                color: AppColors.separatorOpaque.withOpacity(DesignTokens.opacity20),
                indent: DesignTokens.spacing8, // Align with content
              ),
          ],
        );
      },
    );
  }
}
