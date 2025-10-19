import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../generated/app_localizations.dart';

/// Widget for adding new tasks
class TaskInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCreateTask;

  const TaskInputWidget({
    super.key,
    required this.controller,
    required this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body
                  .copyWith(color: AppColors.getTextPrimaryColor(context)),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.addNewTask,
                hintStyle: AppTypography.body
                    .copyWith(color: AppColors.getTextSecondaryColor(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  borderSide: BorderSide(color: AppColors.separatorOpaque),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  borderSide: BorderSide(color: AppColors.separatorOpaque),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  borderSide: BorderSide(
                      color: AppColors.primary,
                      width: DesignTokens.borderWidth2),
                ),
                filled: true,
                fillColor: AppColors.getSecondaryBackgroundColor(context),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.inputPadding,
                  vertical: DesignTokens.spacing2,
                ),
              ),
              onSubmitted: (_) => onCreateTask(),
            ),
          ),
          SizedBox(width: DesignTokens.spacing2),
          ElevatedButton.icon(
            onPressed: onCreateTask,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.add),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.componentPadding,
                vertical: DesignTokens.spacing2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
