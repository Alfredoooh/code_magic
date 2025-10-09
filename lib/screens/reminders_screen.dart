import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _titleController = TextEditingController();
  DateTime _reminderDate = DateTime.now();

  Future<void> _addReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _titleController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('reminders').add({
      'userId': user.uid,
      'title': _titleController.text,
      'date': Timestamp.fromDate(_reminderDate),
    });
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('reminders')!)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomTextField(controller: _titleController, label: AppLocalizations.of(context)!.translate('title')!, icon: Icons.title_rounded),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text(AppLocalizations.of(context)!.translate('date')!)),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: _reminderDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (date != null) setState(() => _reminderDate = date);
                      },
                      child: Text(_reminderDate.toIso8601String().split('T')[0]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(text: AppLocalizations.of(context)!.translate('add_reminder')!, onPressed: _addReminder),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reminders').where('userId', isEqualTo: userId).orderBy('date').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text(AppLocalizations.of(context)!.translate('error_loading')!);
                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                final reminders = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(reminder['title']),
                      subtitle: Text(reminder['date'].toDate().toLocal().toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: () {
                          FirebaseFirestore.instance.collection('reminders').doc(reminders[index].id).delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}