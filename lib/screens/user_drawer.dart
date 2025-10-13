import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_screen.dart';

class UserDrawer extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;
  final bool showNews;
  final String cardStyle;
  final Function(bool) onShowNewsChanged;
  final Function(String) onCardStyleChanged;

  const UserDrawer({
    required this.userData,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
    required this.showNews,
    required this.cardStyle,
    required this.onShowNewsChanged,
    required this.onCardStyleChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  Map<String, dynamic>? _userDoc;
  bool _loading = true;

  // local cached controls to show instant UI on toggle
  bool _showNews = true;
  bool _isOnline = true;
  String _cardStyle = 'modern';
  String _currentLocale = 'pt';

  Timer? _debounceWrite;

  @override
  void initState() {
    super.initState();
    // initialize local values from passed userData (if any)
    _userDoc = widget.userData;
    _showNews = widget.showNews;
    _cardStyle = widget.cardStyle;
    _currentLocale = widget.currentLocale;
    _subscribeToUserDoc();
  }

  void _subscribeToUserDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      _userSub?.cancel();
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        if (!snap.exists) {
          setState(() {
            _userDoc = null;
            _loading = false;
          });
          return;
        }

        final data = snap.data();
        setState(() {
          _userDoc = data ?? {};
          _showNews = (_userDoc?['showNews'] ?? _showNews) as bool;
          _isOnline = (_userDoc?['isOnline'] ?? _isOnline) as bool;
          _cardStyle = (_userDoc?['cardStyle'] ?? _cardStyle) as String;
          _currentLocale = (_userDoc?['language'] ?? _currentLocale) as String;
          _loading = false;
        });
      }, onError: (err) {
        if (mounted) setState(() => _loading = false);
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _debounceWrite?.cancel();
    super.dispose();
  }

  Future<void> _writeUserField(Map<String, dynamic> payload) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(payload);
    } catch (e) {
      // ignore write failure silently — as UI already shows change from server stream when possible
    }
  }

  // Debounced write to avoid spamming Firestore when user toggles quickly
  void _debouncedWrite(Map<String, dynamic> payload) {
    _debounceWrite?.cancel();
    _debounceWrite = Timer(Duration(milliseconds: 250), () {
      _writeUserField(payload);
    });
  }

  Future<void> _safeSetUserOnline(bool isOnline) async {
    // instant local set + debounced write
    if (!mounted) return;
    setState(() => _isOnline = isOnline);
    _debouncedWrite({'isOnline': isOnline});
  }

  Future<void> _safeSetShowNews(bool value) async {
    if (!mounted) return;
    setState(() => _showNews = value);
    widget.onShowNewsChanged(value);
    _debouncedWrite({'showNews': value});
  }

  Future<void> _safeSetCardStyle(String style) async {
    if (!mounted) return;
    setState(() => _cardStyle = style);
    widget.onCardStyleChanged(style);
    _debouncedWrite({'cardStyle': style});
  }

  Future<void> _safeUpdateTheme(String theme) async {
    widget.onThemeChanged(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
    _debouncedWrite({'theme': theme});
  }

  Future<void> _safeUpdateLanguage(String lang) async {
    widget.onLocaleChanged(lang);
    _debouncedWrite({'language': lang});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width * 0.85;

    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildBody(isDark)),
            _buildLogout(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final displayName = (_userDoc?['username'] ?? 'Usuário') as String;
    final email = (_userDoc?['email'] ?? '') as String;
    final profileImage = (_userDoc?['profile_image'] ?? '') as String;
    final isPro = (_userDoc?['pro'] == true);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.xmark,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          SizedBox(height: 16),
          CircleAvatar(
            radius: 44,
            backgroundColor: Color(0xFFFF444F),
            backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
            child: profileImage.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 36, color: CupertinoColors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          SizedBox(height: 12),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isPro ? Color(0xFFFF444F) : CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isPro ? 'PRO' : 'FREEMIUM',
              style: TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return Center(child: CupertinoActivityIndicator(radius: 16));
    }

    final isAdmin = _userDoc?['admin'] == true;

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8),
      children: [
        if (isAdmin)
          _buildDrawerItem(
            icon: CupertinoIcons.shield_fill,
            title: 'Painel Admin',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, CupertinoPageRoute(builder: (_) => AdminPanelScreen()));
            },
            isDark: isDark,
          ),
        _buildDrawerItem(
          icon: CupertinoIcons.person_fill,
          title: 'Perfil',
          subtitle: 'Ver perfil',
          onTap: () => Navigator.pop(context),
          isDark: isDark,
        ),
        _buildDrawerItem(
          icon: CupertinoIcons.settings,
          title: 'Configurações',
          subtitle: 'Tema, idioma e estilo',
          onTap: () {
            _showSettingsModal(context);
          },
          isDark: isDark,
        ),
        // Real-time switches container
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // isOnline switch
                Row(
                  children: [
                    Icon(CupertinoIcons.circle_grid_hex, color: Color(0xFFFF444F), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presença (Online)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _isOnline ? 'Visível como online' : 'Offline/Indisponível',
                            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _isOnline,
                      activeColor: CupertinoColors.activeGreen,
                      onChanged: (v) => _safeSetUserOnlineSwitch(v),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // showNews switch
                Row(
                  children: [
                    Icon(CupertinoIcons.news, color: Color(0xFFFF444F), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mostrar notícias',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Exibir últimas notícias no ecrã principal',
                            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _showNews,
                      activeColor: CupertinoColors.activeGreen,
                      onChanged: (v) => _safeSetShowNews(v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  // called by UI - sets local state and writes DB (debounced)
  void _safeSetUserOnlineSwitch(bool v) {
    // If turning online, write isOnline true; if turning offline, still write.
    _safeSetUserOnline(v);
  }

  Widget _buildLogout(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      child: CupertinoButton(
        color: CupertinoColors.destructiveRed,
        borderRadius: BorderRadius.circular(12),
        onPressed: () async {
          // set offline first (non-blocking) and sign out
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              // set offline immediately (best-effort)
              FirebaseFirestore.instance.collection('users').doc(uid).update({'isOnline': false});
            }
          } catch (_) {}
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pop(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.arrow_right_square),
            SizedBox(width: 8),
            Text(
              'Sair',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFFFF444F), size: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      )),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  ],
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 20),
          ],
        ),
      ),
    );
  }

  // Settings modal (theme, language, card style)
  void _showSettingsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            padding: EdgeInsets.all(18),
            children: [
              SizedBox(height: 8),
              _buildSettingTile(
                icon: CupertinoIcons.moon_fill,
                title: 'Tema',
                subtitle: Theme.of(context).brightness == Brightness.dark ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(context),
                isDark: isDark,
              ),
              _buildSettingTile(
                icon: CupertinoIcons.globe,
                title: 'Idioma',
                subtitle: _getLanguageName(_currentLocale),
                onTap: () => _showLanguageDialog(context),
                isDark: isDark,
              ),
              _buildSettingTile(
                icon: CupertinoIcons.paintbrush_fill,
                title: 'Estilo do Cartão',
                subtitle: _getCardStyleName(_cardStyle),
                onTap: () => _showCardStylePicker(context),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
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
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
        subtitle: Text(subtitle, style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
        trailing: Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o tema'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Claro'),
            onPressed: () {
              _safeUpdateTheme('light');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Escuro'),
            onPressed: () {
              _safeUpdateTheme('dark');
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

  void _showLanguageDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o idioma'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Português'),
            onPressed: () {
              _safeUpdateLanguage('pt');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('English'),
            onPressed: () {
              _safeUpdateLanguage('en');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Español'),
            onPressed: () {
              _safeUpdateLanguage('es');
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

  void _showCardStylePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 420,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: CupertinoColors.systemGrey, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 16),
            Text('Escolha o Estilo do Cartão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
            SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStyleOption('modern', 'Moderno', CupertinoIcons.creditcard_fill, isDark),
                  _buildStyleOption('gradient', 'Gradiente', CupertinoIcons.color_filter, isDark),
                  _buildStyleOption('minimal', 'Minimalista', CupertinoIcons.rectangle, isDark),
                  _buildStyleOption('glass', 'Vidro', CupertinoIcons.sparkles, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(String style, String name, IconData icon, bool isDark) {
    final selected = _cardStyle == style;
    return GestureDetector(
      onTap: () {
        _safeSetCardStyle(style);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Color(0xFFFF444F).withOpacity(0.14) : (isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Color(0xFFFF444F) : Colors.transparent, width: 2),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 36, color: selected ? Color(0xFFFF444F) : CupertinoColors.systemGrey),
          SizedBox(height: 12),
          Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Color(0xFFFF444F) : (isDark ? CupertinoColors.white : CupertinoColors.black))),
        ]),
      ),
    );
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
}