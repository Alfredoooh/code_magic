import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class IntegrationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('integrations')!)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text('Binance'),
            trailing: CustomButton(text: AppLocalizations.of(context)!.translate('connect')!, onPressed: () {
              // Connect logic
            }),
          ),
          // Add more integrations
        ],
      ),
    );
  }
}