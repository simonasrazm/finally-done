import 'package:flutter/material.dart';

/// Design Tokens - Single source of truth for all design values
/// 
/// This system follows modern design token principles:
/// 1. Semantic naming (what it's for, not what it looks like)
/// 2. Scale-based values (consistent mathematical relationships)
/// 3. Figma-ready structure (easy to sync with design tools)
/// 4. Responsive design support
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ============================================================================
  // SPACING TOKENS
  // ============================================================================
  
  /// Base spacing unit (4px) - all spacing is multiples of this
  static const double _baseUnit = 4.0;
  
  /// Spacing scale following 4px grid system
  static const double spacing0 = 0.0;           // 0px
  static const double spacing1 = _baseUnit * 1;  // 4px
  static const double spacing2 = _baseUnit * 2;  // 8px
  static const double spacing3 = _baseUnit * 3;  // 12px
  static const double spacing4 = _baseUnit * 4;  // 16px
  static const double spacing6 = _baseUnit * 6;  // 24px
  static const double spacing8 = _baseUnit * 8;  // 32px
  static const double spacing12 = _baseUnit * 12; // 48px
  static const double spacing24 = _baseUnit * 24; // 96px

  // ============================================================================
  // SEMANTIC SPACING TOKENS
  // ============================================================================
  
  /// Component internal spacing
  static const double componentPadding = spacing4;      // 16px
  static const double componentGap = spacing2;          // 8px
  static const double componentMargin = spacing4;       // 16px
  
  /// Layout spacing
  static const double layoutPadding = spacing4;         // 16px
  static const double layoutGap = spacing6;             // 24px
  static const double sectionSpacing = spacing8;        // 32px
  
  /// Content spacing
  static const double contentPadding = spacing4;        // 16px
  static const double contentGap = spacing3;            // 12px
  static const double textSpacing = spacing2;           // 8px
  
  /// Interactive element spacing
  static const double buttonPadding = spacing3;         // 12px
  static const double inputPadding = spacing3;          // 12px
  static const double iconSpacing = spacing2;           // 8px

  // ============================================================================
  // SIZING TOKENS
  // ============================================================================
  
  /// Icon sizes
  static const double iconSm = 16.0;    // Small icons
  static const double iconMd = 20.0;    // Medium icons
  static const double iconLg = 24.0;    // Large icons
  static const double icon4xl = 80.0;   // 4X large icons (main recording button)
  
  /// Button sizes
  static const double buttonHeight2xl = 60.0;  // 2X large buttons (input buttons)
  static const double buttonHeight3xl = 200.0; // 3X large buttons (main recording button)
  
  /// Input field widths
  static const double inputWidthMd = 120.0;    // Medium input widths
  static const double inputWidthLg = 150.0;    // Large input widths
  
  /// Photo/Media sizes
  static const double photoPreviewHeight = 100.0;  // Photo preview height
  static const double photoPreviewWidth = 100.0;   // Photo preview width
  
  /// Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radius2xl = 24.0;

  // ============================================================================
  // BORDER TOKENS
  // ============================================================================
  
  /// Border widths
  static const double borderWidth1 = 1.0;
  static const double borderWidth2 = 2.0;
  static const double borderWidth3 = 3.0;

  // ============================================================================
  // ELEVATION TOKENS
  // ============================================================================
  
  /// Material elevation levels
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;
  static const double elevation16 = 16.0;

  // ============================================================================
  // OPACITY TOKENS
  // ============================================================================
  
  /// Opacity values for overlays and transparency
  static const double opacity10 = 0.1;
  static const double opacity20 = 0.2;
  static const double opacity30 = 0.3;
  static const double opacity40 = 0.4;
  static const double opacity50 = 0.5;
  static const double opacity60 = 0.6;
  static const double opacity70 = 0.7;
  static const double opacity80 = 0.8;
  static const double opacity90 = 0.9;
  static const double opacity100 = 1.0;

  // ============================================================================
  // TIMING TOKENS
  // ============================================================================
  
  /// Animation and delay durations
  static const int delayShort = 500;        // 500ms - short delays
  static const int delayMedium = 1000;      // 1s - medium delays
  static const int delayLong = 2000;        // 2s - long delays
  
  static const int animationFast = 150;     // 150ms - fast animations
  static const int animationNormal = 300;   // 300ms - normal animations
  static const int animationSlow = 500;     // 500ms - slow animations

}

/// Convenience class for commonly used spacing values
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();
  
  // Quick access to most common spacing values
  static const double xs = DesignTokens.spacing1;    // 4px
  static const double sm = DesignTokens.spacing2;    // 8px
  static const double md = DesignTokens.spacing4;    // 16px
  static const double lg = DesignTokens.spacing6;    // 24px
  static const double xl = DesignTokens.spacing8;    // 32px
  static const double xxl = DesignTokens.spacing12;  // 48px
  
  // Semantic spacing
  static const double componentPadding = DesignTokens.componentPadding;
  static const double layoutPadding = DesignTokens.layoutPadding;
  static const double sectionSpacing = DesignTokens.sectionSpacing;
  
  // Gap values
  static const double gapXs = DesignTokens.spacing1;
  static const double gapSm = DesignTokens.spacing2;
  static const double gapMd = DesignTokens.spacing3;
  static const double gapLg = DesignTokens.spacing4;
  static const double gapXl = DesignTokens.spacing6;
  
  // Width/Height helpers
  static const double widthXs = DesignTokens.spacing1;
  static const double widthSm = DesignTokens.spacing2;
  static const double widthMd = DesignTokens.spacing4;
  static const double widthLg = DesignTokens.spacing6;
  static const double widthXl = DesignTokens.spacing8;
}
