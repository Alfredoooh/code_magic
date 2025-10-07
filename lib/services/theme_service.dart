import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static String _currentTheme = 'light';
  static final List<VoidCallback> _listeners = [];

  static String get currentTheme => _currentTheme;

  static bool get isDarkMode => _currentTheme != 'light';

  static Color get backgroundColor {
    switch (_currentTheme) {
      case 'light':
        return Colors.white;
      case 'dark':
        return const Color(0xFF1C1C1E);
      case 'deep_dark':
        return const Color(0xFF000000);
      default:
        return Colors.white;
    }
  }

  static Color get textColor {
    return _currentTheme == 'light' ? Colors.black : Colors.white;
  }

  static Color get cardColor {
    switch (_currentTheme) {
      case 'light':
        return Colors.grey[100]!;
      case 'dark':
        return const Color(0xFF2C2C2E);
      case 'deep_dark':
        return const Color(0xFF1C1C1E);
      default:
        return Colors.grey[100]!;
    }
  }

  static ThemeData getThemeData() {
    switch (_currentTheme) {
      case 'light':
        return ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF1877F2),
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.grey[100],
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
          ),
        );
      case 'dark':
        return ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1877F2),
          scaffoldBackgroundColor: const Color(0xFF1C1C1E),
          cardColor: const Color(0xFF2C2C2E),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case 'deep_dark':
        return ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1877F2),
          scaffoldBackgroundColor: const Color(0xFF000000),
          cardColor: const Color(0xFF1C1C1E),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      default:
        return ThemeData.light();
    }
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('theme') ?? 'light';
  }

  static Future<void> setTheme(String theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
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
