// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_snackbar.dart';
import 'user_profile_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider, bool isDark, Color cardColor, Color textColor, Color secondaryColor) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.palette_outlined, color: const Color(0xFF007AFF), size: 24),
              const SizedBox(width: 12),
              Text(
                'Tema do Aplicativo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                icon: Icons.light_mode_outlined,
                label: 'Modo Claro',
                description: 'Tema claro do sistema',
                isSelected: themeProvider.themeMode == ThemeMode.light,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(dialogContext);
                },
                isDark: isDark,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                icon: Icons.dark_mode_outlined,
                label: 'Modo Escuro',
                description: 'Tema escuro do sistema',
                isSelected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(dialogContext);
                },
                isDark: isDark,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                icon: Icons.phone_android_outlined,
                label: 'Sistema',
                description: 'Usar tema do dispositivo',
                isSelected: themeProvider.themeMode == ThemeMode.system,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(dialogContext);
                },
                isDark: isDark,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Fechar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header customizado
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.string(
                      CustomIcons.arrowLeft,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Configurações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E5E5),
              height: 1,
            ),

            // Conteúdo
            Expanded(
              child: ListView(
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
                          SvgPicture.string(
                            CustomIcons.chevronRight,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
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
                    child: InkWell(
                      onTap: () => _showThemeDialog(context, themeProvider, isDark, cardColor, textColor, secondaryColor),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: textColor,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tema',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getThemeLabel(themeProvider.themeMode),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SvgPicture.string(
                              CustomIcons.chevronRight,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
                            ),
                          ],
                        ),
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
                          color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E5E5),
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
                          color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E5E5),
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
                          color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E5E5),
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
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context, authProvider, isDark, cardColor, textColor, secondaryColor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA383E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(
                            CustomIcons.logout,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
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
            SvgPicture.string(
              iconSvg,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            SvgPicture.string(
              CustomIcons.chevronRight,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Terminar sessão?',
            style: TextStyle(
              fontSize: 20,
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
                  fontSize: 16,
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
                  fontSize: 16,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Eliminar histórico?',
            style: TextStyle(
              fontSize: 20,
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
                  fontSize: 16,
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
                  fontSize: 16,
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

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;
  final Color secondaryColor;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF).withOpacity(0.15)
              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007AFF)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF007AFF) : secondaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF007AFF),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}