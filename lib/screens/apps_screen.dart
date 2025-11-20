// apps_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'word_editor_screen.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    final apps = [
      {
        'name': 'Word',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF2B579A),
        'description': 'Editor de documentos',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WordEditorScreen()),
        ),
      },
      {
        'name': 'Excel',
        'icon': Icons.grid_on_rounded,
        'color': const Color(0xFF217346),
        'description': 'Planilhas',
        'onTap': () {},
      },
      {
        'name': 'PowerPoint',
        'icon': Icons.slideshow_rounded,
        'color': const Color(0xFFD24726),
        'description': 'Apresentações',
        'onTap': () {},
      },
      {
        'name': 'OneNote',
        'icon': Icons.note_rounded,
        'color': const Color(0xFF7719AA),
        'description': 'Anotações',
        'onTap': () {},
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Apps',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: app['onTap'] as VoidCallback?,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (app['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  app['icon'] as IconData,
                  color: app['color'] as Color,
                  size: 28,
                ),
              ),
              title: Text(
                app['name'] as String,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                app['description'] as String,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: textColor.withOpacity(0.3),
                size: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}