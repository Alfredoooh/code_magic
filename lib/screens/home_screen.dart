import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/language_service.dart';
import 'admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;

  const HomeScreen({
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  bool _showDrawer = false;
  List<Map<String, dynamic>> _newsArticles = [];
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setUserOnline(true);
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsdata.io/api/1/news?apikey=pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c&language=pt&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        setState(() {
          _newsArticles = results.take(10).map((article) => {
            'title': article['title'] ?? '',
            'image': article['image_url'] ?? '',
            'source': article['source_id'] ?? '',
          }).toList();
          _loadingNews = false;
        });
      }
    } catch (e) {
      setState(() => _loadingNews = false);
    }
  }

  @override
  void dispose() {
    _setUserOnline(false);
    super.dispose();
  }

  void _setUserOnline(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isOnline': isOnline});
    }
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    }
  }

  void _showUserModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
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
              backgroundColor: Color(0xFFFF444F),
              backgroundImage: _userData?['profile_image'] != null && _userData!['profile_image'].isNotEmpty
                  ? NetworkImage(_userData!['profile_image'])
                  : null,
              child: _userData?['profile_image'] == null || _userData!['profile_image'].isEmpty
                  ? Text(
                      (_userData?['username'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              _userData?['username'] ?? 'Usuário',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _userData?['email'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _userData?['pro'] == true ? Color(0xFFFF444F) : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userData?['pro'] == true ? 'PRO' : 'FREEMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (_userData?['admin'] == true)
                    _buildMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Painel Admin',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                        );
                      },
                    ),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsModal();
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_rounded,
                    title: 'Editar Perfil',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.info_rounded,
                    title: 'Sobre',
                    onTap: () {},
                  ),
                  SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Últimas Notícias',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Ver Todas',
                        style: TextStyle(
                          color: Color(0xFFFF444F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _loadingNews
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)))
                    : Container(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newsArticles.length,
                          itemBuilder: (context, index) {
                            final article = _newsArticles[index];
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: article['image'].isNotEmpty
                                        ? Image.network(
                                            article['image'],
                                            width: 100,
                                            height: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) => Container(
                                              width: 100,
                                              height: 160,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 100,
                                            height: 160,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.article, color: Colors.grey),
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFF444F).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              article['source'].toUpperCase(),
                                              style: TextStyle(
                                                color: Color(0xFFFF444F),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            article['title'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                              height: 1.3,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _setUserOnline(false);
                        await FirebaseAuth.instance.signOut();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Sair', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Configurações',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildSettingItem(
                    icon: Icons.dark_mode_rounded,
                    title: 'Tema',
                    subtitle: isDark ? 'Escuro' : 'Claro',
                    onTap: () => _showThemeDialog(),
                  ),
                  _buildSettingItem(
                    icon: Icons.language_rounded,
                    title: 'Idioma',
                    subtitle: _getLanguageName(widget.currentLocale),
                    onTap: () => _showLanguageDialog(),
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notificações',
                    subtitle: 'Ativadas',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolha o tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Claro'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: Theme.of(context).brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
                onChanged: (value) {
                  widget.onThemeChanged(value!);
                  _updateUserTheme('light');
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Escuro'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                onChanged: (value) {
                  widget.onThemeChanged(value!);
                  _updateUserTheme('dark');
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolha o idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Português'),
              onTap: () {
                widget.onLocaleChanged('pt');
                _updateUserLanguage('pt');
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('English'),
              onTap: () {
                widget.onLocaleChanged('en');
                _updateUserLanguage('en');
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Español'),
              onTap: () {
                widget.onLocaleChanged('es');
                _updateUserLanguage('es');
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateUserTheme(String theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'theme': theme});
    }
  }

  void _updateUserLanguage(String language) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'language': language});
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Português';
    }
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFFFF444F)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFFFF444F)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => setState(() => _showDrawer = true),
        ),
        title: Text(
          'K Paga',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: _showUserModal,
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFF444F),
                backgroundImage: _userData?['profile_image'] != null && _userData!['profile_image'].isNotEmpty
                    ? NetworkImage(_userData!['profile_image'])
                    : null,
                child: _userData?['profile_image'] == null || _userData!['profile_image'].isEmpty
                    ? Text(
                        (_userData?['username'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF444F).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tokens Disponíveis',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 24),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '${_userData?['tokens'] ?? 0}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_userData?['pro'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Conta PRO - Tokens Ilimitados',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Expira em: ${_getExpirationDate()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.chat_rounded,
                        title: 'Mensagens',
                        value: '0',
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.group_rounded,
                        title: 'Grupos',
                        value: '0',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Últimas Notícias',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Ver Todas',
                        style: TextStyle(
                          color: Color(0xFFFF444F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _loadingNews
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)))
                    : Container(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newsArticles.length,
                          itemBuilder: (context, index) {
                            final article = _newsArticles[index];
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: article['image'].isNotEmpty
                                        ? Image.network(
                                            article['image'],
                                            width: 100,
                                            height: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) => Container(
                                              width: 100,
                                              height: 160,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 100,
                                            height: 160,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.article, color: Colors.grey),
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFF444F).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              article['source'].toUpperCase(),
                                              style: TextStyle(
                                                color: Color(0xFFFF444F),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            article['title'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                              height: 1.3,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                SizedBox(height: 24),
                Text(
                  'Publicações Recentes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                    }

                    final posts = snapshot.data!.docs;

                    if (posts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.article_rounded, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma publicação ainda',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index].data() as Map<String, dynamic>;
                        return _buildPostCard(post, isDark);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          if (_showDrawer)
            GestureDetector(
              onTap: () => setState(() => _showDrawer = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Opções',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
                                    onPressed: () => setState(() => _showDrawer = false),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  _buildDrawerItem(Icons.home_rounded, 'Home', () {}),
                                  _buildDrawerItem(Icons.info_rounded, 'Sobre', () {}),
                                  _buildDrawerItem(Icons.help_rounded, 'Ajuda', () {}),
                                  _buildDrawerItem(Icons.policy_rounded, 'Política de Privacidade', () {}),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['image'] != null && post['image'].isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                post['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_rounded, size: 60, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFFF444F),
                      child: Text(
                        (post['userName'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      post['userName'] ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  post['content'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite_border_rounded, color: Colors.grey),
                      onPressed: () {},
                    ),
                    Text('${post['likes'] ?? 0}', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.comment_rounded, color: Colors.grey),
                      onPressed: () {},
                    ),
                    Text('${post['comments'] ?? 0}', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFFFF444F)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        onTap: () {
          setState(() => _showDrawer = false);
          onTap();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getExpirationDate() {
    if (_userData?['expiration_date'] == null) return 'N/A';
    try {
      final date = DateTime.parse(_userData!['expiration_date']);
      final diff = date.difference(DateTime.now()).inDays;
      return '$diff dias';
    } catch (e) {
      return 'N/A';
    }
  }
}