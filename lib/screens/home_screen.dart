import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final String language;

  const HomeScreen({required this.language});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;
  bool _isDrawerOpen = false;
  Map<String, dynamic>? _userData;
  int _activeUsers = 0;
  int _totalMessages = 0;
  int _totalGroups = 0;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _drawerAnimation = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
    _loadUserData();
    _loadStats();
    _startActiveUsersListener();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  Future<void> _loadStats() async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .get();
    final groupsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .get();

    if (mounted) {
      setState(() {
        _totalMessages = messagesSnapshot.docs.length;
        _totalGroups = groupsSnapshot.docs.length;
      });
    }
  }

  void _startActiveUsersListener() {
    Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('last_active', isGreaterThan: DateTime.now().subtract(Duration(minutes: 5)))
          .get();
      if (mounted) {
        setState(() {
          _activeUsers = snapshot.docs.length;
        });
      }
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
    if (_isDrawerOpen) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  Future<void> _updateTheme(String theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'theme': theme});
      ChatApp.appKey.currentState?.updateTheme(theme);
      setState(() {
        _userData?['theme'] = theme;
      });
    }
  }

  Future<void> _updateLanguage(String language) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'language': language});
      ChatApp.appKey.currentState?.updateLanguage(language);
      setState(() {
        _userData?['language'] = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu_rounded),
          onPressed: _toggleDrawer,
        ),
        title: Text(
          'K Paga',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _showProfileModal,
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  _userData?['profile_image'] ?? 
                  'https://ui-avatars.com/api/?name=${user?.displayName ?? 'User'}&background=FF444F&color=fff',
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bem-vindo, ${_userData?['username'] ?? user?.displayName ?? "Usuário"}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _userData?['is_pro'] == true ? 'Conta PRO' : 'Conta Gratuita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _userData?['is_pro'] == true 
                        ? Color(0xFFFFD700)
                        : Colors.grey,
                  ),
                ),
                SizedBox(height: 32),
                _buildStatCard(
                  'Usuários Ativos',
                  _activeUsers.toString(),
                  Icons.people_rounded,
                  Color(0xFFFF444F),
                ),
                SizedBox(height: 16),
                _buildStatCard(
                  'Total de Mensagens',
                  _totalMessages.toString(),
                  Icons.chat_rounded,
                  Color(0xFF4CAF50),
                ),
                SizedBox(height: 16),
                _buildStatCard(
                  'Grupos Criados',
                  _totalGroups.toString(),
                  Icons.group_rounded,
                  Color(0xFF2196F3),
                ),
                SizedBox(height: 16),
                _buildStatCard(
                  'Tokens Restantes',
                  _userData?['is_pro'] == true 
                      ? 'Ilimitado' 
                      : '${(_userData?['max_daily_tokens'] ?? 50) - (_userData?['tokens_used_today'] ?? 0)}',
                  Icons.token_rounded,
                  Color(0xFFFFA726),
                ),
                if (_userData?['is_pro'] != true) ...[
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.star_rounded, size: 48, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Upgrade para PRO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tokens ilimitados, criar grupos e muito mais!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black54,
              ),
            ),
          SlideTransition(
            position: _drawerAnimation,
            child: _buildCustomDrawer(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDrawer(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Opções',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerSection('Tema'),
                    _buildDrawerOption(
                      'Tema Escuro',
                      Icons.dark_mode_rounded,
                      () => _updateTheme('dark'),
                      selected: _userData?['theme'] == 'dark',
                    ),
                    _buildDrawerOption(
                      'Tema Claro',
                      Icons.light_mode_rounded,
                      () => _updateTheme('light'),
                      selected: _userData?['theme'] == 'light',
                    ),
                    SizedBox(height: 16),
                    _buildDrawerSection('Idioma'),
                    _buildDrawerOption(
                      'Português',
                      Icons.language_rounded,
                      () => _updateLanguage('pt'),
                      selected: _userData?['language'] == 'pt',
                    ),
                    _buildDrawerOption(
                      'English',
                      Icons.language_rounded,
                      () => _updateLanguage('en'),
                      selected: _userData?['language'] == 'en',
                    ),
                    _buildDrawerOption(
                      'Español',
                      Icons.language_rounded,
                      () => _updateLanguage('es'),
                      selected: _userData?['language'] == 'es',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDrawerOption(String title, IconData icon, VoidCallback onTap, {bool selected = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Color(0xFFFF444F) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Color(0xFFFF444F) : null,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: selected ? Icon(Icons.check_rounded, color: Color(0xFFFF444F)) : null,
      onTap: () {
        onTap();
        _toggleDrawer();
      },
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _userData?['profile_image'] ?? 
                'https://ui-avatars.com/api/?name=${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}&background=FF444F&color=fff',
              ),
            ),
            SizedBox(height: 16),
            Text(
              _userData?['username'] ?? 'Usuário',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              _userData?['email'] ?? '',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _userData?['is_pro'] == true 
                    ? Color(0xFFFFD700).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userData?['is_pro'] == true ? 'PRO' : 'GRATUITO',
                style: TextStyle(
                  color: _userData?['is_pro'] == true 
                      ? Color(0xFFFFD700)
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                },
                icon: Icon(Icons.logout_rounded, color: Colors.white),
                label: Text('Sair', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF444F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }
}