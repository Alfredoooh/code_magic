import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/theme_service.dart';

class HubTab extends StatelessWidget {
  const HubTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Hub'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildHubCard(
            icon: CupertinoIcons.graph_circle,
            title: 'Análise',
            color: Colors.blue,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.calendar,
            title: 'Calendário',
            color: Colors.red,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.photo,
            title: 'Galeria',
            color: Colors.purple,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.music_note,
            title: 'Música',
            color: Colors.pink,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.folder,
            title: 'Arquivos',
            color: Colors.orange,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.bookmark,
            title: 'Salvos',
            color: Colors.green,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.chart_bar,
            title: 'Estatísticas',
            color: Colors.teal,
            onTap: () {},
          ),
          _buildHubCard(
            icon: CupertinoIcons.gear,
            title: 'Ferramentas',
            color: Colors.grey,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
