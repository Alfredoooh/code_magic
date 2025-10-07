import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppTheme { light, dark, deepDark }

class ThemeService {
  static AppTheme _currentTheme = AppTheme.dark;
  static final List<VoidCallback> _listeners = [];

  static AppTheme get currentTheme => _currentTheme;

  static ThemeData get currentThemeData {
    switch (_currentTheme) {
      case AppTheme.light:
        return _lightTheme;
      case AppTheme.dark:
        return _darkTheme;
      case AppTheme.deepDark:
        return _deepDarkTheme;
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1877F2),
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    cardColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F2F7),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF000000)),
      titleTextStyle: TextStyle(
        color: Color(0xFF000000),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1877F2),
    scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    cardColor: const Color(0xFF2C2C2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final ThemeData _deepDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1877F2),
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardColor: const Color(0xFF1C1C1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme') ?? 1;
    _currentTheme = AppTheme.values[themeIndex];
  }

  static Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);

    // Salvar no Firestore se usuário logado
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'theme': theme.toString().split('.').last});
    }

    _notifyListeners();
  }

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}
