// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import 'user_profile_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Configurações',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Profile Card
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const UserProfileScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF1877F2),
                    backgroundImage: authProvider.userData?['photoURL'] != null
                        ? NetworkImage(authProvider.userData!['photoURL'])
                        : null,
                    child: authProvider.userData?['photoURL'] == null
                        ? Text(
                            authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userData?['name'] ?? 'Usuário',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.userData?['nickname'] ?? '@usuario',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                        Text(
                          authProvider.userData?['email'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgIcon(
                    svgString: CustomIcons.chevronRight,
                    color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Appearance Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aparência',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ThemeButton(
                          label: 'Claro',
                          icon: Icons.light_mode_outlined,
                          isSelected: themeProvider.themeMode == ThemeMode.light,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeButton(
                          label: 'Escuro',
                          icon: Icons.dark_mode_outlined,
                          isSelected: themeProvider.themeMode == ThemeMode.dark,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Account Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  CustomIcons.userCircle,
                  'Minha conta',
                  () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const UserProfileScreen(),
                      ),
                    );
                  },
                  isDark,
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA)),
                _buildSettingItem(
                  context,
                  CustomIcons.trash,
                  'Eliminar histórico de atividade',
                  () => _showClearHistoryDialog(context, authProvider),
                  isDark,
                ),
              ],
            ),
          ),

          // Legal Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  CustomIcons.document,
                  'Termos de uso',
                  () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const TermsScreen(type: TermsType.terms),
                      ),
                    );
                  },
                  isDark,
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA)),
                _buildSettingItem(
                  context,
                  CustomIcons.shield,
                  'Política de privacidade',
                  () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const TermsScreen(type: TermsType.privacy),
                      ),
                    );
                  },
                  isDark,
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA)),
                _buildSettingItem(
                  context,
                  CustomIcons.globe,
                  'Sobre',
                  () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const TermsScreen(type: TermsType.about),
                      ),
                    );
                  },
                  isDark,
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            margin: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context, authProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFA383E),
                  side: const BorderSide(color: Color(0xFFFA383E), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sair',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String iconSvg,
    String title,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SvgIcon(
              svgString: iconSvg,
              color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                ),
              ),
            ),
            SvgIcon(
              svgString: CustomIcons.chevronRight,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _showClearHistoryDialog(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar histórico'),
        content: const Text('Tem certeza que deseja eliminar todo o histórico de atividade? Esta ação não pode ser desfeita.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // TODO: Implementar lógica de limpar histórico
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico eliminado com sucesso')),
      );
    }
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1877F2)
              : isDark
                  ? const Color(0xFF3A3B3C)
                  : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1877F2)
                : isDark
                    ? const Color(0xFF3E4042)
                    : const Color(0xFFDADADA),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? const Color(0xFFB0B3B8)
                      : const Color(0xFF65676B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? const Color(0xFFE4E6EB)
                        : const Color(0xFF050505),
              ),
            ),
          ],
        ),
      ),
    );
  }
}