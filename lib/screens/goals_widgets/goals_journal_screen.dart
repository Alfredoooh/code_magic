// lib/screens/goals_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsJournalScreen extends StatefulWidget {
  @override
  _GoalsJournalScreenState createState() => _GoalsJournalScreenState();
}

class _GoalsJournalScreenState extends State<GoalsJournalScreen> {
  final TextEditingController _assetController = TextEditingController();
  final TextEditingController _entryPriceController = TextEditingController();
  final TextEditingController _exitPriceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _tradeType = 'Compra';
  String _result = 'Lucro';

  Future<void> _saveJournalEntry() async {
    if (_assetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira o ativo')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final entryPrice = double.tryParse(_entryPriceController.text) ?? 0;
      final exitPrice = double.tryParse(_exitPriceController.text) ?? 0;
      final profitLoss = _tradeType == 'Compra' 
          ? exitPrice - entryPrice 
          : entryPrice - exitPrice;

      await FirebaseFirestore.instance.collection('journal_entries').add({
        'userId': user.uid,
        'asset': _assetController.text.trim(),
        'tradeType': _tradeType,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'profitLoss': profitLoss,
        'result': _result,
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entrada adicionada ao diário!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar entrada')),
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
          'Diário de Trading',
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
            _buildTextField('Ativo', _assetController, isDark, hint: 'Ex: EUR/USD'),
            SizedBox(height: 20),
            Text(
              'Tipo de Operação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton('Compra', Colors.green, isDark),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton('Venda', Colors.red, isDark),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildTextField('Preço de Entrada', _entryPriceController, isDark, 
                hint: '0.00', keyboardType: TextInputType.number),
            SizedBox(height: 20),
            _buildTextField('Preço de Saída', _exitPriceController, isDark, 
                hint: '0.00', keyboardType: TextInputType.number),
            SizedBox(height: 20),
            Text(
              'Resultado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildResultButton('Lucro', Colors.green, isDark),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildResultButton('Prejuízo', Colors.red, isDark),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildResultButton('Empate', Colors.grey, isDark),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildTextField('Observações', _notesController, isDark, 
                hint: 'Anotações sobre o trade...', maxLines: 4),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveJournalEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF444F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Salvar no Diário',
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

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, 
      {String hint = '', int maxLines = 1, TextInputType? keyboardType}) {
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
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
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

  Widget _buildTypeButton(String type, Color color, bool isDark) {
    final isSelected = _tradeType == type;
    return GestureDetector(
      onTap: () => setState(() => _tradeType = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultButton(String result, Color color, bool isDark) {
    final isSelected = _result == result;
    return GestureDetector(
      onTap: () => setState(() => _result = result),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            result,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _assetController.dispose();
    _entryPriceController.dispose();
    _exitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}