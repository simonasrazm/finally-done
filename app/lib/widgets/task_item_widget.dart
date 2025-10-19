import 'package:flutter/material.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
// Removed unused imports

/// Widget for displaying a single task item
class TaskItemWidget extends StatelessWidget {
  final google_tasks.Task task;
  final bool isCompleted;
  final bool showCompleted;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onCheckboxChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.showCompleted,
    this.isLoading = false,
    required this.onTap,
    required this.onCheckboxChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasAdditionalContent =
        task.notes?.isNotEmpty == true || task.due != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing3,
          vertical: hasAdditionalContent
              ? DesignTokens.spacing1
              : DesignTokens.spacing0,
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onCheckboxChanged,
              child: Container(
                width: DesignTokens.checkboxSize,
                height: DesignTokens.checkboxSize,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.borderRadiusSmall),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.getTextSecondaryColor(context),
                    width: DesignTokens.borderWidthMedium,
                  ),
                  color: isCompleted
                      ? AppColors.primary
                      : isLoading
                          ? AppColors.getBackgroundColor(context)
                          : AppColors.transparent,
                ),
                child: isLoading
                    ? SizedBox(
                        width: DesignTokens.iconSizeSmall,
                        height: DesignTokens.iconSizeSmall,
                        child: CircularProgressIndicator(
                          strokeWidth: DesignTokens.borderWidthMedium,
                          color: AppColors.getTextSecondaryColor(
                              context), // Theme-aware color
                        ),
                      )
                    : isCompleted
                        ? Icon(
                            Icons.check,
                            color: AppColors.getTextPrimaryColor(context),
                            size: DesignTokens.iconSizeSmall,
                          )
                        : null,
              ),
            ),
            SizedBox(width: DesignTokens.spacing3),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title
                  Text(
                    task.title ?? '',
                    style: AppTypography.body.copyWith(
                      color: isCompleted
                          ? AppColors.getTextSecondaryColor(context)
                          : AppColors.getTextPrimaryColor(context),
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),

                  // Additional content (notes, due date)
                  if (hasAdditionalContent) ...[
                    SizedBox(height: DesignTokens.spacing1),
                    if (task.notes?.isNotEmpty == true)
                      Text(
                        task.notes!,
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (task.due != null) ...[
                      if (task.notes?.isNotEmpty == true)
                        SizedBox(height: DesignTokens.spacing0),
                      _buildDueDate(context, task.due!),
                    ],
                  ],
                ],
              ),
            ),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    size: DesignTokens.iconSizeMedium,
                  ),
                  constraints: BoxConstraints(
                    minWidth: DesignTokens.touchTargetSize,
                    minHeight: DesignTokens.touchTargetSize,
                  ),
                  padding: EdgeInsets.zero,
                ),

                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.textSecondary,
                    size: DesignTokens.iconSizeMedium,
                  ),
                  constraints: BoxConstraints(
                    minWidth: DesignTokens.touchTargetSize,
                    minHeight: DesignTokens.touchTargetSize,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDate(BuildContext context, String dueDateString) {
    // Parse the due date string (assuming it's in ISO format)
    final dueDate = DateTime.tryParse(dueDateString);
    if (dueDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final daysDifference = dueDate.difference(now).inDays;

    String dueText;
    if (daysDifference == 0) {
      dueText = 'Due today';
    } else if (daysDifference == 1) {
      dueText = 'Due tomorrow';
    } else if (daysDifference == -1) {
      dueText = 'Overdue yesterday';
    } else if (daysDifference > 1) {
      dueText = 'Due in $daysDifference days';
    } else {
      dueText = 'Overdue ${-daysDifference} days ago';
    }

    return Text(
      dueText,
      style: AppTypography.footnote.copyWith(
        color: isOverdue
            ? AppColors.error
            : AppColors.getTextSecondaryColor(context),
        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
