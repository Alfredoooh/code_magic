import 'package:flutter/material.dart';
import '../models/strategy_model.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StrategiesScreen extends StatefulWidget {
  @override
  _StrategiesScreenState createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();

  Future<void> _createStrategy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('strategies').add({
      'userId': user.uid,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'code': _codeController.text,
      'price': 0.0,
      'rating': 0.0,
      'reviews': 0,
    });
    _nameController.clear();
    _descriptionController.clear();
    _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('strategies')!)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomTextField(controller: _nameController, label: AppLocalizations.of(context)!.translate('name')!, icon: Icons.label_rounded),
                const SizedBox(height: 16),
                CustomTextField(controller: _descriptionController, label: AppLocalizations.of(context)!.translate('description')!, icon: Icons.description_rounded),
                const SizedBox(height: 16),
                CustomTextField(controller: _codeController, label: AppLocalizations.of(context)!.translate('code')!, icon: Icons.code_rounded, maxLines: 10),
                const SizedBox(height: 16),
                CustomButton(text: AppLocalizations.of(context)!.translate('create_strategy')!, onPressed: _createStrategy),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('strategies').where('userId', isEqualTo: userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text(AppLocalizations.of(context)!.translate('error_loading')!);
                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                final strategies = snapshot.data!.docs.map((doc) => StrategyModel.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
                return ListView.builder(
                  itemCount: strategies.length,
                  itemBuilder: (context, index) {
                    final strategy = strategies[index];
                    return ListTile(
                      title: Text(strategy.name),
                      subtitle: Text(strategy.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () {
                          // Edit strategy
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
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}