// lib/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'custom_icons.dart';
import 'new_post_modal.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: bgColor,
      child: Column(
        children: [
          Container(
            height: 120,
            padding: const EdgeInsets.only(left: 16, top: 50, bottom: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1877F2),
                  child: Text(
                    authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userData?['name'] ?? 'Usuário',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ver perfil',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
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
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  CustomIcons.inbox,
                  'Caixa de entrada',
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/messages');
                  },
                  isDark,
                ),
                _buildDrawerItem(
                  context,
                  CustomIcons.plus,
                  'Adicionar nova publicação',
                  () {
                    Navigator.pop(context);
                    _showNewPostModal(context);
                  },
                  isDark,
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 8,
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFF0F2F5),
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context,
                  CustomIcons.settings,
                  'Configurações',
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                  isDark,
                ),
                _buildDrawerItem(
                  context,
                  CustomIcons.logout,
                  'Sair',
                  () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  isDark,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String svgString,
    String title,
    VoidCallback onTap,
    bool isDark, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFFA383E)
        : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505));

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: SvgIcon(
                  svgString: svgString,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewPostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewPostModal(),
    );
  }
}