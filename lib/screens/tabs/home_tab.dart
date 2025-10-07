import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/theme_service.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_circle),
            onPressed: () {
              _showProfileSheet(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(user, textColor),
            const SizedBox(height: 20),
            _buildQuickActions(context, textColor),
            const SizedBox(height: 20),
            _buildRecentActivity(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1877F2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo de volta!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.displayName ?? user?.email?.split('@')[0] ?? 'Usuário',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.chat_bubble_2_fill,
                title: 'Nova Conversa',
                color: Colors.blue,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.arrow_2_squarepath,
                title: 'Converter',
                color: Colors.orange,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.news_solid,
                title: 'Notícias',
                color: Colors.red,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: CupertinoIcons.settings,
                title: 'Configurações',
                color: Colors.grey,
                onTap: () => _showProfileSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atividade Recente',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: CupertinoIcons.chat_bubble,
          title: 'Mensagem enviada',
          time: 'Há 5 minutos',
          textColor: textColor,
        ),
        _buildActivityItem(
          icon: CupertinoIcons.arrow_2_squarepath,
          title: 'Conversão realizada',
          time: 'Há 1 hora',
          textColor: textColor,
        ),
        _buildActivityItem(
          icon: CupertinoIcons.news,
          title: 'Notícia lida',
          time: 'Há 2 horas',
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF1877F2),
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
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileSheet(),
    );
  }
}

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bgColor = ThemeService.currentTheme == AppTheme.deepDark
        ? const Color(0xFF000000)
        : ThemeService.currentTheme == AppTheme.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFFFFFFF);
    
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF1877F2),
                  child: Text(
                    (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Usuário',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildThemeSelector(context, textColor),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemeOption(
                context,
                'Claro',
                AppTheme.light,
                CupertinoIcons.sun_max,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOption(
                context,
                'Escuro',
                AppTheme.dark,
                CupertinoIcons.moon,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOption(
                context,
                'Profundo',
                AppTheme.deepDark,
                CupertinoIcons.moon_stars,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    AppTheme theme,
    IconData icon,
  ) {
    final isSelected = ThemeService.currentTheme == theme;

    return GestureDetector(
      onTap: () {
        ThemeService.setTheme(theme);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1877F2)
              : const Color(0xFF1877F2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF1877F2),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1877F2),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Sair',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
