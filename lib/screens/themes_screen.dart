import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class ThemesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('themes')!)),
      body: ListView(
        children: [
          ListTile(
            title: Text('Dark'),
            onTap: () => appProvider.setTheme('dark'),
          ),
          ListTile(
            title: Text('Light'),
            onTap: () => appProvider.setTheme('light'),
          ),
          ListTile(
            title: Text('OLED'),
            onTap: () => appProvider.setTheme('oled'),
          ),
          // Custom theme picker
        ],
      ),
    );
  }
}