import 'package:flutter/material.dart';
import 'package:finally_done/design_system/colors.dart';
import 'package:finally_done/generated/app_localizations.dart';

/// Helper class for command status display logic
class StatusHelper {
  /// Get color for command status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return AppColors.primary;
      case 'recorded':
        return AppColors.warning;
      case 'manual_review':
        return AppColors.warning;
      case 'transcribing':
        return AppColors.warning;
      case 'processing':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
  
  /// Get display text for command status
  static String getStatusText(String status, BuildContext context) {
    switch (status) {
      case 'queued':
        return AppLocalizations.of(context)!.queued;
      case 'recorded':
        return AppLocalizations.of(context)!.recorded;
      case 'manual_review':
        return 'Manual Review';
      case 'transcribing':
        return AppLocalizations.of(context)!.transcribing;
      case 'processing':
        return AppLocalizations.of(context)!.processingTab;
      case 'completed':
        return AppLocalizations.of(context)!.done;
      case 'failed':
        return AppLocalizations.of(context)!.failed;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  /// Format time difference for display
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
