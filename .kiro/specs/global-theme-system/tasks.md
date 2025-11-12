# Implementation Plan

- [ ] 1. Create theme foundation files

  - Create `frontend/lib/core/theme/` directory structure
  - Create `app_colors.dart` with color palette and gradient definitions
  - Create `app_typography.dart` with text style scale
  - Create `app_spacing.dart` with spacing constants and common padding values
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 4.1, 4.2, 4.3, 4.4, 8.1, 8.5_

- [ ] 2. Implement component theme configurations

  - Create `component_themes.dart` with InputDecorationTheme configuration
  - Add ElevatedButtonThemeData configuration
  - Add CardTheme configuration
  - _Requirements: 3.3, 3.4, 3.5, 5.2_

- [ ] 3. Create custom gradient widgets

  - [ ] 3.1 Implement GradientButton widget

    - Create `frontend/lib/core/theme/widgets/gradient_button.dart`
    - Implement primary variant with gradient background and white text
    - Implement secondary variant with light background and gradient text
    - Add loading state with circular progress indicator
    - Add disabled state with reduced opacity
    - Add optional icon support
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 8.3, 8.4_

  - [ ] 3.2 Implement GradientScaffold widget

    - Create `frontend/lib/core/theme/widgets/gradient_scaffold.dart`
    - Apply background gradient using Container with BoxDecoration
    - Support optional gradient (can be disabled)
    - Maintain all standard Scaffold functionality
    - _Requirements: 1.2, 8.2, 8.5_

  - [ ] 3.3 Implement GradientText widget
    - Create `frontend/lib/core/theme/widgets/gradient_text.dart`
    - Use ShaderMask to apply gradient to text
    - Support custom TextStyle parameter
    - Support custom Gradient parameter
    - _Requirements: 8.4_

- [ ] 4. Create main theme configuration and exports

  - Create `app_theme.dart` with AppTheme class and lightTheme() method
  - Configure Material Design 3 ThemeData with custom color scheme
  - Apply typography scale to textTheme
  - Apply component themes (input, button, card)
  - Create barrel export file for easy imports
  - _Requirements: 1.3, 1.5, 2.5, 5.1, 5.2, 5.3, 5.4_

- [ ] 5. Update main.dart to use new theme

  - Import AppTheme from theme directory
  - Replace existing theme with AppTheme.lightTheme()
  - Verify app launches with new theme applied
  - _Requirements: 1.1, 1.3, 5.3_

- [ ] 6. Migrate login screen to use themed components

  - [ ] 6.1 Update login screen scaffold

    - Replace Scaffold with GradientScaffold
    - Remove hardcoded background colors
    - Verify gradient background renders correctly
    - _Requirements: 6.1, 6.5, 8.2_

  - [ ] 6.2 Update login screen buttons

    - Replace ElevatedButton with GradientButton for primary login button
    - Apply themed button styling
    - Verify gradient background on button
    - Verify loading state uses themed styling
    - _Requirements: 3.1, 6.2, 8.3_

  - [ ] 6.3 Update login screen text fields

    - Remove hardcoded InputDecoration properties
    - Verify themed input decoration is applied
    - Test focus states use theme colors
    - _Requirements: 3.2, 3.3, 6.3_

  - [ ] 6.4 Update login screen typography

    - Replace hardcoded TextStyle with AppTypography styles
    - Apply displayLarge for app title
    - Apply bodyMedium for subtitle
    - Apply labelLarge for input labels
    - _Requirements: 2.1, 2.2, 2.3, 6.4, 6.5_

  - [ ] 6.5 Update login screen spacing

    - Replace hardcoded padding/margin values with AppSpacing constants
    - Apply consistent spacing between elements
    - Use AppSpacing.screenPadding for screen padding
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 6.5_

  - [ ] 6.6 Update error message styling
    - Apply semantic error color to error container
    - Use themed error colors for background and border
    - Verify error icon uses themed color
    - Ensure error text uses appropriate typography
    - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 7. Create theme documentation

  - Document theme usage patterns in README or comments
  - Provide examples of using GradientButton, GradientScaffold, GradientText
  - Document color palette and when to use each color
  - Document typography scale and appropriate use cases
  - _Requirements: 5.5_

- [ ] 8. Write widget tests for custom components
  - Write tests for GradientButton primary and secondary variants
  - Write tests for GradientButton loading and disabled states
  - Write tests for GradientScaffold gradient rendering
  - Write tests for GradientText gradient application
  - Verify button callbacks fire correctly
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
