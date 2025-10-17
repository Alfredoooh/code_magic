// lib/screens/goals_checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsChecklistScreen extends StatefulWidget {
  @override
  _GoalsChecklistScreenState createState() => _GoalsChecklistScreenState();
}

class _GoalsChecklistScreenState extends State<GoalsChecklistScreen> {
  final TextEditingController _itemController = TextEditingController();

  final List<Map<String, dynamic>> _defaultItems = [
    {'title': 'Revisar análise técnica', 'checked': false},
    {'title': 'Verificar calendário econômico', 'checked': false},
    {'title': 'Definir stop loss e take profit', 'checked': false},
    {'title': 'Revisar gestão de risco', 'checked': false},
    {'title': 'Atualizar diário de trading', 'checked': false},
  ];

  Future<void> _addCustomItem() async {
    if (_itemController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('checklist_items').add({
        'userId': user.uid,
        'title': _itemController.text.trim(),
        'checked': false,
        'date': Timestamp.fromDate(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _itemController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item adicionado!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar item')),
      );
    }
  }

  Future<void> _toggleItem(String docId, bool currentValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('checklist_items')
          .doc(docId)
          .update({'checked': !currentValue});
    } catch (e) {
      print('Erro ao atualizar item: $e');
    }
  }

  Future<void> _deleteItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('checklist_items').doc(docId).delete();
    } catch (e) {
      print('Erro ao deletar item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

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
          'Checklist Diário',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Adicionar novo item...',
                      filled: true,
                      fillColor: isDark ? Color(0xFF2C2C2E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    onSubmitted: (_) => _addCustomItem(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add_rounded, color: Colors.white),
                    onPressed: _addCustomItem,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? Color(0xFF1C1C1E).withOpacity(0.5) : Colors.white.withOpacity(0.5),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Itens Padrão',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _defaultItems.length,
              itemBuilder: (context, index) {
                final item = _defaultItems[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    value: item['checked'],
                    onChanged: (value) {
                      setState(() {
                        _defaultItems[index]['checked'] = value ?? false;
                      });
                    },
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        decoration: item['checked'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    activeColor: Color(0xFFFF444F),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
          if (user != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? Color(0xFF1C1C1E).withOpacity(0.5) : Colors.white.withOpacity(0.5),
              child: Row(
                children: [
                  Icon(Icons.star_outline_rounded, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Itens Personalizados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('checklist_items')
                    .where('userId', isEqualTo: user.uid)
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                    .orderBy('date')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Nenhum item personalizado ainda',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final doc = items[index];
                      final item = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: item['checked'] ?? false,
                          onChanged: (value) {
                            _toggleItem(docId, item['checked'] ?? false);
                          },
                          title: Text(
                            item['title'] ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              decoration: (item['checked'] ?? false) 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          secondary: IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () => _deleteItem(docId),
                          ),
                          activeColor: Color(0xFFFF444F),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }
}