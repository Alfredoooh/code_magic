import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  int _activeUsers = 0;
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadActiveUsers();
    _startExpirationCheck();
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'last_active': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _loadActiveUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('last_active', isGreaterThan: DateTime.now().subtract(Duration(minutes: 5)))
        .get();
    if (mounted) {
      setState(() {
        _activeUsers = snapshot.docs.length;
      });
    }
  }

  void _startExpirationCheck() {
    _expirationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_userData?['expiration_date'] != null) {
        final expiration = DateTime.parse(_userData!['expiration_date']);
        if (DateTime.now().isAfter(expiration)) {
          _showExpirationDialog();
          timer.cancel();
        }
      }
    });
  }

  void _showExpirationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Conta Expirada'),
        content: Text('Sua conta PRO expirou. Entre em contato com o administrador.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getRemainingTime() {
    if (_userData?['expiration_date'] == null) return 'Sem limite';
    if (_userData?['is_pro'] != true) return 'Gratuito';
    
    final expiration = DateTime.parse(_userData!['expiration_date']);
    final now = DateTime.now();
    final difference = expiration.difference(now);
    
    if (difference.isNegative) return 'Expirado';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dias';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else {
      return '${difference.inMinutes} minutos';
    }
  }

  void _showSearchScreen() {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => SearchScreen(),
      ),
    );
  }

  void _showUserModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UserModalSheet(userData: _userData, onRefresh: _loadUserData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = _userData?['tokens'] ?? 0;
    final isPro = _userData?['is_pro'] == true;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: _showUserModal,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                _userData?['profile_image'] ?? 
                'https://ui-avatars.com/api/?name=${user?.displayName ?? 'User'}&background=FF444F&color=fff',
              ),
            ),
          ),
        ),
        title: Text(
          'K Paga',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: _showSearchScreen,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadActiveUsers();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWalletCard(tokens, isPro, isDark),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Publicações',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userData?['is_admin'] == true || isPro)
                          IconButton(
                            icon: Icon(Icons.add_circle_rounded, color: Color(0xFFFF444F)),
                            onPressed: _createSheet,
                          ),
                      ],
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sheets')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Erro ao carregar publicações')),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: Color(0xFFFF444F)),
                      ),
                    ),
                  );
                }

                final sheets = snapshot.data?.docs ?? [];

                if (sheets.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(Icons.article_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma publicação ainda',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sheet = sheets[index].data() as Map<String, dynamic>;
                      return _buildSheetCard(sheet, sheets[index].id);
                    },
                    childCount: sheets.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(int tokens, bool isPro, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [Color(0xFFFFD700), Color(0xFFFFA500)]
              : [Color(0xFFFF444F), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPro ? Color(0xFFFFD700) : Color(0xFFFF444F)).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro ? 'Conta PRO' : 'Conta Gratuita',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _userData?['username'] ?? 'Usuário',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                isPro ? Icons.star_rounded : Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tokens Disponíveis',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isPro ? '∞' : tokens.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tempo Restante',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRemainingTime(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCard(Map<String, dynamic> sheet, String sheetId) {
    final likes = List.from(sheet['likes'] ?? []);
    final commentsCount = sheet['comments_count'] ?? 0;
    final isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => SheetDetailScreen(sheetId: sheetId, sheet: sheet),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(sheet['author_image'] ?? ''),
                      backgroundColor: Color(0xFFFF444F),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheet['author_name'] ?? 'Autor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _formatTimestamp(sheet['created_at']),
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
              ),
              if (sheet['image']?.isNotEmpty == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    sheet['image'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image_rounded, size: 50),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sheet['title']?.isNotEmpty == true)
                      Text(
                        sheet['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (sheet['title']?.isNotEmpty == true) SizedBox(height: 8),
                    Text(
                      sheet['content'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _toggleLike(sheetId, isLiked),
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.red : Colors.grey,
                                size: 22,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${likes.length}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 24),
                        InkWell(
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              CupertinoPageRoute(
                                fullscreenDialog: true,
                                builder: (context) => SheetDetailScreen(sheetId: sheetId, sheet: sheet),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.comment_rounded, color: Colors.grey, size: 22),
                              SizedBox(width: 6),
                              Text(
                                '$commentsCount',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
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
      return 'Agora';
    }
  }

  Future<void> _toggleLike(String sheetId, bool isLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sheetRef = FirebaseFirestore.instance.collection('sheets').doc(sheetId);
    
    if (isLiked) {
      await sheetRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await sheetRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  void _createSheet() {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => CreateSheetScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }
}

class UserModalSheet extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onRefresh;

  const UserModalSheet({required this.userData, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = userData?['is_admin'] == true;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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
                userData?['profile_image'] ?? 
                'https://ui-avatars.com/api/?name=${user?.displayName ?? 'User'}&background=FF444F&color=fff',
              ),
            ),
            SizedBox(height: 16),
            Text(
              userData?['username'] ?? 'Usuário',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              userData?['email'] ?? '',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.settings_rounded, color: Color(0xFFFF444F)),
              title: Text('Configurações'),
              trailing: Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (context) => SettingsScreen(userData: userData),
                  ),
                );
              },
            ),
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFF444F)),
                title: Text('Painel Admin'),
                trailing: Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  // Navegar para admin panel
                },
              ),
            SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const SettingsScreen({required this.userData});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _updateTheme(String theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'theme': theme});
      ChatApp.appKey.currentState?.updateTheme(theme);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Configurações'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Aparência',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildSettingTile(
            'Tema Escuro',
            Icons.dark_mode_rounded,
            () => _updateTheme('dark'),
            selected: widget.userData?['theme'] == 'dark',
          ),
          _buildSettingTile(
            'Tema Claro',
            Icons.light_mode_rounded,
            () => _updateTheme('light'),
            selected: widget.userData?['theme'] == 'light',
          ),
          SizedBox(height: 24),
          Text(
            'Idioma',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildSettingTile(
            'Português',
            Icons.language_rounded,
            () => _updateLanguage('pt'),
            selected: widget.userData?['language'] == 'pt',
          ),
          _buildSettingTile(
            'English',
            Icons.language_rounded,
            () => _updateLanguage('en'),
            selected: widget.userData?['language'] == 'en',
          ),
          _buildSettingTile(
            'Español',
            Icons.language_rounded,
            () => _updateLanguage('es'),
            selected: widget.userData?['language'] == 'es',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap, {bool selected = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Color(0xFFFF444F) : Theme.of(context).dividerColor.withOpacity(0.1),
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? Color(0xFFFF444F) : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Color(0xFFFF444F) : null,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: selected ? Icon(Icons.check_rounded, color: Color(0xFFFF444F)) : null,
        onTap: onTap,
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tudo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Pesquisar...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['Tudo', 'Publicações', 'Mensagens', 'Usuários'].map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: Color(0xFFFF444F).withOpacity(0.2),
                    checkmarkColor: Color(0xFFFF444F),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Digite para pesquisar',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Implementar lógica de pesquisa aqui
    return Center(
      child: Text('Resultados para: $_searchQuery'),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SheetDetailScreen extends StatefulWidget {
  final String sheetId;
  final Map<String, dynamic> sheet;

  const SheetDetailScreen({required this.sheetId, required this.sheet});

  @override
  _SheetDetailScreenState createState() => _SheetDetailScreenState();
}

class _SheetDetailScreenState extends State<SheetDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('sheets')
          .doc(widget.sheetId)
          .collection('comments')
          .add({
        'text': _commentController.text.trim(),
        'author_id': user.uid,
        'author_name': user.displayName ?? 'Usuário',
        'author_image': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('sheets')
          .doc(widget.sheetId)
          .update({
        'comments_count': FieldValue.increment(1),
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      print('Erro ao adicionar comentário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Publicação'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(widget.sheet['author_image'] ?? ''),
                          backgroundColor: Color(0xFFFF444F),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.sheet['author_name'] ?? 'Autor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatTimestamp(widget.sheet['created_at']),
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.sheet['image']?.isNotEmpty == true)
                    Image.network(
                      widget.sheet['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.sheet['title']?.isNotEmpty == true) ...[
                          Text(
                            widget.sheet['title'],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                        Text(
                          widget.sheet['content'] ?? '',
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        SizedBox(height: 24),
                        Divider(),
                        SizedBox(height: 16),
                        Text(
                          'Comentários',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sheets')
                        .doc(widget.sheetId)
                        .collection('comments')
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar comentários'));
                      }

                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data?.docs ?? [];

                      if (comments.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Seja o primeiro a comentar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: comment['author_image']?.isNotEmpty == true
                                      ? NetworkImage(comment['author_image'])
                                      : null,
                                  backgroundColor: Color(0xFFFF444F),
                                  child: comment['author_image']?.isEmpty != false
                                      ? Text(
                                          (comment['author_name'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['author_name'] ?? 'Usuário',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        comment['text'] ?? '',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(comment['created_at']),
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Adicionar comentário...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF1A1A1A)
                            : Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: Color(0xFFFF444F)),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
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
      return 'Agora';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class CreateSheetScreen extends StatefulWidget {
  @override
  _CreateSheetScreenState createState() => _CreateSheetScreenState();
}

class _CreateSheetScreenState extends State<CreateSheetScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createSheet() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Digite o conteúdo da publicação')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('sheets').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'image': _imageController.text.trim(),
        'author_id': user.uid,
        'author_name': userData['username'] ?? user.displayName ?? 'Usuário',
        'author_image': userData['profile_image'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'likes': [],
        'comments_count': 0,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publicação criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar publicação'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nova Publicação'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createSheet,
            child: Text(
              'Publicar',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Color(0xFFFF444F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Título (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Escreva sua publicação...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 8,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _imageController,
              decoration: InputDecoration(
                hintText: 'URL da imagem (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.image_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}