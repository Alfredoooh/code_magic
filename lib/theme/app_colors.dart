// app_colors.dart - Material Design 3 Color System
import 'package:flutter/material.dart';

// ============================================
// COLOR SYSTEM - M3 EXPRESSIVE
// ============================================
class AppColors {
  // DARK THEME COLORS
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);
  static const darkSurfaceContainer = Color(0xFF1C1C1E);
  static const darkSurfaceContainerHigh = Color(0xFF2C2C2E);

  // LIGHT THEME COLORS
  static const lightBackground = Color(0xFFFFFBFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightSurfaceContainer = Color(0xFFF8F8F8);
  static const lightSurfaceContainerHigh = Color(0xFFEEEEEE);

  // PRIMARY COLORS (White for dark theme, Black for light theme)
  static const primary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2A2A2A);
  static const onPrimary = Color(0xFF000000);
  static const onPrimaryContainer = Color(0xFFE0E0E0);

  // SECONDARY COLORS (Neutral grays)
  static const secondary = Color(0xFF757575);
  static const secondaryContainer = Color(0xFFE0E0E0);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF1C1B1F);

  // TERTIARY COLORS (Neutral grays)
  static const tertiary = Color(0xFF616161);
  static const tertiaryContainer = Color(0xFFEEEEEE);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF1C1B1F);

  // STATUS COLORS
  static const success = Color(0xFF00C896);
  static const successContainer = Color(0xFF003826);
  static const error = Color(0xFFFF4444);
  static const errorContainer = Color(0xFF93000A);
  static const warning = Color(0xFFFF9500);
  static const warningContainer = Color(0xFF4E2F00);
  static const info = Color(0xFF9E9E9E);
  static const infoContainer = Color(0xFF424242);

  // TEXT COLORS - DARK
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB3B3B3);
  static const darkTextTertiary = Color(0xFF666666);
  static const darkTextDisabled = Color(0xFF444444);

  // TEXT COLORS - LIGHT
  static const lightTextPrimary = Color(0xFF1C1B1F);
  static const lightTextSecondary = Color(0xFF49454F);
  static const lightTextTertiary = Color(0xFF79747E);
  static const lightTextDisabled = Color(0xFFB3B3B3);

  // OUTLINE COLORS - Using getter to avoid const evaluation issues
  static Color get darkOutline => Colors.white.withOpacity(0.12);
  static Color get darkOutlineVariant => Colors.white.withOpacity(0.08);
  static Color get lightOutline => Colors.black.withOpacity(0.12);
  static Color get lightOutlineVariant => Colors.black.withOpacity(0.08);

  // SCRIM & OVERLAY
  static Color get scrim => Colors.black.withOpacity(0.32);
  static Color get darkOverlay => Colors.white.withOpacity(0.05);
  static Color get lightOverlay => Colors.black.withOpacity(0.05);
}