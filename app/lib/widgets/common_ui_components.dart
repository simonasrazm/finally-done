import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';

/// Common UI components used across the app
class CommonUIComponents {
  // Private constructor to prevent instantiation
  CommonUIComponents._();

  /// Builds a section header with icon and title
  static Widget buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.componentPadding),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: DesignTokens.iconLg,
          ),
          const SizedBox(width: DesignTokens.spacing3),
          Text(
            title,
            style: AppTypography.headline.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an empty state widget
  static Widget buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    double? iconSize,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize ?? DesignTokens.iconXl,
            color: AppColors.getTextTertiaryColor(context),
          ),
          const SizedBox(height: DesignTokens.componentPadding),
          Text(
            title,
            style: AppTypography.headline.copyWith(
              color: AppColors.getTextTertiaryColor(context),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(
              color: AppColors.getTextTertiaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a toggle switch widget
  static Widget buildToggleSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.componentPadding),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: AppColors.separator.withValues(alpha: DesignTokens.opacity30),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: DesignTokens.iconMd,
              color: AppColors.getTextSecondaryColor(context),
            ),
            const SizedBox(width: DesignTokens.spacing2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextPrimaryColor(context),
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacing1),
                  Text(
                    subtitle,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Builds a command list with empty state handling
  static Widget buildCommandList({
    required List<dynamic> commands,
    required Widget Function(dynamic command) itemBuilder,
    required Widget emptyState,
  }) {
    if (commands.isEmpty) {
      return emptyState;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: commands.map((command) => itemBuilder(command)).toList(),
    );
  }
}
