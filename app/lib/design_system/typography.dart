import 'package:flutter/material.dart';

/// Finally Done App Typography System
/// Based on iOS Human Interface Guidelines with SF Pro font family
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // Font Family - Using system fonts
  static const String fontFamily = 'SF Pro Display'; // Will fallback to system font
  static const String fontFamilyText = 'SF Pro Text'; // Will fallback to system font

  // Font Weights - Centralized for consistency
  static const FontWeight weightNormal = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Large Title (34pt, Bold)
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.4,
  );

  // Title 1 (28pt, Bold)
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.36,
  );

  // Title 2 (22pt, Bold)
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.22,
  );

  // Title 3 (20pt, Semibold)
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.1,
  );

  // Headline (17pt, Semibold)
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.4,
  );

  // Body (17pt, Regular)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 17,
    fontWeight: FontWeight.normal,
    height: 1.3,
    letterSpacing: -0.4,
  );

  // Callout (16pt, Regular)
  static const TextStyle callout = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.3,
    letterSpacing: -0.32,
  );

  // Subhead (15pt, Regular)
  static const TextStyle subhead = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.3,
    letterSpacing: -0.24,
  );

  // Footnote (13pt, Regular)
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
    letterSpacing: -0.08,
  );

  // Caption 1 (12pt, Regular)
  static const TextStyle caption1 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
    letterSpacing: 0,
  );

  // Caption 2 (11pt, Regular)
  static const TextStyle caption2 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    height: 1.2,
    letterSpacing: 0.07,
  );

  // Button Text (17pt, Semibold)
  static const TextStyle button = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.4,
  );

  // Section Header (13pt, Regular, Uppercase)
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
    letterSpacing: -0.08,
  );

  // Helper method to get text style with color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // Helper method to get text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(
      color: style.color?.withOpacity(opacity),
    );
  }
}
