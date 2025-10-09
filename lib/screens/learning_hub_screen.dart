import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class LearningHubScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _courses = [
    {'title': 'Beginner Trading', 'lessons': 10},
    // Add more
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('learning')!)),
      body: ListView.builder(
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return ListTile(
            title: Text(course['title']),
            subtitle: Text('${course['lessons']} lessons'),
            onTap: () {
              // Open course details
            },
          );
        },
      ),
    );
  }
}