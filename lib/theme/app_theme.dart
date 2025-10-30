// app_theme.dart - Material Design 3 Theme Configuration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

// ============================================
// SPACING SYSTEM - 4dp grid
// ============================================
class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const xxxl = 48.0;
  static const huge = 64.0;
  static const massive = 80.0;

  // Border radius values
  static const radiusXs = 4.0;
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusFull = 9999.0;
}

// ============================================
// SHAPE SYSTEM - M3 rounded corners
// ============================================
class AppShapes {
  static const none = 0.0;
  static const extraSmall = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const extraLarge = 28.0;
  static const full = 9999.0;

  // Shape styles
  static RoundedRectangleBorder get shapeNone => const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static RoundedRectangleBorder get shapeExtraSmall => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(extraSmall),
  );

  static RoundedRectangleBorder get shapeSmall => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(small),
  );

  static RoundedRectangleBorder get shapeMedium => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(medium),
  );

  static RoundedRectangleBorder get shapeLarge => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(large),
  );

  static RoundedRectangleBorder get shapeExtraLarge => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(extraLarge),
  );

  static RoundedRectangleBorder get shapeFull => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(full),
  );
}

// ============================================
// ELEVATION SYSTEM
// ============================================
class AppElevation {
  static const level0 = 0.0;
  static const level1 = 1.0;
  static const level2 = 3.0;
  static const level3 = 6.0;
  static const level4 = 8.0;
  static const level5 = 12.0;
}

// ============================================
// MOTION SYSTEM - Physics-based animations
// ============================================
class AppMotion {
  // DURATION - Adaptive timing
  static const instant = Duration(milliseconds: 0);
  static const veryShort = Duration(milliseconds: 50);
  static const short = Duration(milliseconds: 100);
  static const medium = Duration(milliseconds: 250);
  static const long = Duration(milliseconds: 350);
  static const veryLong = Duration(milliseconds: 500);
  static const extraLong = Duration(milliseconds: 700);

  // EASING CURVES - M3 emphasized curves
  static const standardEasing = Curves.easeInOutCubicEmphasized;
  static const emphasizedDecelerate = Curves.easeOutCubic;
  static const emphasizedAccelerate = Curves.easeInCubic;
  static const linear = Curves.linear;

  // SPRING CONFIGURATIONS
  static const fastSpring = SpringDescription(
    mass: 0.8,
    stiffness: 180.0,
    damping: 18.0,
  );

  static const mediumSpring = SpringDescription(
    mass: 1.0,
    stiffness: 120.0,
    damping: 16.0,
  );

  static const slowSpring = SpringDescription(
    mass: 1.2,
    stiffness: 80.0,
    damping: 14.0,
  );
}

// ============================================
// STATE LAYER OPACITIES
// ============================================
class AppStateOpacity {
  static const hover = 0.08;
  static const focus = 0.12;
  static const press = 0.12;
  static const drag = 0.16;
  static const disabled = 0.38;
}

// ============================================
// HAPTIC FEEDBACK HELPER
// ============================================
class AppHaptics {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void success() {
    HapticFeedback.lightImpact();
  }

  static void error() {
    HapticFeedback.vibrate();
  }
}

// ============================================
// COMPLETE DARK THEME
// ============================================
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  splashFactory: InkRipple.splashFactory,

  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onPrimaryContainer,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkSurfaceContainerHigh,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: Colors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightTextPrimary,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  ),

  scaffoldBackgroundColor: AppColors.darkBackground,

  textTheme: TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkTextPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkTextPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.darkTextPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkTextPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkTextPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.darkTextPrimary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkTextPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkTextTertiary),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
    iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),

  cardTheme: CardThemeData(
    color: AppColors.darkSurfaceContainer,
    elevation: AppElevation.level1,
    shape: AppShapes.shapeMedium,
    margin: const EdgeInsets.all(AppSpacing.xs),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: AppElevation.level1,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.darkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.darkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextTertiary),
  ),

  dividerTheme: DividerThemeData(
    color: AppColors.darkOutlineVariant,
    thickness: 1,
    space: 1,
  ),

  iconTheme: const IconThemeData(
    color: AppColors.darkTextPrimary,
    size: 24,
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.darkSurfaceContainerHigh,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
    shape: AppShapes.shapeMedium,
    elevation: AppElevation.level3,
    behavior: SnackBarBehavior.floating,
  ),
);

// ============================================
// COMPLETE LIGHT THEME
// ============================================
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  splashFactory: InkRipple.splashFactory,

  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.onPrimaryContainer,
    onPrimaryContainer: AppColors.primaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onPrimaryContainer,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerHighest: AppColors.lightSurfaceContainerHigh,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: Colors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkTextPrimary,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  ),

  scaffoldBackgroundColor: AppColors.lightBackground,

  textTheme: TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.lightTextPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.lightTextPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.lightTextPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.lightTextPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.lightTextPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.lightTextPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.lightTextPrimary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.lightTextPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.lightTextTertiary),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
    iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),

  cardTheme: CardThemeData(
    color: AppColors.lightSurfaceContainer,
    elevation: AppElevation.level1,
    shape: AppShapes.shapeMedium,
    margin: const EdgeInsets.all(AppSpacing.xs),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: AppElevation.level1,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
      textStyle: AppTypography.labelLarge,
    ).copyWith(
      splashFactory: InkRipple.splashFactory,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextTertiary),
  ),

  dividerTheme: DividerThemeData(
    color: AppColors.lightOutlineVariant,
    thickness: 1,
    space: 1,
  ),

  iconTheme: const IconThemeData(
    color: AppColors.lightTextPrimary,
    size: 24,
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.lightSurfaceContainerHigh,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
    shape: AppShapes.shapeMedium,
    elevation: AppElevation.level3,
    behavior: SnackBarBehavior.floating,
  ),
);

// ============================================
// THEME EXTENSIONS
// ============================================
extension ThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => colors.surface;
  Color get surfaceContainer => colors.surfaceContainerHighest;
  Color get primary => colors.primary;
  Color get error => colors.error;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
}