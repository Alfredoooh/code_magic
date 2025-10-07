import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/theme_service.dart';

// hub_tab.dart
class HubTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        title: Text(
          'Hub',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildHubCard(CupertinoIcons.calendar, 'Calendário', Colors.orange),
          _buildHubCard(CupertinoIcons.folder, 'Arquivos', Colors.blue),
          _buildHubCard(CupertinoIcons.camera, 'Galeria', Colors.purple),
          _buildHubCard(CupertinoIcons.music_note, 'Música', Colors.red),
          _buildHubCard(CupertinoIcons.doc_text, 'Documentos', Colors.green),
          _buildHubCard(CupertinoIcons.settings, 'Configurações', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHubCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: ThemeService.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
