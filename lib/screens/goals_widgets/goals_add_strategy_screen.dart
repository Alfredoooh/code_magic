// lib/screens/goals_add_strategy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsAddStrategyScreen extends StatefulWidget {
  @override
  _GoalsAddStrategyScreenState createState() => _GoalsAddStrategyScreenState();
}

class _GoalsAddStrategyScreenState extends State<GoalsAddStrategyScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _exitController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _takeProfitController = TextEditingController();
  String _strategyType = 'Scalping';

  final List<String> _types = ['Scalping', 'Day Trade', 'Swing Trade', 'Position Trade'];

  Future<void> _saveStrategy() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira um título')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('strategies').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _strategyType,
        'entryRule': _entryController.text.trim(),
        'exitRule': _exitController.text.trim(),
        'stopLoss': _stopLossController.text.trim(),
        'takeProfit': _takeProfitController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estratégia criada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar estratégia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nova Estratégia',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Título', _titleController, isDark, maxLines: 1),
            SizedBox(height: 20),
            Text(
              'Tipo de Estratégia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((type) {
                final isSelected = _strategyType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: Color(0xFFFF444F),
                  backgroundColor: isDark ? Color(0xFF2C2C2E) : Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    setState(() => _strategyType = type);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            _buildTextField('Descrição', _descriptionController, isDark, maxLines: 3),
            SizedBox(height: 20),
            _buildTextField('Regra de Entrada', _entryController, isDark, maxLines: 2),
            SizedBox(height: 20),
            _buildTextField('Regra de Saída', _exitController, isDark, maxLines: 2),
            SizedBox(height: 20),
            _buildTextField('Stop Loss', _stopLossController, isDark, maxLines: 1),
            SizedBox(height: 20),
            _buildTextField('Take Profit', _takeProfitController, isDark, maxLines: 1),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveStrategy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF444F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Criar Estratégia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Color(0xFF2C2C2E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _entryController.dispose();
    _exitController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }
}