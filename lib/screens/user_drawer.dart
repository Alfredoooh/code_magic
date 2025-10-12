import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_screen.dart';

class UserDrawer extends StatelessWidget {
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

  Future<void> _setUserOnline(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isOnline': isOnline});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
              ),
              child: Column(
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
                        child: Icon(
                          CupertinoIcons.xmark,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFFF444F),
                    backgroundImage: userData?['profile_image'] != null &&
                            userData!['profile_image'].isNotEmpty
                        ? NetworkImage(userData!['profile_image'])
                        : null,
                    child: userData?['profile_image'] == null ||
                            userData!['profile_image'].isEmpty
                        ? Text(
                            (userData?['username'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    userData?['username'] ?? 'Usuário',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userData?['email'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: userData?['pro'] == true
                          ? Color(0xFFFF444F)
                          : CupertinoColors.systemGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (userData?['pro'] == true)
                          Icon(
                            CupertinoIcons.star_fill,
                            color: CupertinoColors.white,
                            size: 14,
                          ),
                        if (userData?['pro'] == true) SizedBox(width: 6),
                        Text(
                          userData?['pro'] == true ? 'PRO' : 'FREEMIUM',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (userData?['admin'] == true)
                    _buildDrawerItem(
                      context: context,
                      icon: CupertinoIcons.shield_fill,
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
                      isDark: isDark,
                    ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.person_fill,
                    title: 'Perfil',
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.settings,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsModal(context);
                    },
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.creditcard_fill,
                    title: 'Tokens',
                    subtitle: '${userData?['tokens'] ?? 0} disponíveis',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.heart_fill,
                    title: 'Favoritos',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.bookmark_fill,
                    title: 'Salvos',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.chart_bar_fill,
                    title: 'Estatísticas',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  Divider(height: 32),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.info_circle_fill,
                    title: 'Sobre',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.question_circle_fill,
                    title: 'Ajuda',
                    onTap: () {},
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: CupertinoButton(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(0xFFFF444F),
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
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

  void _showSettingsModal(BuildContext context) {
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
              _buildSettingItem(
                context: context,
                icon: CupertinoIcons.moon_fill,
                title: 'Tema',
                subtitle: isDark ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(context),
                isDark: isDark,
              ),
              _buildSettingItem(
                context: context,
                icon: CupertinoIcons.globe,
                title: 'Idioma',
                subtitle: _getLanguageName(currentLocale),
                onTap: () => _showLanguageDialog(context),
                isDark: isDark,
              ),
              _buildSettingItem(
                context: context,
                icon: CupertinoIcons.paintbrush_fill,
                title: 'Estilo do Cartão',
                subtitle: _getCardStyleName(cardStyle),
                onTap: () => _showCardStylePicker(context),
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
                      value: showNews,
                      activeColor: Color(0xFFFF444F),
                      onChanged: onShowNewsChanged,
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
    required BuildContext context,
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

  void _showThemeDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o tema'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Claro'),
            onPressed: () {
              onThemeChanged(ThemeMode.light);
              _updateUserTheme('light');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Escuro'),
            onPressed: () {
              onThemeChanged(ThemeMode.dark);
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

  void _showLanguageDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o idioma'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Português'),
            onPressed: () {
              onLocaleChanged('pt');
              _updateUserLanguage('pt');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('English'),
            onPressed: () {
              onLocaleChanged('en');
              _updateUserLanguage('en');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Español'),
            onPressed: () {
              onLocaleChanged('es');
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

  void _showCardStylePicker(BuildContext context) {
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
                  _buildStyleOption(context, 'modern', 'Moderno', CupertinoIcons.creditcard_fill, isDark),
                  _buildStyleOption(context, 'gradient', 'Gradiente', CupertinoIcons.color_filter, isDark),
                  _buildStyleOption(context, 'minimal', 'Minimalista', CupertinoIcons.rectangle, isDark),
                  _buildStyleOption(context, 'glass', 'Vidro', CupertinoIcons.sparkles, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(BuildContext context, String style, String name, IconData icon, bool isDark) {
    final isSelected = cardStyle == style;

    return GestureDetector(
      onTap: () async {
        onCardStyleChanged(style);
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
}