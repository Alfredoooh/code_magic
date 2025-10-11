// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLocaleChanged;

  HomeScreen({
    this.userData,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showUserModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  widget.userData?['profile_image'] ??
                      'https://alfredoooh.github.io/database/gallery/app_icon.png',
                ),
              ),
              SizedBox(height: 16),
              Text(
                widget.userData?['full_name'] ?? 'Usuário',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
              SizedBox(height: 4),
              Text(
                widget.userData?['email'] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.userData?['isPro'] == true
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.userData?['isPro'] == true ? 'PRO' : 'FREEMIUM',
                  style: TextStyle(
                    color: widget.userData?['isPro'] == true
                        ? Colors.amber
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (widget.userData?['isAdmin'] == true)
                      _buildModalItem(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Painel Admin',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => AdminPanelScreen(),
                            ),
                          );
                        },
                      ),
                    _buildModalItem(
                      icon: Icons.settings_rounded,
                      title: 'Configurações',
                      onTap: () {
                        Navigator.pop(context);
                        _showSettingsModal();
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.logout_rounded,
                      title: 'Sair',
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pop(context);
                      },
                      isDestructive: true,
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

  Widget _buildModalItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive
                      ? Color(0xFFFF444F)
                      : isDark
                          ? Colors.white
                          : Color(0xFF0E0E0E),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Color(0xFFFF444F)
                        : isDark
                            ? Colors.white
                            : Color(0xFF0E0E0E),
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
              SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSettingItem(
                      icon: Icons.dark_mode_rounded,
                      title: 'Tema',
                      trailing: CupertinoSegmentedControl<String>(
                        padding: EdgeInsets.all(4),
                        selectedColor: Color(0xFFFF444F),
                        borderColor: Color(0xFFFF444F),
                        children: {
                          'light': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Claro', style: TextStyle(fontSize: 12)),
                          ),
                          'dark': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Escuro', style: TextStyle(fontSize: 12)),
                          ),
                        },
                        groupValue: isDark ? 'dark' : 'light',
                        onValueChanged: (value) {
                          widget.onThemeChanged(
                            value == 'light' ? ThemeMode.light : ThemeMode.dark,
                          );
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .update({'theme': value});
                        },
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: 'Idioma',
                      trailing: CupertinoSegmentedControl<String>(
                        padding: EdgeInsets.all(4),
                        selectedColor: Color(0xFFFF444F),
                        borderColor: Color(0xFFFF444F),
                        children: {
                          'pt': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('PT', style: TextStyle(fontSize: 12)),
                          ),
                          'en': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('EN', style: TextStyle(fontSize: 12)),
                          ),
                          'es': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('ES', style: TextStyle(fontSize: 12)),
                          ),
                        },
                        groupValue: widget.userData?['language'] ?? 'pt',
                        onValueChanged: (value) {
                          widget.onLocaleChanged(
                            Locale(value, value == 'pt' ? 'PT' : value == 'en' ? 'US' : 'ES'),
                          );
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .update({'language': value});
                        },
                      ),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFF444F)),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Color(0xFF0E0E0E),
            ),
          ),
          Spacer(),
          trailing,
        ],
      ),
    );
  }

  void _showSearchScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF38383A) : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        middle: Text(
          'K Paga',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Color(0xFF0E0E0E),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showSearchScreen,
              child: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white : Color(0xFF0E0E0E),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showUserModal,
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  widget.userData?['profile_image'] ??
                      'https://alfredoooh.github.io/database/gallery/app_icon.png',
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Card de Tokens e Status
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF444F), Color(0xFFFF6B75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Minha Carteira',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tokens Disponíveis',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${widget.userData?['tokens'] ?? 0}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (widget.userData?['isPro'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (widget.userData?['isPro'] != true) ...[
                    SizedBox(height: 16),
                    Text(
                      'Limite diário: 50 tokens',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  if (widget.userData?['expiration_date'] != null) ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Expira em: ${widget.userData?['expiration_date']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Título de Publicações
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Publicações Recentes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Lista de Publicações (Posts)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CupertinoActivityIndicator(),
                  );
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.article_rounded,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Nenhuma publicação ainda',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: posts.map((post) {
                    final data = post.data() as Map<String, dynamic>;
                    return _buildPostCard(data, post.id);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data, String postId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => PostDetailScreen(postId: postId, data: data),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        data['user_image'] ??
                            'https://alfredoooh.github.io/database/gallery/app_icon.png',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['user_name'] ?? 'Usuário',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Color(0xFF0E0E0E),
                            ),
                          ),
                          Text(
                            _formatTimestamp(data['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (data['image_url'] != null) ...[
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['image_url'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                SizedBox(height: 12),
                Text(
                  data['content'] ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Color(0xFF0E0E0E),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 20, color: Color(0xFFFF444F)),
                    SizedBox(width: 4),
                    Text(
                      '${data['likes'] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.comment_rounded, size: 20, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${data['comments'] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d atrás';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h atrás';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min atrás';
      } else {
        return 'Agora';
      }
    } catch (e) {
      return '';
    }
  }
}

// Telas auxiliares
class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        middle: Text('Pesquisar'),
      ),
      child: Center(
        child: Text('Tela de Pesquisa'),
      ),
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  PostDetailScreen({required this.postId, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        middle: Text('Publicação'),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              data['content'] ?? '',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white : Color(0xFF0E0E0E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}