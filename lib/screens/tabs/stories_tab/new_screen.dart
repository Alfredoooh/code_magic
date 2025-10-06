// new_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF000000),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
          ),
        ),
        middle: const Text(
          'Mais',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            _buildMenuItem(
              icon: CupertinoIcons.gear_alt_fill,
              title: 'Configurações',
              subtitle: 'Personalize seu aplicativo',
              onTap: () {
                // Ação para configurações
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.star_fill,
              title: 'Favoritos',
              subtitle: 'Seus conteúdos salvos',
              onTap: () {
                // Ação para favoritos
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.bookmark_fill,
              title: 'Leitura Posterior',
              subtitle: 'Artigos para ler depois',
              onTap: () {
                // Ação para leitura posterior
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.chart_bar_fill,
              title: 'Estatísticas',
              subtitle: 'Veja seu progresso',
              onTap: () {
                // Ação para estatísticas
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.bell_fill,
              title: 'Notificações',
              subtitle: 'Gerencie suas notificações',
              onTap: () {
                // Ação para notificações
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.info_circle_fill,
              title: 'Sobre',
              subtitle: 'Informações do aplicativo',
              onTap: () {
                // Ação para sobre
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: Color(0xFF007AFF),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Desenvolvido com ❤️',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF007AFF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
