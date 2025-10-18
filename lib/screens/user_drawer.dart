import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_ui_components.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'user_drawer_settings.dart';
import 'feedback_screen.dart';

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
    _debounceWrite = Timer(const Duration(milliseconds: 250), () {
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

  Uint8List? _decodeBase64Image(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkBackground : AppColors.lightCard,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(child: _buildBody(isDark)),
              _buildFeedbackAndLogout(isDark),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
              AppSectionTitle(text: 'Ajustes', fontSize: 28),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white : Colors.black,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: _buildProfileImage(profileImage, displayName),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String profileImage, String displayName) {
    if (profileImage.isEmpty) {
      return Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (profileImage.startsWith('data:image') || !profileImage.startsWith('http')) {
      final imageBytes = _decodeBase64Image(profileImage);
      if (imageBytes != null) {
        return ClipOval(
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }
    }

    return ClipOval(
      child: Image.network(
        profileImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Center(
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final isAdmin = _userDoc?['admin'] == true;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (isAdmin)
          _buildMenuItem(
            icon: Icons.shield,
            title: 'Painel Admin',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              );
            },
            isDark: isDark,
          ),
        _buildMenuItem(
          icon: Icons.person,
          title: 'Perfil',
          subtitle: 'Ver perfil',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Configurações',
          subtitle: 'Tema, idioma e estilo',
          onTap: () => UserDrawerSettings.showSettingsModal(
            context,
            isDark: isDark,
            currentLocale: _currentLocale,
            cardStyle: _cardStyle,
            onThemeChanged: _safeUpdateTheme,
            onLanguageChanged: _safeUpdateLanguage,
            onCardStyleChanged: _safeSetCardStyle,
          ),
          isDark: isDark,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: Icons.circle,
                title: 'Presença Online',
                subtitle: _isOnline ? 'Visível como online' : 'Indisponível',
                value: _isOnline,
                onChanged: (v) => _safeSetUserOnline(v),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildSwitchRow(
                icon: Icons.newspaper,
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
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
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
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFeedbackAndLogout(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Botão Feedback
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedbackScreen(
                      currentLocale: _currentLocale,
                      isDark: isDark,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getFeedbackText(_currentLocale),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botão Sair
          AppPrimaryButton(
            text: _getLogoutText(_currentLocale),
            onPressed: () async {
              AppDialogs.showConfirmation(
                context,
                _getLogoutTitle(_currentLocale),
                _getLogoutMessage(_currentLocale),
                onConfirm: () async {
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isOnline': false});
                    }
                  } catch (_) {}
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pop(context);
                },
                confirmText: _getLogoutText(_currentLocale),
                cancelText: _getCancelText(_currentLocale),
                isDestructive: true,
              );
            },
          ),
        ],
      ),
    );
  }

  String _getFeedbackText(String locale) {
    switch (locale) {
      case 'pt':
        return 'Feedback';
      case 'en':
        return 'Feedback';
      case 'es':
        return 'Comentarios';
      default:
        return 'Feedback';
    }
  }

  String _getLogoutText(String locale) {
    switch (locale) {
      case 'pt':
        return 'Sair';
      case 'en':
        return 'Logout';
      case 'es':
        return 'Salir';
      default:
        return 'Sair';
    }
  }

  String _getLogoutTitle(String locale) {
    switch (locale) {
      case 'pt':
        return 'Confirmar Saída';
      case 'en':
        return 'Confirm Logout';
      case 'es':
        return 'Confirmar Salida';
      default:
        return 'Confirmar Saída';
    }
  }

  String _getLogoutMessage(String locale) {
    switch (locale) {
      case 'pt':
        return 'Tem certeza de que deseja sair?';
      case 'en':
        return 'Are you sure you want to logout?';
      case 'es':
        return '¿Estás seguro de que quieres salir?';
      default:
        return 'Tem certeza de que deseja sair?';
    }
  }

  String _getCancelText(String locale) {
    switch (locale) {
      case 'pt':
        return 'Cancelar';
      case 'en':
        return 'Cancel';
      case 'es':
        return 'Cancelar';
      default:
        return 'Cancelar';
    }
  }
}