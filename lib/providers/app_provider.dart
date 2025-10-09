import 'package:flutter/material.dart';
import '../widgets/design_system.dart';

class AppProvider with ChangeNotifier {
  ThemeData _currentTheme = darkTheme;
  Locale _locale = const Locale('pt', 'PT');

  ThemeData get currentTheme => _currentTheme;
  Locale get locale => _locale;

  void setTheme(String themeName) {
    switch (themeName) {
      case 'dark':
        _currentTheme = darkTheme;
        break;
      case 'light':
        _currentTheme = lightTheme;
        break;
      case 'oled':
        _currentTheme = oledTheme;
        break;
    }
    notifyListeners();
  }

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}
