import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 0;
  List<Map<String, dynamic>> _questions = [
    {'question': 'What is P/E?', 'options': ['Price/Earnings', 'Profit/Equity'], 'answer': 0},
    // Add more questions
  ];

  void _answer(int index) {
    // Check answer, update score
    setState(() {
      _currentQuestion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion >= _questions.length) {
      return Center(child: Text(AppLocalizations.of(context)!.translate('quiz_complete')!));
    }
    final q = _questions[_currentQuestion];
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('quiz')!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(q['question'], style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...q['options'].asMap().entries.map((entry) => ListTile(
              title: Text(entry.value),
              onTap: () => _answer(entry.key),
            )),
          ],
        ),
      ),
    );
  }
}