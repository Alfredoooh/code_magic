import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import '../svg_icons.dart';
import 'custom_switch.dart';

class AppDrawer extends StatelessWidget {
  final bool isDarkTheme;
  final VoidCallback onThemeToggle;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const AppDrawer({
    Key? key,
    required this.isDarkTheme,
    required this.onThemeToggle,
    required this.onRefresh,
    required this.onClose,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(color: surfaceColor),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Divider(color: borderColor),
            _buildThemeToggle(),
            Divider(color: borderColor),
            Expanded(child: _buildMenuItems()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: borderColor,
            ),
            child: Center(
              child: SvgPicture.string(
                SvgIcons.profileFilled,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Usuario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            isDarkTheme ? Ionicons.moon : Ionicons.sunny,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isDarkTheme ? 'Modo Escuro' : 'Modo Claro',
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ),
          CustomSwitch(
            value: isDarkTheme,
            onChanged: (_) => onThemeToggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildMenuItem(Ionicons.refresh_outline, 'Atualizar Feed', () {
          onClose();
          onRefresh();
        }),
        _buildMenuItem(Ionicons.globe_outline, 'Todas as Fontes', () {}),
        _buildMenuItem(Ionicons.star_outline, 'Favoritos', () {}),
        _buildMenuItem(Ionicons.settings_outline, 'Configurações', () {}),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}