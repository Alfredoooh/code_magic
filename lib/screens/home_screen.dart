import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tabs/inicio_tab.dart';
import 'tabs/hub_tab.dart';
import 'tabs/conversor_tab.dart';
import 'tabs/atualidade_tab.dart';
import 'tabs/chats_tab.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
 
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final List<Widget> _tabs = [
    InicioTab(),
    HubTab(),
    ConversorTab(),
    AtualidadeTab(),
    ChatsTab(),
  ];

  void _showUserMenu() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Buscar dados do usuário
    final userData = await _firestore.collection('users').doc(user.uid).get();
    final data = userData.data() ?? {};

    // Criar JSON com todos os dados
    final jsonData = {
      'userId': user.uid,
      'email': user.email,
      'name': data['name'] ?? user.displayName,
      'age': data['age'],
      'gender': data['gender'],
      'phone': data['phone'],
      'city': data['city'],
      'createdAt': data['createdAt']?.toString(),
      'lastActive': data['lastActive']?.toString(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFFF8C42),
              child: Text(
                (data['name'] ?? user.email ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              data['name'] ?? user.displayName ?? 'Usuário',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              user.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            
            // Botão Exportar Dados
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportUserData(jsonData),
                icon: Icon(Icons.upload_rounded),
                label: Text('Exportar Dados'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Botão Sair
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _auth.signOut();
                },
                icon: Icon(Icons.logout_rounded),
                label: Text('Sair'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUserData(Map<String, dynamic> jsonData) async {
    try {
      // Salvar no Firestore para o admin
      await _firestore.collection('user_exports').add({
        'adminEmail': 'alfredopjonas@gmail.com',
        'userData': jsonData,
        'exportedAt': FieldValue.serverTimestamp(),
      });

      // Fechar modal
      Navigator.pop(context);

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Dados exportados com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Atualizar última atividade
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar dados'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          
          // Atualizar última atividade
          if (user != null) {
            _firestore.collection('users').doc(user.uid).update({
              'lastActive': FieldValue.serverTimestamp(),
            });
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFFF8C42).withOpacity(0.2),
        elevation: 3,
        height: 80,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFFF8C42)),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_rounded),
            selectedIcon: Icon(Icons.hub_rounded, color: Color(0xFFFF8C42)),
            label: 'Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_rounded),
            selectedIcon: Icon(Icons.currency_exchange_rounded, color: Color(0xFFFF8C42)),
            label: 'Conversor',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_rounded),
            selectedIcon: Icon(Icons.newspaper_rounded, color: Color(0xFFFF8C42)),
            label: 'Atualidade',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_rounded),
            selectedIcon: Icon(Icons.chat_rounded, color: Color(0xFFFF8C42)),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}
