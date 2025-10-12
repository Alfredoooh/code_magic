import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:palette_generator/palette_generator.dart';
import '../services/language_service.dart';
import 'admin_panel_screen.dart';
import 'news_detail_screen.dart';
import '../models/news_article.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;

  const HomeScreen({
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  List<NewsArticle> _newsArticles = [];
  bool _loadingNews = true;
  bool _showNews = true;
  Map<int, Color> _newsColors = {};
  String _cardStyle = 'modern'; // modern, gradient, minimal, glass
  int _messageCount = 0;
  int _groupCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setUserOnline(true);
    _loadNews();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Carregar contagem de mensagens
    final convSnapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .get();
    
    int totalMessages = 0;
    for (var conv in convSnapshot.docs) {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conv.id)
          .collection('messages')
          .where('senderId', isEqualTo: user.uid)
          .get();
      totalMessages += messagesSnapshot.docs.length;
    }

    // Carregar contagem de grupos
    final groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .get();

    if (mounted) {
      setState(() {
        _messageCount = totalMessages;
        _groupCount = groupSnapshot.docs.length;
      });
    }
  }

  Future<void> _loadNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsdata.io/api/1/news?apikey=pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c&language=pt&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        List<NewsArticle> articles = [];
        for (var article in results.take(10)) {
          articles.add(NewsArticle.fromNewsdata(article));
        }

        if (mounted) {
          setState(() {
            _newsArticles = articles;
            _loadingNews = false;
          });
        }

        _extractColors();
      } else {
        if (mounted) {
          setState(() => _loadingNews = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingNews = false);
      }
    }
  }

  Future<void> _extractColors() async {
    for (int i = 0; i < _newsArticles.length; i++) {
      if (_newsArticles[i].imageUrl.isNotEmpty) {
        try {
          final paletteGenerator = await PaletteGenerator.fromImageProvider(
            NetworkImage(_newsArticles[i].imageUrl),
            maximumColorCount: 10,
          );

          if (mounted) {
            setState(() {
              _newsColors[i] = paletteGenerator.dominantColor?.color ?? 
                              paletteGenerator.vibrantColor?.color ?? 
                              Color(0xFFFF444F);
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _newsColors[i] = Color(0xFFFF444F);
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _setUserOnline(false);
    super.dispose();
  }

  Future<void> _setUserOnline(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isOnline': isOnline});
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data();
            _showNews = _userData?['showNews'] ?? true;
            _cardStyle = _userData?['cardStyle'] ?? 'modern';
          });
        }
      });
    }
  }

  void _showCardStylePicker() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Escolha o Estilo do Cartão',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStyleOption('modern', 'Moderno', CupertinoIcons.creditcard_fill),
                  _buildStyleOption('gradient', 'Gradiente', CupertinoIcons.color_filter),
                  _buildStyleOption('minimal', 'Minimalista', CupertinoIcons.rectangle),
                  _buildStyleOption('glass', 'Vidro', CupertinoIcons.sparkles),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(String style, String name, IconData icon) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isSelected = _cardStyle == style;

    return GestureDetector(
      onTap: () async {
        setState(() => _cardStyle = style);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'cardStyle': style});
        }
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFFFF444F).withOpacity(0.2)
              : (isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFFFF444F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Color(0xFFFF444F) : CupertinoColors.systemGrey,
            ),
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Color(0xFFFF444F) 
                    : (isDark ? CupertinoColors.white : CupertinoColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    switch (_cardStyle) {
      case 'gradient':
        return _buildGradientCard(isDark);
      case 'minimal':
        return _buildMinimalCard(isDark);
      case 'glass':
        return _buildGlassCard(isDark);
      default:
        return _buildModernCard(isDark);
    }
  }

  Widget _buildModernCard(bool isDark) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d), Color(0xFF1a1a1a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: CardPatternPainter(),
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _buildCardContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientCard(bool isDark) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF444F),
            Color(0xFFFF6B6B),
            Color(0xFFFF8E53),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF444F).withOpacity(0.5),
            blurRadius: 25,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: _buildCardContent(),
    );
  }

  Widget _buildMinimalCard(bool isDark) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey5,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tokens',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_userData?['tokens'] ?? 0}',
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  CupertinoIcons.creditcard_fill,
                  color: Color(0xFFFF444F),
                  size: 32,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_userData?['pro'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Text(
                  _userData?['username'] ?? 'Utilizador',
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Color(0xFF1A1A1A).withOpacity(0.8),
                      Color(0xFF2C2C2C).withOpacity(0.6),
                    ]
                  : [
                      CupertinoColors.white.withOpacity(0.8),
                      CupertinoColors.white.withOpacity(0.6),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? CupertinoColors.white.withOpacity(0.1)
                  : CupertinoColors.black.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tokens Disponíveis',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final tokens = snapshot.data?.data() != null
                          ? (snapshot.data!.data() as Map<String, dynamic>)['tokens'] ?? 0
                          : 0;
                      return Text(
                        '$tokens',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showCardStylePicker,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF444F).withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.paintbrush_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_userData?['pro'] == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF444F).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.star_fill, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'PRO - Tokens Ilimitados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Expira: ${_getExpirationDate()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              SizedBox(height: 12),
              Text(
                _userData?['username'] ?? 'Utilizador',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserModal() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          middle: Text('Perfil'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.xmark_circle_fill),
            onPressed: () => Navigator.pop(context),
          ),
          border: null,
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFFFF444F),
                  backgroundImage: _userData?['profile_image'] != null && _userData!['profile_image'].isNotEmpty
                      ? NetworkImage(_userData!['profile_image'])
                      : null,
                  child: _userData?['profile_image'] == null || _userData!['profile_image'].isEmpty
                      ? Text(
                          (_userData?['username'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(fontSize: 48, color: CupertinoColors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 20),
              Text(
                _userData?['username'] ?? 'Usuário',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _userData?['email'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
              ),
              SizedBox(height: 12),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _userData?['pro'] == true ? Color(0xFFFF444F) : CupertinoColors.systemGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userData?['pro'] == true ? 'PRO' : 'FREEMIUM',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              if (_userData?['admin'] == true)
                _buildCupertinoMenuItem(
                  icon: CupertinoIcons.shield_fill,
                  title: 'Painel Admin',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (context) => AdminPanelScreen()),
                    );
                  },
                  isDark: isDark,
                ),
              _buildCupertinoMenuItem(
                icon: CupertinoIcons.settings,
                title: 'Configurações',
                onTap: () {
                  Navigator.pop(context);
                  _showSettingsModal();
                },
                isDark: isDark,
              ),
              _buildCupertinoMenuItem(
                icon: CupertinoIcons.person_fill,
                title: 'Editar Perfil',
                onTap: () {},
                isDark: isDark,
              ),
              _buildCupertinoMenuItem(
                icon: CupertinoIcons.info_circle_fill,
                title: 'Sobre',
                onTap: () {},
                isDark: isDark,
              ),
              SizedBox(height: 32),
              CupertinoButton(
                color: CupertinoColors.destructiveRed,
                borderRadius: BorderRadius.circular(12),
                onPressed: () async {
                  await _setUserOnline(false);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.arrow_right_square),
                    SizedBox(width: 8),
                    Text('Sair', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsModal() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          middle: Text('Configurações'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.xmark_circle_fill),
            onPressed: () => Navigator.pop(context),
          ),
          border: null,
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              SizedBox(height: 20),
              _buildCupertinoSettingItem(
                icon: CupertinoIcons.moon_fill,
                title: 'Tema',
                subtitle: isDark ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(),
                isDark: isDark,
              ),
              _buildCupertinoSettingItem(
                icon: CupertinoIcons.globe,
                title: 'Idioma',
                subtitle: _getLanguageName(widget.currentLocale),
                onTap: () => _showLanguageDialog(),
                isDark: isDark,
              ),
              _buildCupertinoSettingItem(
                icon: CupertinoIcons.paintbrush_fill,
                title: 'Estilo do Cartão',
                subtitle: _getCardStyleName(_cardStyle),
                onTap: _showCardStylePicker,
                isDark: isDark,
              ),
              Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.news, color: Color(0xFFFF444F), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mostrar Notícias',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Exibir notícias no ecrã principal',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _showNews,
                      activeColor: Color(0xFFFF444F),
                      onChanged: (value) async {
                        setState(() => _showNews = value);
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({'showNews': value});
                        }
                      },
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

  void _showThemeDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o tema'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Claro'),
            onPressed: () {
              widget.onThemeChanged(ThemeMode.light);
              _updateUserTheme('light');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Escuro'),
            onPressed: () {
              widget.onThemeChanged(ThemeMode.dark);
              _updateUserTheme('dark');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o idioma'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Português'),
            onPressed: () {
              widget.onLocaleChanged('pt');
              _updateUserLanguage('pt');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('English'),
            onPressed: () {
              widget.onLocaleChanged('en');
              _updateUserLanguage('en');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Español'),
            onPressed: () {
              widget.onLocaleChanged('es');
              _updateUserLanguage('es');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _updateUserTheme(String theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'theme': theme});
    }
  }

  Future<void> _updateUserLanguage(String language) async {
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

  String _getCardStyleName(String style) {
    switch (style) {
      case 'modern':
        return 'Moderno';
      case 'gradient':
        return 'Gradiente';
      case 'minimal':
        return 'Minimalista';
      case 'glass':
        return 'Vidro';
      default:
        return 'Moderno';
    }
  }

  Widget _buildCupertinoMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: Color(0xFFFF444F), size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCupertinoSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: Color(0xFFFF444F), size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
        ),
        trailing: Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 20),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        middle: Text(
          'K Paga',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.search, color: isDark ? CupertinoColors.white : CupertinoColors.black),
              onPressed: () {},
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFF444F),
                backgroundImage: _userData?['profile_image'] != null && _userData!['profile_image'].isNotEmpty
                    ? NetworkImage(_userData!['profile_image'])
                    : null,
                child: _userData?['profile_image'] == null || _userData!['profile_image'].isEmpty
                    ? Text(
                        (_userData?['username'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(fontSize: 14, color: CupertinoColors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              onPressed: _showUserModal,
            ),
          ],
        ),
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await _loadUserData();
                await _loadNews();
                await _loadStats();
              },
            ),
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWalletCard(),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          title: 'Mensagens',
                          value: '$_messageCount',
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: CupertinoIcons.group_solid,
                          title: 'Grupos',
                          value: '$_groupCount',
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ],
                  ),
                  if (_showNews) ...[
                    SizedBox(height: 32),
                    Text(
                      'Últimas Notícias',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    _loadingNews
                        ? Center(
                            child: CupertinoActivityIndicator(radius: 16),
                          )
                        : Container(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              itemCount: _newsArticles.length,
                              itemBuilder: (context, index) {
                                final article = _newsArticles[index];
                                final cardColor = _newsColors[index] ?? Color(0xFFFF444F);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => NewsDetailScreen(
                                          article: article,
                                          allArticles: _newsArticles,
                                          currentIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 320,
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: cardColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: cardColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: cardColor.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          if (article.imageUrl.isNotEmpty)
                                            Positioned.fill(
                                              child: Image.network(
                                                article.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stack) => Container(
                                                  color: cardColor.withOpacity(0.2),
                                                  child: Icon(
                                                    CupertinoIcons.photo,
                                                    color: cardColor,
                                                    size: 60,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.8),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: cardColor,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      article.source.toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    article.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                  SizedBox(height: 32),
                  Text(
                    'Publicações Recentes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CupertinoActivityIndicator(radius: 16),
                      ),
                    );
                  }

                  final posts = snapshot.data!.docs;

                  if (posts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.doc_text,
                              size: 60,
                              color: CupertinoColors.systemGrey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma publicação ainda',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index].data() as Map<String, dynamic>;
                      return _buildPostCard(post, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
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
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
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
                  color: CupertinoColors.systemGrey5,
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 60,
                    color: CupertinoColors.systemGrey,
                  ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      post['userName'] ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  post['content'] ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? CupertinoColors.white.withOpacity(0.85) : CupertinoColors.black,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 30,
                      child: Icon(
                        CupertinoIcons.heart,
                        color: CupertinoColors.systemGrey,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    Text(
                      '${post['likes'] ?? 0}',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    SizedBox(width: 16),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 30,
                      child: Icon(
                        CupertinoIcons.chat_bubble,
                        color: CupertinoColors.systemGrey,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    Text(
                      '${post['comments'] ?? 0}',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    for (double i = -50; i < size.width; i += 30) {
      for (double j = -50; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}