// lib/screens/templates_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
import 'document_request_detail_screen.dart';

class TemplatesGalleryScreen extends StatefulWidget {
  final DocumentCategory category;

  const TemplatesGalleryScreen({
    super.key,
    required this.category,
  });

  @override
  State<TemplatesGalleryScreen> createState() => _TemplatesGalleryScreenState();
}

class _TemplatesGalleryScreenState extends State<TemplatesGalleryScreen> {
  final DocumentService _documentService = DocumentService();

  String _getCategoryName(DocumentCategory category) {
    switch (category) {
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
        return 'Trabalho Acadêmico';
      case DocumentCategory.other:
        return 'Outro';
    }
  }

  void _selectTemplate(DocumentTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentRequestDetailScreen(template: template),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final borderColor = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getCategoryName(widget.category),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: borderColor,
            height: 1,
          ),
        ),
      ),
      body: StreamBuilder<List<DocumentTemplate>>(
        stream: _documentService.getTemplatesByCategory(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: hintColor),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar templates',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 13, color: hintColor),
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
                  SvgPicture.string(
                    CustomIcons.folder,
                    width: 64,
                    height: 64,
                    colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum template disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Novos templates serão adicionados em breve',
                    style: TextStyle(
                      fontSize: 13,
                      color: hintColor,
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
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return _TemplateCard(
                template: templates[index],
                onTap: () => _selectTemplate(templates[index]),
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                hintColor: hintColor,
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  template.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? const Color(0xFF3A3B3C)
                          : const Color(0xFFF0F2F5),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: hintColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (template.usageCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.string(
                          CustomIcons.star,
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFFFA000),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.usageCount} usos',
                          style: TextStyle(
                            fontSize: 11,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}