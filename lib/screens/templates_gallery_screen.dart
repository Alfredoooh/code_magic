// lib/screens/templates_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../providers/theme_provider.dart';

/// GALERIA COMPLETA de templates da APP (imagens via URL).
/// Ao tocar num template, o widget faz `Navigator.pop(context, template)`,
/// retornando o DocumentTemplate selecionado para a tela chamadora.
class TemplatesGalleryScreen extends StatelessWidget {
  final DocumentCategory category;
  const TemplatesGalleryScreen({super.key, required this.category});

  String _categoryName(DocumentCategory c) {
    switch (c) {
      case DocumentCategory.curriculum: return 'Currículo';
      case DocumentCategory.certificate: return 'Certificado';
      case DocumentCategory.letter: return 'Carta/Câmara';
      case DocumentCategory.report: return 'Relatório';
      case DocumentCategory.contract: return 'Contrato';
      case DocumentCategory.invoice: return 'Fatura';
      case DocumentCategory.presentation: return 'Apresentação';
      case DocumentCategory.essay: return 'Trabalho Acadêmico';
      case DocumentCategory.other: return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentService documentService = DocumentService();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bg = isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(_categoryName(category)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fechar',
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentTemplate>>(
        stream: documentService.getTemplatesByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.folder_open_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('Nenhum template nesta categoria'),
                ],
              ),
            );
          }

          // Grid de templates: toca para selecionar e retornar o template
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return GestureDetector(
                onTap: () {
                  // Retorna o template seleccionado para a tela anterior
                  Navigator.of(context).pop(t);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: t.imageUrl.startsWith('http')
                              ? Image.network(t.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                              : Image.network(t.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
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