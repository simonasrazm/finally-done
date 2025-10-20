import 'package:flutter/material.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../generated/app_localizations.dart';

/// Widget for selecting task lists
class TaskListSelectorWidget extends StatelessWidget {

  const TaskListSelectorWidget({
    super.key,
    required this.selectedTaskListId,
    required this.taskLists,
    required this.onTaskListChanged,
  });
  final String? selectedTaskListId;
  final List<google_tasks.TaskList> taskLists;
  final Function(String?) onTaskListChanged;

  @override
  Widget build(BuildContext context) {
    if (taskLists.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.componentPadding),
      child: Row(
        children: [
          Icon(Icons.list, color: AppColors.getTextPrimaryColor(context)),
          const SizedBox(width: DesignTokens.iconSpacing),
          Expanded(
            child: DropdownButton<String>(
              value: selectedTaskListId,
              hint: Text(
                AppLocalizations.of(context)!.selectTaskList,
                style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              ),
              isExpanded: true,
              onChanged: onTaskListChanged,
              items: taskLists.map<DropdownMenuItem<String>>((google_tasks.TaskList list) {
                return DropdownMenuItem<String>(
                  value: list.id,
                  child: Text(
                    list.title ?? 'Untitled List',
                    style: AppTypography.body.copyWith(color: AppColors.getTextPrimaryColor(context)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
