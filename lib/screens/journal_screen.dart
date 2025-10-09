import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _noteController = TextEditingController();

  Future<void> _addEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _noteController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('journals').add({
      'userId': user.uid,
      'note': _noteController.text,
      'timestamp': Timestamp.now(),
    });
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('journal')!)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('new_entry')!,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: AppLocalizations.of(context)!.translate('add_entry')!,
                  onPressed: _addEntry,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('journals').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text(AppLocalizations.of(context)!.translate('error_loading')!);
                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                final entries = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(entry['note']),
                      subtitle: Text(entry['timestamp'].toDate().toLocal().toString()),
                    );
                },
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}