import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../generated/app_localizations.dart';

/// Service for formatting dates and determining colors for due dates
class DateFormatterService {
  /// Get color for a due date based on how urgent it is
  static Color getDueDateColor(String dueDate, BuildContext context) {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return AppColors.getTextSecondaryColor(context);
    
    final now = DateTime.now();
    final difference = due.difference(now).inDays;
    
    if (difference < 0) {
      return AppColors.error; // Overdue
    } else if (difference == 0) {
      return AppColors.warning; // Due today
    } else if (difference <= 3) {
      return AppColors.warning; // Due soon
    } else {
      return AppColors.getTextSecondaryColor(context); // Normal
    }
  }

  /// Format a due date string for display
  static String formatDueDate(String dueDate, BuildContext context) {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return '';
    
    final now = DateTime.now();
    final difference = due.difference(now).inDays;
    
    if (difference < 0) {
      return AppLocalizations.of(context)!.overdue(-difference);
    } else if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.tomorrow;
    } else if (difference <= 7) {
      return AppLocalizations.of(context)!.daysFromNow(difference);
    } else {
      return '${due.day}/${due.month}';
    }
  }
}
