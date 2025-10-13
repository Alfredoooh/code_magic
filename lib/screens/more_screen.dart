// lib/screens/more_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Mais Opções',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          children: [
            _buildOptionCard(
              icon: CupertinoIcons.settings,
              title: 'Configurações',
              subtitle: 'Gerencie suas preferências',
              color: CupertinoColors.systemBlue,
              isDark: isDark,
              onTap: () {
                // Navegar para configurações
              },
            ),
            SizedBox(height: 12),
            _buildOptionCard(
              icon: CupertinoIcons.person_circle,
              title: 'Perfil',
              subtitle: 'Edite suas informações',
              color: CupertinoColors.systemPurple,
              isDark: isDark,
              onTap: () {
                // Navegar para perfil
              },
            ),
            SizedBox(height: 12),
            _buildOptionCard(
              icon: CupertinoIcons.bell,
              title: 'Notificações',
              subtitle: 'Configure suas notificações',
              color: CupertinoColors.systemOrange,
              isDark: isDark,
              onTap: () {
                // Navegar para notificações
              },
            ),
            SizedBox(height: 12),
            _buildOptionCard(
              icon: CupertinoIcons.shield,
              title: 'Privacidade',
              subtitle: 'Controle sua privacidade',
              color: CupertinoColors.systemGreen,
              isDark: isDark,
              onTap: () {
                // Navegar para privacidade
              },
            ),
            SizedBox(height: 12),
            _buildOptionCard(
              icon: CupertinoIcons.question_circle,
              title: 'Ajuda',
              subtitle: 'Central de suporte',
              color: CupertinoColors.systemYellow,
              isDark: isDark,
              onTap: () {
                // Navegar para ajuda
              },
            ),
            SizedBox(height: 12),
            _buildOptionCard(
              icon: CupertinoIcons.info_circle,
              title: 'Sobre',
              subtitle: 'Informações do aplicativo',
              color: CupertinoColors.systemGrey,
              isDark: isDark,
              onTap: () {
                // Navegar para sobre
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
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
                  SizedBox(height: 4),
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
}