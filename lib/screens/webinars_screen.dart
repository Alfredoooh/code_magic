import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class WebinarsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _webinars = [
    {'title': 'Market Analysis', 'date': '2025-10-10'},
    // Add more
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('webinars')!)),
      body: ListView.builder(
        itemCount: _webinars.length,
        itemBuilder: (context, index) {
          final webinar = _webinars[index];
          return ListTile(
            title: Text(webinar['title']),
            subtitle: Text(webinar['date']),
            trailing: CustomButton(text: AppLocalizations.of(context)!.translate('join')!, onPressed: () {
              // Join logic
            }),
          );
        },
      ),
    );
  }
}