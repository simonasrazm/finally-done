import 'package:flutter/material.dart';

/// Finally Done App Color System
/// Based on iOS Human Interface Guidelines with brand customization
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Brand Colors
  static const primary = Color(0xFF007AFF); // iOS Blue
  static const primaryDark = Color(0xFF0051D5);
  static const secondary = Color(0xFF5856D6); // iOS Purple

  // Status Colors
  static const success = Color(0xFF34C759); // iOS Green
  static const warning = Color(0xFFFF9500); // iOS Orange
  static const error = Color(0xFFFF3B30); // iOS Red
  static const info = Color(0xFF007AFF); // iOS Blue

  // Neutral Colors (iOS System Colors)
  static const background = Color(0xFFF2F2F7); // iOS Background
  static const backgroundSecondary =
      Color(0xFFFFFFFF); // iOS Secondary Background
  static const backgroundTertiary =
      Color(0xFFF2F2F7); // iOS Tertiary Background

  // Text Colors
  static const textPrimary = Color(0xFF000000); // iOS Label
  static const textSecondary =
      Color(0xFF3C3C43); // iOS Secondary Label (99% opacity)
  static const textTertiary =
      Color(0xFF3C3C43); // iOS Tertiary Label (60% opacity)
  static const textQuaternary =
      Color(0xFF3C3C43); // iOS Quaternary Label (30% opacity)

  // Separator Colors
  static const separator = Color(0xFF3C3C43); // iOS Separator (30% opacity)
  static const separatorOpaque = Color(0xFFC6C6C8); // iOS Opaque Separator

  // Fill Colors
  static const fillPrimary = Color(0xFF787880); // iOS Fill (20% opacity)
  static const fillSecondary =
      Color(0xFF787880); // iOS Secondary Fill (16% opacity)
  static const fillTertiary =
      Color(0xFF767680); // iOS Tertiary Fill (12% opacity)
  static const fillQuaternary =
      Color(0xFF747480); // iOS Quaternary Fill (8% opacity)

  // Dark Mode Colors
  static const darkBackground = Color(0xFF000000);
  static const darkBackgroundSecondary = Color(0xFF1C1C1E);
  static const darkBackgroundTertiary = Color(0xFF2C2C2E);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFEBEBF5); // 99% opacity
  static const darkTextTertiary = Color(0xFFEBEBF5); // 60% opacity
  static const darkTextQuaternary = Color(0xFFEBEBF5); // 30% opacity
  static const darkSeparator = Color(0xFF38383A);
  static const darkSeparatorOpaque = Color(0xFF38383A);
  static const darkFillPrimary = Color(0xFF787880); // 20% opacity
  static const darkFillSecondary = Color(0xFF787880); // 16% opacity
  static const darkFillTertiary = Color(0xFF767680); // 12% opacity
  static const darkFillQuaternary = Color(0xFF747480); // 8% opacity

  // Mission Control Status Colors
  static const statusQueued = Color(0xFF8E8E93); // Gray
  static const statusProcessing = Color(0xFF007AFF); // Blue
  static const statusReviewNeeded = Color(0xFFFF9500); // Orange
  static const statusExecuting = Color(0xFF007AFF); // Blue
  static const statusExecuted = Color(0xFF34C759); // Green
  static const statusFailed = Color(0xFFFF3B30); // Red

  // Helper method to get appropriate color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  static Color getSecondaryBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackgroundSecondary
        : backgroundSecondary;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  static Color getTextTertiaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : textTertiary;
  }

  // Theme-agnostic colors
  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
}
