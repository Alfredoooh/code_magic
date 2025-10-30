// app_colors.dart - Material Design 3 Expressive Color System
import 'package:flutter/material.dart';

// ============================================
// COLOR SYSTEM - M3 EXPRESSIVE
// ============================================
class AppColors {
  // DARK THEME COLORS (90% escuro profundo)
  static const darkBackground = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF151515);
  static const darkSurfaceVariant = Color(0xFF1F1F1F);
  static const darkSurfaceContainer = Color(0xFF1A1A1A);
  static const darkSurfaceContainerHigh = Color(0xFF242424);
  static const darkSurfaceContainerHighest = Color(0xFF2E2E2E);

  // LIGHT THEME COLORS
  static const lightBackground = Color(0xFFFFFBFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightSurfaceContainer = Color(0xFFF8F8F8);
  static const lightSurfaceContainerHigh = Color(0xFFEEEEEE);
  static const lightSurfaceContainerHighest = Color(0xFFE8E8E8);

  // PRIMARY COLORS - Material Vibrant Purple (M3 Expressive)
  static const primary = Color(0xFF9C27B0); // Material Purple 500
  static const primaryContainer = Color(0xFF4A148C); // Material Purple 900
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFE1BEE7);
  
  // PRIMARY LIGHT THEME
  static const primaryLight = Color(0xFF6A1B9A); // Material Purple 800
  static const primaryContainerLight = Color(0xFFF3E5F5); // Material Purple 50
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const onPrimaryContainerLight = Color(0xFF4A148C);

  // SECONDARY COLORS - Material Teal (Complementar)
  static const secondary = Color(0xFF00897B); // Material Teal 600
  static const secondaryContainer = Color(0xFF004D40); // Material Teal 900
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFFB2DFDB);
  
  // SECONDARY LIGHT THEME
  static const secondaryLight = Color(0xFF00796B); // Material Teal 700
  static const secondaryContainerLight = Color(0xFFE0F2F1); // Material Teal 50
  static const onSecondaryLight = Color(0xFFFFFFFF);
  static const onSecondaryContainerLight = Color(0xFF004D40);

  // TERTIARY COLORS - Material Deep Orange (Accent)
  static const tertiary = Color(0xFFFF5722); // Material Deep Orange 500
  static const tertiaryContainer = Color(0xFFBF360C); // Material Deep Orange 900
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFFFFCCBC);
  
  // TERTIARY LIGHT THEME
  static const tertiaryLight = Color(0xFFE64A19); // Material Deep Orange 700
  static const tertiaryContainerLight = Color(0xFFFBE9E7); // Material Deep Orange 50
  static const onTertiaryLight = Color(0xFFFFFFFF);
  static const onTertiaryContainerLight = Color(0xFFBF360C);

  // STATUS COLORS - Material Expressive
  static const success = Color(0xFF00C853); // Material Green A700
  static const successContainer = Color(0xFF1B5E20); // Material Green 900
  static const onSuccess = Color(0xFF000000);
  static const onSuccessContainer = Color(0xFFB9F6CA);
  
  static const error = Color(0xFFFF1744); // Material Red A400
  static const errorContainer = Color(0xFFB71C1C); // Material Red 900
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFFFFCDD2);
  
  static const warning = Color(0xFFFFC400); // Material Amber A400
  static const warningContainer = Color(0xFFFF6F00); // Material Orange 900
  static const onWarning = Color(0xFF000000);
  static const onWarningContainer = Color(0xFFFFECB3);
  
  static const info = Color(0xFF2196F3); // Material Blue 500
  static const infoContainer = Color(0xFF0D47A1); // Material Blue 900
  static const onInfo = Color(0xFFFFFFFF);
  static const onInfoContainer = Color(0xFFBBDEFB);

  // TEXT COLORS - DARK THEME
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB8B8B8);
  static const darkTextTertiary = Color(0xFF888888);
  static const darkTextDisabled = Color(0xFF4A4A4A);

  // TEXT COLORS - LIGHT THEME
  static const lightTextPrimary = Color(0xFF1C1B1F);
  static const lightTextSecondary = Color(0xFF49454F);
  static const lightTextTertiary = Color(0xFF79747E);
  static const lightTextDisabled = Color(0xFFB3B3B3);

  // OUTLINE COLORS - DARK THEME
  static Color get darkOutline => Colors.white.withOpacity(0.12);
  static Color get darkOutlineVariant => Colors.white.withOpacity(0.08);
  
  // OUTLINE COLORS - LIGHT THEME
  static Color get lightOutline => Colors.black.withOpacity(0.12);
  static Color get lightOutlineVariant => Colors.black.withOpacity(0.08);

  // SCRIM & OVERLAY
  static Color get scrim => Colors.black.withOpacity(0.32);
  static Color get darkOverlay => Colors.white.withOpacity(0.05);
  static Color get lightOverlay => Colors.black.withOpacity(0.05);
  
  // GRADIENT COLORS - Material Expressive
  static const List<Color> primaryGradient = [
    Color(0xFF9C27B0), // Purple 500
    Color(0xFF7B1FA2), // Purple 600
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF00C853), // Green A700
    Color(0xFF00E676), // Green A400
  ];
  
  static const List<Color> errorGradient = [
    Color(0xFFFF1744), // Red A400
    Color(0xFFFF5252), // Red A200
  ];
  
  // ELEVATION TINTS (M3 Expressive)
  static Color elevationTintDark(int elevation) {
    switch (elevation) {
      case 0:
        return Colors.transparent;
      case 1:
        return primary.withOpacity(0.05);
      case 2:
        return primary.withOpacity(0.08);
      case 3:
        return primary.withOpacity(0.11);
      case 4:
        return primary.withOpacity(0.12);
      case 5:
        return primary.withOpacity(0.14);
      default:
        return primary.withOpacity(0.14);
    }
  }
  
  static Color elevationTintLight(int elevation) {
    switch (elevation) {
      case 0:
        return Colors.transparent;
      case 1:
        return primaryLight.withOpacity(0.05);
      case 2:
        return primaryLight.withOpacity(0.08);
      case 3:
        return primaryLight.withOpacity(0.11);
      case 4:
        return primaryLight.withOpacity(0.12);
      case 5:
        return primaryLight.withOpacity(0.14);
      default:
        return primaryLight.withOpacity(0.14);
    }
  }
}