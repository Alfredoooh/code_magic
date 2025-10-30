// app_typography.dart - Material Design 3 Typography System
import 'package:flutter/material.dart';

// ============================================
// TYPOGRAPHY - M3 EXPRESSIVE TYPE SCALE
// Based on Roboto with adaptive scaling
// ============================================
class AppTypography {
  // Font Family
  static const fontFamily = 'Roboto';
  static const fontFamilyDisplay = 'Roboto'; // Can be changed to display font
  static const fontFamilyMono = 'RobotoMono';

  // Font Weights
  static const thin = FontWeight.w100;
  static const extraLight = FontWeight.w200;
  static const light = FontWeight.w300;
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extraBold = FontWeight.w800;
  static const black = FontWeight.w900;

  // ============================================
  // DISPLAY - Large, prominent text
  // ============================================
  static const displayLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 57,
    fontWeight: regular,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const displayMedium = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 45,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.16,
  );

  static const displaySmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 36,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================
  // HEADLINE - High-emphasis text
  // ============================================
  static const headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.25,
  );

  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.29,
  );

  static const headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================
  // TITLE - Medium-emphasis text
  // ============================================
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.27,
  );

  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================
  // BODY - Standard reading text
  // ============================================
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================
  // LABEL - Small, functional text
  // ============================================
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================
  // CUSTOM VARIANTS - Extended styles
  // ============================================
  
  // Display variants
  static const displayLargeBold = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const displayMediumBold = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.16,
  );

  // Headline variants
  static const headlineLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.25,
  );

  static const headlineMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.29,
  );

  static const headlineSmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title variants
  static const titleLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.27,
  );

  static const titleMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: bold,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const titleSmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: bold,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body variants
  static const bodyLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: bold,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const bodyMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: bold,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const bodySmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: bold,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Monospace variants for code
  static const codeLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.50,
  );

  static const codeMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.43,
  );

  static const codeSmall = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================
  // BUTTON TEXT STYLES
  // ============================================
  static const buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.25,
  );

  static const buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  // ============================================
  // CAPTION & OVERLINE
  // ============================================
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Creates a text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Creates a text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Creates a text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Creates a text style with custom height (line height)
  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  /// Creates a text style with custom letter spacing
  static TextStyle withLetterSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }

  /// Creates an italic variant of the style
  static TextStyle withItalic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Creates an underlined variant of the style
  static TextStyle withUnderline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Creates a line-through variant of the style
  static TextStyle withLineThrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }
}

// ============================================
// TYPOGRAPHY EXTENSIONS
// ============================================
extension TextStyleExtensions on TextStyle {
  /// Makes text bold
  TextStyle get bold => copyWith(fontWeight: AppTypography.bold);
  
  /// Makes text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: AppTypography.semiBold);
  
  /// Makes text medium weight
  TextStyle get medium => copyWith(fontWeight: AppTypography.medium);
  
  /// Makes text light
  TextStyle get light => copyWith(fontWeight: AppTypography.light);
  
  /// Makes text italic
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  
  /// Adds underline
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);
  
  /// Adds line through (strikethrough)
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
  
  /// Sets custom color
  TextStyle withColor(Color color) => copyWith(color: color);
  
  /// Sets custom opacity
  TextStyle withOpacity(double opacity) => copyWith(
    color: color?.withOpacity(opacity),
  );
  
  /// Sets custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
  
  /// Sets custom height
  TextStyle withHeight(double height) => copyWith(height: height);
  
  /// Sets custom letter spacing
  TextStyle withLetterSpacing(double spacing) => copyWith(letterSpacing: spacing);
}

// ============================================
// TEXT THEME HELPER
// ============================================
class AppTextTheme {
  /// Creates a complete Material Design 3 text theme
  static TextTheme createTextTheme({Color? color}) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: color),
      displayMedium: AppTypography.displayMedium.copyWith(color: color),
      displaySmall: AppTypography.displaySmall.copyWith(color: color),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: color),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: color),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: color),
      titleLarge: AppTypography.titleLarge.copyWith(color: color),
      titleMedium: AppTypography.titleMedium.copyWith(color: color),
      titleSmall: AppTypography.titleSmall.copyWith(color: color),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: color),
      bodySmall: AppTypography.bodySmall.copyWith(color: color),
      labelLarge: AppTypography.labelLarge.copyWith(color: color),
      labelMedium: AppTypography.labelMedium.copyWith(color: color),
      labelSmall: AppTypography.labelSmall.copyWith(color: color),
    );
  }
}

// ============================================
// CONTEXT EXTENSION FOR TYPOGRAPHY
// ============================================
extension TypographyContext on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Quick access to common text styles
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
}