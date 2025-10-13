# Design System Documentation

## Overview

This design system follows modern design token principles and is structured to be Figma-ready. It provides a single source of truth for all design values used throughout the app.

## Architecture

### 1. Design Tokens (`tokens.dart`)
- **Single source of truth** for all design values
- **Semantic naming** - describes purpose, not appearance
- **Scale-based system** - consistent mathematical relationships
- **Figma-ready structure** - easy to sync with design tools

### 2. Color System (`colors.dart`)
- Brand colors with semantic naming
- Light/dark mode support
- Context-aware color selection

### 3. Typography System (`typography.dart`)
- iOS Human Interface Guidelines based
- Consistent font scales and weights
- Responsive typography support

## Usage Examples

### Spacing Tokens

```dart
// ❌ Old way - hardcoded values
Container(
  padding: EdgeInsets.all(16.0),
  margin: EdgeInsets.symmetric(horizontal: 8.0),
  child: Text('Content'),
)

// ✅ New way - design tokens
Container(
  padding: EdgeInsets.all(DesignTokens.componentPadding),
  margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing2),
  child: Text('Content'),
)

// ✅ Even better - semantic tokens
Container(
  padding: EdgeInsets.all(DesignTokens.componentPadding),
  margin: EdgeInsets.symmetric(horizontal: DesignTokens.componentGap),
  child: Text('Content'),
)
```

### Icon Sizes

```dart
// ❌ Old way
Icon(Icons.star, size: 24.0)

// ✅ New way
Icon(Icons.star, size: DesignTokens.iconLg)

// ✅ Or using helper
Icon(Icons.star, size: DesignTokens.getIconSize('lg'))
```

### Responsive Design

```dart
// Responsive spacing based on screen size
Container(
  padding: DesignTokens.getResponsivePadding(
    context,
    mobile: EdgeInsets.all(DesignTokens.spacing4),
    tablet: EdgeInsets.all(DesignTokens.spacing6),
    desktop: EdgeInsets.all(DesignTokens.spacing8),
  ),
)
```

### Button Sizing

```dart
// Consistent button heights
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(0, DesignTokens.buttonHeightMd),
    padding: EdgeInsets.symmetric(
      horizontal: DesignTokens.buttonPadding,
      vertical: DesignTokens.spacing2,
    ),
  ),
  child: Text('Button'),
)
```

## Figma Integration

### Token Naming Convention

The tokens are structured to match Figma's design token system:

```
spacing/
  ├── xs: 4px
  ├── sm: 8px
  ├── md: 16px
  ├── lg: 24px
  └── xl: 32px

sizing/
  ├── icon/
  │   ├── xs: 12px
  │   ├── sm: 16px
  │   ├── md: 20px
  │   └── lg: 24px
  └── button/
      ├── sm: 32px
      ├── md: 40px
      └── lg: 48px

radius/
  ├── sm: 4px
  ├── md: 8px
  └── lg: 12px
```

### Exporting from Figma

1. Install Figma Tokens plugin
2. Create tokens in Figma with matching names
3. Export as JSON/Code
4. Sync with this Dart implementation

## Migration Guide

### Step 1: Replace Hardcoded Values

```dart
// Before
Container(
  padding: EdgeInsets.all(16.0),
  margin: EdgeInsets.only(top: 8.0),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8.0),
  ),
)

// After
Container(
  padding: EdgeInsets.all(DesignTokens.componentPadding),
  margin: EdgeInsets.only(top: DesignTokens.spacing2),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
  ),
)
```

### Step 2: Use Semantic Tokens

```dart
// Before
Container(
  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
)

// After
Container(
  padding: EdgeInsets.symmetric(
    horizontal: DesignTokens.componentPadding,
    vertical: DesignTokens.buttonPadding,
  ),
)
```

### Step 3: Implement Responsive Design

```dart
// Before
Container(
  padding: EdgeInsets.all(16.0),
)

// After
Container(
  padding: DesignTokens.getResponsivePadding(
    context,
    mobile: EdgeInsets.all(DesignTokens.spacing4),
    tablet: EdgeInsets.all(DesignTokens.spacing6),
  ),
)
```

## Benefits

1. **Consistency** - All spacing/sizing follows the same scale
2. **Maintainability** - Change one token, update everywhere
3. **Figma Sync** - Easy to keep design and code in sync
4. **Responsive** - Built-in responsive design support
5. **Developer Experience** - Clear, semantic naming
6. **Design Handoff** - Clear mapping between design and code

## Best Practices

1. **Always use tokens** - Never hardcode spacing/sizing values
2. **Use semantic names** - `componentPadding` not `spacing16`
3. **Group related tokens** - Keep spacing, sizing, colors separate
4. **Document changes** - Update this README when adding tokens
5. **Test responsive** - Verify tokens work across screen sizes
6. **Sync with Figma** - Keep design and code tokens in sync
