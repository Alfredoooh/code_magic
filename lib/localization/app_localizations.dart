import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_de.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<void> load() async {
    switch (locale.languageCode) {
      case 'en':
        _localizedStrings = en;
        break;
      case 'pt':
        _localizedStrings = pt;
        break;
      case 'es':
        _localizedStrings = es;
        break;
      case 'fr':
        _localizedStrings = fr;
        break;
      case 'de':
        _localizedStrings = de;
        break;
      case 'it':
        _localizedStrings = it;
        break;
      case 'ru':
        _localizedStrings = ru;
        break;
      case 'zh':
        _localizedStrings = zh;
        break;
      case 'ja':
        _localizedStrings = ja;
        break;
      case 'ko':
        _localizedStrings = ko;
        break;
      default:
        _localizedStrings = en;
    }
  }

  String? translate(String key) {
    return _localizedStrings[key];
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'pt', 'es', 'fr', 'de', 'it', 'ru', 'zh', 'ja', 'ko'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
