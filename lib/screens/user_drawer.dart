import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart'; // Certifique-se de que este import existe

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

  bool _showNews = true;
  bool _isOnline = true;
  String _cardStyle = 'modern';
  String _currentLocale = 'pt';

  Timer? _debounceWrite;

  @override
  void initState() {
    super.initState();
    _userDoc = widget.userData;
    _showNews = widget.showNews;
    _cardStyle = widget.cardStyle;
    _currentLocale = widget.currentLocale;
    _subscribeToUserDoc();
  }

  void _subscribeToUserDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
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
    } catch (e) {}
  }

  void _debouncedWrite(Map<String, dynamic> payload) {
    _debounceWrite?.cancel();
    _debounceWrite = Timer(Duration(milliseconds: 250), () {
      _writeUserField(payload);
    });
  }

  Future<void> _safeSetUserOnline(bool isOnline) async {
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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF000000) : CupertinoColors.white,
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
        color: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 30,
                child: Icon(
                  CupertinoIcons.xmark,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF444F),
                ),
                child: profileImage.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Center(
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 24,
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPro ? Color(0xFFFF444F) : CupertinoColors.systemGrey3,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPro ? 'FREEMIUM' : 'FREEMIUM',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return Center(child: CupertinoActivityIndicator());
    }

    final isAdmin = _userDoc?['admin'] == true;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (isAdmin) _buildMenuItem(
          icon: CupertinoIcons.shield_fill,
          title: 'Painel Admin',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => AdminPanelScreen()),
            );
          },
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.person_fill,
          title: 'Perfil',
          subtitle: 'Ver perfil',
          onTap: () {
            Navigator.pop(context);
            // Navegue para a tela de perfil se existir
            // Navigator.push(context, CupertinoPageRoute(builder: (_) => ProfileScreen()));
          },
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.settings,
          title: 'Configurações',
          subtitle: 'Tema, idioma e estilo',
          onTap: () => _showSettingsModal(context),
          isDark: isDark,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: CupertinoIcons.circle_grid_hex_fill,
                title: 'Presença Online',
                subtitle: _isOnline ? 'Visível como online' : 'Indisponível',
                value: _isOnline,
                onChanged: (v) => _safeSetUserOnline(v),
                isDark: isDark,
              ),
              SizedBox(height: 16),
              _buildSwitchRow(
                icon: CupertinoIcons.news_solid,
                title: 'Mostrar Notícias',
                subtitle: 'Exibir no ecrã principal',
                value: _showNews,
                onChanged: (v) => _safeSetShowNews(v),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: onTap,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFFFF444F),
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Color(0xFFFF444F),
          size: 22,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeColor: Color(0xFFFF444F),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLogout(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 14),
        color: CupertinoColors.destructiveRed,
        borderRadius: BorderRadius.circular(12),
        onPressed: () async {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text('Confirmar Saída'),
              content: Text('Tem certeza de que deseja sair?'),
              actions: [
                CupertinoDialogAction(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('Sair'),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'isOnline': false});
                      }
                    } catch (_) {}
                    await FirebaseAuth.instance.signOut();
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.square_arrow_right, size: 20),
            SizedBox(width: 8),
            Text(
              'Sair',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          middle: Text('Configurações'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.xmark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildSettingCard(
                icon: CupertinoIcons.moon_fill,
                title: 'Tema',
                subtitle: Theme.of(context).brightness == Brightness.dark ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(context),
                isDark: isDark,
              ),
              SizedBox(height: 12),
              _buildSettingCard(
                icon: CupertinoIcons.globe,
                title: 'Idioma',
                subtitle: _getLanguageName(_currentLocale),
                onTap: () => _showLanguageDialog(context),
                isDark: isDark,
              ),
              SizedBox(height: 12),
              _buildSettingCard(
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFFFF444F), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ],
        ),
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
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Estilo do Cartão',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 16),
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
          color: selected
              ? Color(0xFFFF444F).withOpacity(0.1)
              : (isDark ? Color(0xFF000000) : Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Color(0xFFFF444F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: selected ? Color(0xFFFF444F) : CupertinoColors.systemGrey,
            ),
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected
                    ? Color(0xFFFF444F)
                    : (isDark ? CupertinoColors.white : CupertinoColors.black),
              ),
            ),
          ],
        ),
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