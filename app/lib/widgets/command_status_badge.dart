import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../models/queued_command.dart';
import '../utils/status_helper.dart';

class CommandStatusBadge extends StatelessWidget {

  const CommandStatusBadge({
    super.key,
    required this.command,
    required this.commandStatus,
  });
  final QueuedCommandRealm command;
  final String commandStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing2,
            vertical: DesignTokens.spacing1,
          ),
          decoration: BoxDecoration(
            color: StatusHelper.getStatusColor(commandStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          child: Text(
            StatusHelper.getStatusText(commandStatus, context),
            style: AppTypography.caption1.copyWith(
              color: StatusHelper.getStatusColor(commandStatus),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Failed flag indicator (only show if failed)
        if (command.failed) ...[
          const SizedBox(width: DesignTokens.spacing1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing1,
              vertical: DesignTokens.spacing0,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Text(
              'FAILED',
              style: AppTypography.caption1.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: AppTypography.caption2.fontSize,
              ),
            ),
          ),
        ],
        
        // Action needed flag indicator (only show if action needed)
        if (command.actionNeeded) ...[
          const SizedBox(width: DesignTokens.spacing1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing1,
              vertical: DesignTokens.spacing0,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Text(
              'ACTION NEEDED',
              style: AppTypography.caption1.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: AppTypography.caption2.fontSize,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
