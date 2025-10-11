// models/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'home': 'Home',
      'marketplace': 'Marketplace',
      'news': 'Novidades',
      'chat': 'Chat',
      'login': 'Entrar',
      'logout': 'Sair',
    },
    'en': {
      'home': 'Home',
      'marketplace': 'Marketplace',
      'news': 'News',
      'chat': 'Chat',
      'login': 'Login',
      'logout': 'Logout',
    },
    'es': {
      'home': 'Inicio',
      'marketplace': 'Mercado',
      'news': 'Noticias',
      'chat': 'Chat',
      'login': 'Entrar',
      'logout': 'Salir',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
