import 'package:flutter/material.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/date_formatter_service.dart';
import '../services/task_animation_service.dart';
import '../generated/app_localizations.dart';

/// Widget for displaying a single task item
class TaskItemWidget extends StatelessWidget {
  final google_tasks.Task task;
  final bool isCompleted;
  final bool showCompleted;
  final TaskAnimationManager animationService;
  final VoidCallback onTap;
  final VoidCallback onCheckboxChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.showCompleted,
    required this.animationService,
    required this.onTap,
    required this.onCheckboxChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animationService,
      builder: (context, child) {
        final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
        
        // Check if this task is currently being animated
        final isCompleting = animationService.isCompleting(task.id!);
        final isUncompleting = animationService.isUncompleting(task.id!);
        final isRemoving = animationService.isRemoving(task.id!);
        final isAdding = animationService.isAdding(task.id!);
        
        // Debug logging for animation state
        if (isCompleting || isUncompleting) {
          print('DEBUG: Task ${task.id} animation state - completing: $isCompleting, uncompleting: $isUncompleting, showCompleted: $showCompleted');
          print('DEBUG: Task ${task.id} transform will be: ${isCompleting && !showCompleted ? "MOVE_RIGHT_UP" : isUncompleting && !showCompleted ? "MOVE_DOWN" : "IDENTITY"}');
          print('DEBUG: Task ${task.id} ListenableBuilder rebuild triggered');
        }
    
    return AnimatedOpacity(
      opacity: isAdding ? 0.0 : 1.0, // Only fade when adding, not during completion
      duration: animationService.animationDuration,
      curve: Curves.easeInOutCubic,
      child: AnimatedContainer(
        key: ValueKey('task_container_${task.id}'),
        duration: animationService.animationDuration,
        curve: Curves.easeInOutCubic,
        height: isRemoving ? 0 : null, // Collapse height when removing
        transform: isCompleting && !showCompleted
            ? (Matrix4.translationValues(MediaQuery.of(context).size.width + DesignTokens.animationOffsetBuffer, -DesignTokens.spacing6, 0)..scale(0.95)) // Move completely off screen to the right
            : isUncompleting && !showCompleted
                ? (Matrix4.translationValues(0, DesignTokens.spacing6, 0)..scale(1.05)) // Move down and slightly grow
                : Matrix4.identity(),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing3,
              vertical: hasAdditionalContent ? DesignTokens.spacing2 : DesignTokens.spacing0,
            ),
            child: Row(
              children: [
                // Provider indicator
                _buildProviderIndicator(),
                SizedBox(width: DesignTokens.spacing2),
                
                // Checkbox
                Checkbox(
                  value: isCompleted || isCompleting, // Show checked when completed OR when completing
                  onChanged: isCompleting || isUncompleting ? null : (_) => onCheckboxChanged(), // Disable during animation
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                ),
                SizedBox(width: hasAdditionalContent ? DesignTokens.spacing2 : DesignTokens.spacing1),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title
                      Text(
                        task.title ?? 'Untitled Task',
                        style: AppTypography.body.copyWith(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted 
                              ? AppColors.getTextSecondaryColor(context) 
                              : AppColors.getTextPrimaryColor(context),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Task metadata row
                      if (hasAdditionalContent)
                        SizedBox(height: DesignTokens.spacing1),
                      if (hasAdditionalContent)
                        Row(
                          children: [
                            // Notes preview
                            if (task.notes?.isNotEmpty == true) ...[
                              Icon(
                                Icons.note_outlined,
                                size: DesignTokens.iconSm,
                                color: AppColors.getTextSecondaryColor(context),
                              ),
                              SizedBox(width: DesignTokens.spacing1),
                              Expanded(
                                child: Text(
                                  task.notes!,
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.getTextSecondaryColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            
                            // Due date
                            if (task.due != null) ...[
                              if (task.notes?.isNotEmpty == true)
                                SizedBox(width: DesignTokens.spacing2),
                              Icon(
                                Icons.schedule_outlined,
                                size: DesignTokens.iconSm,
                                color: DateFormatterService.getDueDateColor(task.due!, context),
                              ),
                              SizedBox(width: DesignTokens.spacing1),
                              Text(
                                DateFormatterService.formatDueDate(task.due!, context),
                                style: AppTypography.caption1.copyWith(
                                  color: DateFormatterService.getDueDateColor(task.due!, context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Action menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: DesignTokens.iconMd,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                  tooltip: AppLocalizations.of(context)!.moreOptions,
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        onDelete();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.primary, size: DesignTokens.iconSm),
                          SizedBox(width: DesignTokens.iconSpacing),
                          Text(
                            AppLocalizations.of(context)!.edit,
                            style: AppTypography.body.copyWith(
                              color: AppColors.getTextPrimaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error, size: DesignTokens.iconSm),
                          SizedBox(width: DesignTokens.iconSpacing),
                          Text(
                            AppLocalizations.of(context)!.delete,
                            style: AppTypography.body.copyWith(
                              color: AppColors.getTextPrimaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildProviderIndicator() {
    return Container(
      width: DesignTokens.spacing1,
      height: DesignTokens.spacing4,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
    );
  }
}
