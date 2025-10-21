import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppStyles {
  // Cores iOS
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosBlueDark = Color(0xFF0051D5);
  
  // Background
  static const Color bgPrimary = Color(0xFF1C1C1E);
  static const Color bgSecondary = Color(0xFF2C2C2E);
  static const Color border = Color(0xFF38383A);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  
  // Status
  static const Color green = Color(0xFF30D158);
  static const Color red = Color(0xFFFF453A);
  static const Color yellow = Color(0xFFFFD60A);
  
  // Aliases para compatibilidade
  static const Color blue = iosBlue;
  static const Color iosGreen = green;
  
  // Temas
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: iosBlue,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: iosBlue,
      secondary: iosBlueDark,
      surface: bgSecondary,
      background: bgPrimary,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgSecondary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgSecondary,
      selectedItemColor: iosBlue,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontSize: 34, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 17),
      bodyMedium: TextStyle(color: textPrimary, fontSize: 15),
      bodySmall: TextStyle(color: textSecondary, fontSize: 13),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgPrimary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: iosBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: iosBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: iosBlue,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: iosBlue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: iosBlue,
      secondary: iosBlueDark,
      surface: Color(0xFFF2F2F7),
      background: Colors.white,
      error: Color(0xFFFF3B30),
    ),
  );

  // Widgets Customizados
  static Widget tradingButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isActive = false,
  }) {
    return Expanded(
      child: Material(
        color: isActive ? color : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget chipButton({
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Material(
      color: isActive ? iosBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: isActive ? iosBlue : border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  static Widget infoCard({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static Widget loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(iosBlue),
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? red : green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
