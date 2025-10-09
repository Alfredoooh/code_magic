import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class LanguagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('languages')!)),
      body: ListView(
        children: [
          ListTile(
            title: Text('English'),
            onTap: () => appProvider.setLocale(const Locale('en', 'US')),
          ),
          ListTile(
            title: Text('Português'),
            onTap: () => appProvider.setLocale(const Locale('pt', 'PT')),
          ),
          // Add all supported languages
        ],
      ),
    );
  }
}