# Global Theme System Design

## Overview

This design document outlines the implementation of a comprehensive global theme system for the Phantom Ping Flutter application. The theme system will provide a modern, gradient-based visual design with consistent colors, typography, spacing, and component styling across all screens. The design emphasizes reusability, maintainability, and adherence to Material Design 3 principles while incorporating custom gradient styling.

## Architecture

### Directory Structure

```
frontend/lib/
├── core/
│   └── theme/
│       ├── app_theme.dart          # Main theme configuration and exports
│       ├── app_colors.dart         # Color definitions and gradients
│       ├── app_typography.dart     # Typography scale and text styles
│       ├── app_spacing.dart        # Spacing constants
│       ├── component_themes.dart   # Component-specific theme configurations
│       └── widgets/
│           ├── gradient_button.dart      # Custom gradient button widget
│           ├── gradient_scaffold.dart    # Custom scaffold with gradient background
│           └── gradient_text.dart        # Text widget with gradient foreground
```

### Theme System Layers

1. **Foundation Layer**: Core design tokens (colors, gradients, spacing, typography)
2. **Component Layer**: Themed widgets and component configurations
3. **Application Layer**: Global theme applied to MaterialApp
4. **Screen Layer**: Screens using themed components

## Components and Interfaces

### 1. Color System (app_colors.dart)

#### Color Palette

```dart
class AppColors {
  // Primary Gradient Colors
  static const Color primaryStart = Color(0xFF4C51BF);  // Indigo-600
  static const Color primaryEnd = Color(0xFF7C3AED);    // Purple-600

  // Secondary Colors
  static const Color secondary = Color(0xFF60A5FA);     // Blue-400
  static const Color secondaryLight = Color(0xFFDEEBFF);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFFAFAFA);

  // Semantic Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}
```

#### Gradient Definitions

```dart
class AppGradients {
  // Primary gradient for buttons and accents
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
  );

  // Background gradient for scaffolds
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF4C51BF),  // Top: Indigo-600
      Color(0xFF6366F1),  // Middle: Indigo-500
      Color(0xFF7C3AED),  // Bottom: Purple-600
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Subtle gradient for cards
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF9FAFB),
    ],
  );
}
```

### 2. Typography System (app_typography.dart)

#### Text Style Scale

```dart
class AppTypography {
  static const String fontFamily = 'Inter'; // Or system default

  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  // Heading styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
```

### 3. Spacing System (app_spacing.dart)

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Common padding values
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
}
```

### 4. Component Themes (component_themes.dart)

#### Input Decoration Theme

```dart
InputDecorationTheme inputDecorationTheme() {
  return InputDecorationTheme(
    filled: false,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      borderSide: const BorderSide(color: AppColors.primaryStart, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    hintStyle: AppTypography.bodyMedium.copyWith(
      color: AppColors.textDisabled,
    ),
  );
}
```

#### Elevated Button Theme

Note: Standard ElevatedButton will be replaced with custom GradientButton for primary actions.

```dart
ElevatedButtonThemeData elevatedButtonTheme() {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: AppSpacing.buttonPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      elevation: 0,
      textStyle: AppTypography.labelLarge,
    ),
  );
}
```

#### Card Theme

```dart
CardTheme cardTheme() {
  return CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
    ),
    color: AppColors.surface,
    margin: const EdgeInsets.all(AppSpacing.sm),
  );
}
```

### 5. Custom Gradient Widgets

#### GradientButton Widget

A custom button widget that supports gradient backgrounds for primary buttons and gradient text for secondary buttons.

```dart
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final Widget? icon;

  // Primary button: gradient background, white text
  // Secondary button: light background, gradient text
}
```

**Key Features:**

- Primary variant: Gradient background with white text
- Secondary variant: Light single-color background (blue-400 shade) with gradient text
- Loading state with circular progress indicator
- Disabled state with reduced opacity
- Optional icon support

#### GradientScaffold Widget

A custom scaffold widget that applies gradient background to the entire screen.

```dart
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool applyGradient;

  // Wraps standard Scaffold with gradient background
}
```

**Key Features:**

- Applies background gradient to entire screen
- Optional gradient (can be disabled for specific screens)
- Maintains all standard Scaffold functionality
- Gradient positioned behind all content

#### GradientText Widget

A text widget that applies gradient as foreground color.

```dart
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  // Uses ShaderMask to apply gradient to text
}
```

**Key Features:**

- Applies gradient as text color
- Supports any TextStyle
- Customizable gradient
- Used in secondary buttons and accent text

### 6. Main Theme Configuration (app_theme.dart)

```dart
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryStart,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: Colors.transparent, // For gradient backgrounds
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.headingLarge,
        headlineMedium: AppTypography.headingMedium,
        headlineSmall: AppTypography.headingSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      inputDecorationTheme: inputDecorationTheme(),
      elevatedButtonTheme: elevatedButtonTheme(),
      cardTheme: cardTheme(),
    );
  }
}
```

## Data Models

No new data models are required for the theme system. The theme system uses Flutter's built-in theming infrastructure with custom extensions.

## Error Handling

### Theme Fallbacks

- If custom fonts fail to load, system defaults will be used
- Gradient widgets will gracefully degrade to solid colors if rendering issues occur
- All theme values have sensible defaults

### Widget Error States

- Buttons show disabled state when `onPressed` is null
- Loading states prevent multiple taps
- Error messages use semantic colors with appropriate contrast

## Testing Strategy

### Visual Testing

1. **Theme Consistency Testing**

   - Verify all screens use theme values instead of hardcoded colors
   - Check gradient rendering on different screen sizes
   - Validate text contrast ratios for accessibility

2. **Component Testing**

   - Test GradientButton in primary and secondary variants
   - Test GradientButton loading and disabled states
   - Test GradientScaffold with and without gradient
   - Test GradientText with different text styles

3. **Responsive Testing**
   - Test on different screen sizes (phone, tablet)
   - Verify spacing scales appropriately
   - Check gradient rendering on different aspect ratios

### Unit Testing

1. **Widget Tests**

   - Test GradientButton renders correctly
   - Test button callbacks fire correctly
   - Test loading state prevents interaction
   - Test secondary button shows gradient text

2. **Theme Tests**
   - Verify theme values are correctly applied
   - Test theme exports are accessible
   - Validate color contrast ratios programmatically

### Integration Testing

1. **Login Screen Integration**
   - Verify login screen uses all themed components
   - Test gradient background renders correctly
   - Verify buttons use gradient styling
   - Test form inputs use themed styles

## Implementation Notes

### Gradient Performance

- Gradients are defined as constants to avoid recreation
- ShaderMask for gradient text is performant for short text
- Background gradients use Container with BoxDecoration for efficiency

### Material Design 3 Compatibility

- Theme system extends Material Design 3 rather than replacing it
- Custom widgets maintain Material Design interaction patterns
- Accessibility features (tap targets, contrast) are preserved

### Migration Strategy

1. Implement theme system foundation (colors, typography, spacing)
2. Create custom gradient widgets
3. Update main.dart to use new theme
4. Migrate login screen to use themed components
5. Provide migration guide for future screens

### Future Enhancements

- Dark theme variant with adjusted gradients
- Theme customization per organization
- Animated gradient transitions
- Additional gradient presets for different contexts
