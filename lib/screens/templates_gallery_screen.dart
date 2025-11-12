// lib/screens/templates_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../providers/theme_provider.dart';

class TemplatesGalleryScreen extends StatelessWidget {
  final DocumentCategory category;
  const TemplatesGalleryScreen({super.key, required this.category});

  String _categoryName(DocumentCategory c) {
    switch (c) {
      case DocumentCategory.curriculum:
        return 'Currículo';
      case DocumentCategory.certificate:
        return 'Certificado';
      case DocumentCategory.letter:
        return 'Carta';
      case DocumentCategory.report:
        return 'Relatório';
      case DocumentCategory.contract:
        return 'Contrato';
      case DocumentCategory.invoice:
        return 'Fatura';
      case DocumentCategory.presentation:
        return 'Apresentação';
      case DocumentCategory.essay:
        return 'Trabalho';
      case DocumentCategory.other:
        return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentService documentService = DocumentService();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final cardColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _categoryName(category),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<DocumentTemplate>>(
        stream: documentService.getTemplatesByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1877F2),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 64,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum template disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(t),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            t.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: const Color(0xFF1877F2),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E5E5),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            if (t.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                t.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}