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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configurações',
          style: TextStyle(
            fontSize: 18,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF1877F2),
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
                              color: hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.userData?['email'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: hintColor,
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
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.string(
                      CustomIcons.chevronRight,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1877F2),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Appearance Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Color(0xFF1877F2),
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

          const SizedBox(height: 8),

          // Account Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF3E4042)
                        : const Color(0xFFDADADA)),
                _buildSettingItem(
                  context,
                  CustomIcons.trash,
                  'Eliminar histórico de atividade',
                  () => _showClearHistoryDialog(context, isDark, cardColor,
                      textColor, hintColor),
                  isDark,
                  textColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Legal Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                        builder: (context) =>
                            const TermsScreen(type: TermsType.terms),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF3E4042)
                        : const Color(0xFFDADADA)),
                _buildSettingItem(
                  context,
                  CustomIcons.shield,
                  'Política de privacidade',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TermsScreen(type: TermsType.privacy),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF3E4042)
                        : const Color(0xFFDADADA)),
                _buildSettingItem(
                  context,
                  CustomIcons.globe,
                  'Sobre',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TermsScreen(type: TermsType.about),
                      ),
                    );
                  },
                  isDark,
                  textColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Logout Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(
                  context, authProvider, isDark, cardColor, textColor, hintColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFA383E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(
                    CustomIcons.logout,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
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
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.string(
                iconSvg,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1877F2),
                  BlendMode.srcIn,
                ),
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
            SvgPicture.string(
              CustomIcons.chevronRight,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider,
      bool isDark, Color cardColor, Color textColor, Color hintColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFA383E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.string(
                  CustomIcons.logout,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFA383E),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Terminar sessão?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja sair da sua conta?',
            style: TextStyle(
              fontSize: 15,
              color: hintColor,
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: hintColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFA383E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sair',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearHistoryDialog(BuildContext context, bool isDark,
      Color cardColor, Color textColor, Color hintColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFA383E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.string(
                  CustomIcons.trash,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFA383E),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eliminar histórico?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja eliminar todo o histórico de atividade? Esta ação não pode ser desfeita.',
            style: TextStyle(
              fontSize: 15,
              color: hintColor,
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: hintColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                CustomSnackbar.showSuccess(
                  context,
                  message: 'Histórico eliminado com sucesso',
                  isDark: isDark,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFA383E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
              ? const Color(0xFF1877F2)
              : isDark
                  ? const Color(0xFF3A3B3C)
                  : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1877F2)
                : isDark
                    ? const Color(0xFF3E4042)
                    : const Color(0xFFDADADA),
            width: 1.5,
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
                      ? const Color(0xFFB0B3B8)
                      : const Color(0xFF65676B),
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