// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_snackbar.dart';
import 'user_profile_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgIcon(
            svgString: CustomIcons.arrowBack,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configurações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF007AFF),
                      backgroundImage: authProvider.userData?['photoURL'] != null
                          ? NetworkImage(authProvider.userData!['photoURL'])
                          : null,
                      child: authProvider.userData?['photoURL'] == null
                          ? Text(
                              authProvider.userData?['name']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
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
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (authProvider.userData?['nickname'] != null)
                          Text(
                            '@${authProvider.userData?['nickname']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.userData?['email'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgIcon(
                      svgString: CustomIcons.chevronRight,
                      color: const Color(0xFF007AFF),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Appearance Section
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Color(0xFF007AFF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Aparência',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Account Options
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  CustomIcons.userCircle,
                  'Minha conta',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserProfileScreen(),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                  secondaryColor,
                  isFirst: true,
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  indent: 60,
                ),
                _buildSettingItem(
                  context,
                  CustomIcons.trash,
                  'Eliminar histórico de atividade',
                  () => _showClearHistoryDialog(context, isDark, cardColor, textColor, secondaryColor),
                  isDark,
                  textColor,
                  secondaryColor,
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legal Section
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  CustomIcons.document,
                  'Termos de uso',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsScreen(type: TermsType.terms),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                  secondaryColor,
                  isFirst: true,
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  indent: 60,
                ),
                _buildSettingItem(
                  context,
                  CustomIcons.shield,
                  'Política de privacidade',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsScreen(type: TermsType.privacy),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                  secondaryColor,
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  indent: 60,
                ),
                _buildSettingItem(
                  context,
                  CustomIcons.globe,
                  'Sobre',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsScreen(type: TermsType.about),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                  secondaryColor,
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context, authProvider, isDark, cardColor, textColor, secondaryColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFA383E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(
                    svgString: CustomIcons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sair',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
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
    Color textColor,
    Color secondaryColor, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgIcon(
                svgString: iconSvg,
                color: const Color(0xFF007AFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            SvgIcon(
              svgString: CustomIcons.chevronRight,
              color: secondaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Terminar sessão?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja sair da sua conta?',
            style: TextStyle(
              fontSize: 15,
              color: secondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Sair',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFA383E),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Eliminar histórico?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja eliminar todo o histórico de atividade? Esta ação não pode ser desfeita.',
            style: TextStyle(
              fontSize: 15,
              color: secondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                CustomSnackbar.showSuccess(
                  context,
                  message: 'Histórico eliminado com sucesso',
                  isDark: isDark,
                );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFA383E),
                ),
              ),
            ),
          ],
        );
      },
    );
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF)
              : isDark
                  ? const Color(0xFF3A3A3C)
                  : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007AFF)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6C6C70),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}