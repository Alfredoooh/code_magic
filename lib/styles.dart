import 'package:flutter/material.dart';

// Material Design 3 Expressive - Tema Claro e Escuro
class AppStyles {
  // Cores MD3 Expressive - Tema Claro
  static const Color lightPrimary = Color(0xFF0061A4);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFD1E4FF);
  static const Color lightOnPrimaryContainer = Color(0xFF001D36);
  
  static const Color lightSecondary = Color(0xFF535F70);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFD7E3F7);
  static const Color lightOnSecondaryContainer = Color(0xFF101C2B);
  
  static const Color lightTertiary = Color(0xFF6B5778);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFF2DAFF);
  static const Color lightOnTertiaryContainer = Color(0xFF251431);
  
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF410002);
  
  static const Color lightBackground = Color(0xFFFDFCFF);
  static const Color lightOnBackground = Color(0xFF1A1C1E);
  static const Color lightSurface = Color(0xFFFDFCFF);
  static const Color lightOnSurface = Color(0xFF1A1C1E);
  static const Color lightSurfaceVariant = Color(0xFFDFE2EB);
  static const Color lightOnSurfaceVariant = Color(0xFF43474E);
  
  // Cores MD3 Expressive - Tema Escuro (Profundo)
  static const Color darkPrimary = Color(0xFF9ECAFF);
  static const Color darkOnPrimary = Color(0xFF003258);
  static const Color darkPrimaryContainer = Color(0xFF00497D);
  static const Color darkOnPrimaryContainer = Color(0xFFD1E4FF);
  
  static const Color darkSecondary = Color(0xFFBBC7DB);
  static const Color darkOnSecondary = Color(0xFF253140);
  static const Color darkSecondaryContainer = Color(0xFF3B4858);
  static const Color darkOnSecondaryContainer = Color(0xFFD7E3F7);
  
  static const Color darkTertiary = Color(0xFFD6BEE4);
  static const Color darkOnTertiary = Color(0xFF3B2948);
  static const Color darkTertiaryContainer = Color(0xFF523F5F);
  static const Color darkOnTertiaryContainer = Color(0xFFF2DAFF);
  
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  
  // Fundo escuro profundo (não cinza claro)
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkOnBackground = Color(0xFFE2E2E5);
  static const Color darkSurface = Color(0xFF0F1419);
  static const Color darkOnSurface = Color(0xFFE2E2E5);
  
  // Cards e modais mais claros que o fundo (mas não muito claros)
  static const Color darkSurfaceVariant = Color(0xFF1C1F24);
  static const Color darkOnSurfaceVariant = Color(0xFFC3C7CF);
  static const Color darkSurfaceContainer = Color(0xFF1A1D22);
  static const Color darkSurfaceContainerHigh = Color(0xFF25282D);

  // Tema Claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: lightOnPrimaryContainer,
      secondary: lightSecondary,
      onSecondary: lightOnSecondary,
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: lightOnSecondaryContainer,
      tertiary: lightTertiary,
      onTertiary: lightOnTertiary,
      tertiaryContainer: lightTertiaryContainer,
      onTertiaryContainer: lightOnTertiaryContainer,
      error: lightError,
      onError: lightOnError,
      errorContainer: lightErrorContainer,
      onErrorContainer: lightOnErrorContainer,
      background: lightBackground,
      onBackground: lightOnBackground,
      surface: lightSurface,
      onSurface: lightOnSurface,
      surfaceVariant: lightSurfaceVariant,
      onSurfaceVariant: lightOnSurfaceVariant,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: appBarTheme(true),
    cardTheme: cardTheme(true),
    elevatedButtonTheme: elevatedButtonTheme(true),
    outlinedButtonTheme: outlinedButtonTheme(true),
    textButtonTheme: textButtonTheme(true),
    inputDecorationTheme: inputDecorationTheme(true),
    floatingActionButtonTheme: fabTheme(true),
    dialogTheme: dialogTheme(true),
    snackBarTheme: snackBarTheme(true),
  );

  // Tema Escuro
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: darkOnSecondary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: darkOnSecondaryContainer,
      tertiary: darkTertiary,
      onTertiary: darkOnTertiary,
      tertiaryContainer: darkTertiaryContainer,
      onTertiaryContainer: darkOnTertiaryContainer,
      error: darkError,
      onError: darkOnError,
      errorContainer: darkErrorContainer,
      onErrorContainer: darkOnErrorContainer,
      background: darkBackground,
      onBackground: darkOnBackground,
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceVariant: darkSurfaceVariant,
      onSurfaceVariant: darkOnSurfaceVariant,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: appBarTheme(false),
    cardTheme: cardTheme(false),
    elevatedButtonTheme: elevatedButtonTheme(false),
    outlinedButtonTheme: outlinedButtonTheme(false),
    textButtonTheme: textButtonTheme(false),
    inputDecorationTheme: inputDecorationTheme(false),
    floatingActionButtonTheme: fabTheme(false),
    dialogTheme: dialogTheme(false),
    snackBarTheme: snackBarTheme(false),
  );

  // AppBar Theme
  static AppBarTheme appBarTheme(bool isLight) => AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: isLight ? lightSurface : darkSurface,
    foregroundColor: isLight ? lightOnSurface : darkOnSurface,
    surfaceTintColor: isLight ? lightPrimary : darkPrimary,
  );

  // Card Theme
  static CardTheme cardTheme(bool isLight) => CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: isLight ? lightSurface : darkSurfaceContainerHigh,
    surfaceTintColor: isLight ? lightPrimary : darkPrimary,
  );

  // Elevated Button Theme
  static ElevatedButtonThemeData elevatedButtonTheme(bool isLight) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isLight ? lightPrimary : darkPrimary,
          foregroundColor: isLight ? lightOnPrimary : darkOnPrimary,
        ),
      );

  // Outlined Button Theme
  static OutlinedButtonThemeData outlinedButtonTheme(bool isLight) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: isLight ? lightPrimary : darkPrimary,
          ),
          foregroundColor: isLight ? lightPrimary : darkPrimary,
        ),
      );

  // Text Button Theme
  static TextButtonThemeData textButtonTheme(bool isLight) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: isLight ? lightPrimary : darkPrimary,
        ),
      );

  // Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme(bool isLight) =>
      InputDecorationTheme(
        filled: true,
        fillColor: isLight ? lightSurfaceVariant : darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? lightPrimary : darkPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? lightError : darkError,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? lightError : darkError,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isLight ? lightOnSurfaceVariant : darkOnSurfaceVariant,
        ),
        hintStyle: TextStyle(
          color: isLight ? lightOnSurfaceVariant.withOpacity(0.6) 
                        : darkOnSurfaceVariant.withOpacity(0.6),
        ),
      );

  // FloatingActionButton Theme
  static FloatingActionButtonThemeData fabTheme(bool isLight) =>
      FloatingActionButtonThemeData(
        elevation: 3,
        backgroundColor: isLight ? lightPrimaryContainer : darkPrimaryContainer,
        foregroundColor: isLight ? lightOnPrimaryContainer : darkOnPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );

  // Dialog Theme
  static DialogTheme dialogTheme(bool isLight) => DialogTheme(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    backgroundColor: isLight ? lightSurface : darkSurfaceContainerHigh,
    surfaceTintColor: isLight ? lightPrimary : darkPrimary,
  );

  // SnackBar Theme
  static SnackBarThemeData snackBarTheme(bool isLight) => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    backgroundColor: isLight ? lightOnSurface : darkOnSurface,
    contentTextStyle: TextStyle(
      color: isLight ? lightSurface : darkSurface,
    ),
  );

  // Text Styles
  static TextStyle displayLarge(bool isLight) => TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle displayMedium(bool isLight) => TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle displaySmall(bool isLight) => TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle headlineLarge(bool isLight) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle headlineMedium(bool isLight) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle headlineSmall(bool isLight) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle titleLarge(bool isLight) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle titleMedium(bool isLight) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle titleSmall(bool isLight) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle bodyLarge(bool isLight) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle bodyMedium(bool isLight) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle bodySmall(bool isLight) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: isLight ? lightOnSurfaceVariant : darkOnSurfaceVariant,
  );

  static TextStyle labelLarge(bool isLight) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle labelMedium(bool isLight) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: isLight ? lightOnBackground : darkOnBackground,
  );

  static TextStyle labelSmall(bool isLight) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: isLight ? lightOnBackground : darkOnBackground,
  );
}