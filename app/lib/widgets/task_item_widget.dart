import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
// Removed unused imports

/// Widget for displaying a single task item
class TaskItemWidget extends StatefulWidget {
  final google_tasks.Task task;
  final bool isCompleted;
  final bool showCompleted;
  final bool isLoading;
  final bool enableSquashAnimation;
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
    this.enableSquashAnimation = false,
    required this.onTap,
    required this.onCheckboxChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _squashController;
  late Animation<double> _squashAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.enableSquashAnimation) {
      _squashController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      _squashAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _squashController, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.enableSquashAnimation) {
      _squashController.dispose();
    }
    super.dispose();
  }

  void _handleTaskCompletion() async {
    // Only play audio when completing a task (not when uncompleting)
    if (!widget.isCompleted) {
      // Play haptic feedback
      HapticService.lightImpact();

      // Play audio feedback using 1s magic astral sweep sound
      await AudioService.playAudioFile('audio/magic-astral-sweep-1s.aac');
    } else {
      // Play haptic feedback for uncompleting (but no audio)
      HapticService.lightImpact();
    }
  }

  void _triggerSquashAnimation() {
    if (widget.enableSquashAnimation) {
      // Only handle animation - single responsibility
      _squashController.forward().then((_) {
        _squashController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAdditionalContent =
        widget.task.notes?.isNotEmpty == true || widget.task.due != null;

    Widget content = InkWell(
      onTap: () {
        // Handle task completion feedback (audio + haptic)
        _handleTaskCompletion();

        // Trigger animation
        _triggerSquashAnimation();

        // Notify parent of state change
        widget.onTap();
      },
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
            Container(
              width: DesignTokens.checkboxSize,
              height: DesignTokens.checkboxSize,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius:
                    BorderRadius.circular(DesignTokens.borderRadiusSmall),
                border: Border.all(
                  color: widget.isCompleted
                      ? AppColors.primary
                      : AppColors.getTextSecondaryColor(context),
                  width: DesignTokens.borderWidthMedium,
                ),
                color: widget.isCompleted
                    ? AppColors.primary
                    : widget.isLoading
                        ? AppColors.getBackgroundColor(context)
                        : AppColors.transparent,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: DesignTokens.iconSizeSmall,
                      height: DesignTokens.iconSizeSmall,
                      child: CircularProgressIndicator(
                        strokeWidth: DesignTokens.borderWidthMedium,
                        color: AppColors.getTextSecondaryColor(
                            context), // Theme-aware color
                      ),
                    )
                  : widget.isCompleted
                      ? Icon(
                          Icons.check,
                          color: AppColors.getTextPrimaryColor(context),
                          size: DesignTokens.iconSizeSmall,
                        )
                      : null,
            ),
            SizedBox(width: DesignTokens.spacing3),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title
                  Text(
                    widget.task.title ?? '',
                    style: AppTypography.body.copyWith(
                      color: widget.isCompleted
                          ? AppColors.getTextSecondaryColor(context)
                          : AppColors.getTextPrimaryColor(context),
                      decoration: widget.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),

                  // Additional content (notes, due date)
                  if (hasAdditionalContent) ...[
                    SizedBox(height: DesignTokens.spacing1),
                    if (widget.task.notes?.isNotEmpty == true)
                      Text(
                        widget.task.notes!,
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.task.due != null) ...[
                      if (widget.task.notes?.isNotEmpty == true)
                        SizedBox(height: DesignTokens.spacing0),
                      _buildDueDate(context, widget.task.due!),
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
                  onPressed: widget.onEdit,
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
                  onPressed: widget.onDelete,
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

    // Wrap with animation if enabled
    if (widget.enableSquashAnimation) {
      return AnimatedBuilder(
        animation: _squashAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _squashAnimation.value,
            child: content,
          );
        },
      );
    }

    return content;
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
