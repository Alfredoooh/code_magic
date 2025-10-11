// models/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFFFF444F),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: Colors.grey[300]!,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0E0E0E)),
      titleTextStyle: TextStyle(
        color: Color(0xFF0E0E0E),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFFFF444F),
    scaffoldBackgroundColor: Color(0xFF0E0E0E),
    cardColor: Color(0xFF1C1C1E),
    dividerColor: Color(0xFF38383A),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
