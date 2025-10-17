// lib/screens/goals_add_note_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsAddNoteScreen extends StatefulWidget {
  @override
  _GoalsAddNoteScreenState createState() => _GoalsAddNoteScreenState();
}

class _GoalsAddNoteScreenState extends State<GoalsAddNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _noteColor = 'yellow';

  final Map<String, Color> _colors = {
    'yellow': Color(0xFFFFF3CD),
    'blue': Color(0xFFCCE5FF),
    'green': Color(0xFFD4EDDA),
    'pink': Color(0xFFF8D7DA),
    'purple': Color(0xFFE7D9F5),
  };

  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, escreva algo')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('notes').add({
        'userId': user.uid,
        'title': _titleController.text.trim().isEmpty ? 'Nota sem título' : _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'color': _noteColor,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nota salva com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar nota')),
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
          'Nova Nota',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, color: Color(0xFFFF444F)),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: _colors.entries.map((entry) {
                final isSelected = _noteColor == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _noteColor = entry.key),
                  child: Container(
                    margin: EdgeInsets.only(right: 12),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Color(0xFFFF444F) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _colors[_noteColor],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Título (opcional)',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText: 'Escreva sua nota...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}