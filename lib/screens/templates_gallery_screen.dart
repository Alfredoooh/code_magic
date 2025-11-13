// lib/screens/templates_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';

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

  void _showIndexInfo(BuildContext context, bool isDark) {
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final codeColor = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFF1877F2),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Índice Necessário',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Para consultar templates por categoria, você precisa criar este índice composto no Firebase:',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: codeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark 
                      ? const Color(0xFF3E4042) 
                      : const Color(0xFFDADADA),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Coleção: document_templates',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          color: const Color(0xFF1877F2),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: 'document_templates'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coleção copiada!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      'Campos indexados:',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIndexField('category', 'Ascending', textColor, context),
                    const SizedBox(height: 4),
                    _buildIndexField('createdAt', 'Descending', textColor, context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Link do Console Firebase:',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'https://console.firebase.google.com/project/_/firestore/indexes',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copiado!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1877F2).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'https://console.firebase.google.com/project/_/firestore/indexes',
                          style: TextStyle(
                            color: const Color(0xFF1877F2),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.copy,
                        size: 16,
                        color: Color(0xFF1877F2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendi',
              style: TextStyle(
                color: Color(0xFF1877F2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexField(String field, String order, Color textColor, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$field: $order',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: field));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Campo "$field" copiado!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: const Icon(
              Icons.copy,
              size: 14,
              color: Color(0xFF1877F2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _categoryName(category),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: const Color(0xFF1877F2),
            onPressed: () => _showIndexInfo(context, isDark),
            tooltip: 'Informações do Índice',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('document_templates')
            .where('category', isEqualTo: category.name)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1877F2),
              ),
            );
          }

          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            final needsIndex = errorMessage.contains('index') || 
                              errorMessage.contains('FAILED_PRECONDITION');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: needsIndex 
                          ? const Color(0xFFFF9800).withOpacity(0.1)
                          : const Color(0xFFFA383E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        needsIndex ? Icons.list_alt : Icons.error_outline,
                        size: 50,
                        color: needsIndex 
                          ? const Color(0xFFFF9800)
                          : const Color(0xFFFA383E),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      needsIndex ? 'Índice Necessário' : 'Erro ao carregar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      needsIndex
                          ? 'É necessário criar um índice no Firebase para esta consulta.'
                          : 'Ocorreu um erro ao carregar os templates.',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showIndexInfo(context, isDark),
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: Text(
                        needsIndex ? 'Ver Instruções' : 'Ver Detalhes',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_outlined,
                      size: 50,
                      color: const Color(0xFF1877F2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhum template disponível',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta categoria ainda não possui templates',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
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
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Sem nome';
              final description = data['description'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';
              final createdBy = data['createdBy'] ?? 'Desconhecido';
              final usageCount = data['usageCount'] ?? 0;

              return GestureDetector(
                onTap: () {
                  // Retorna o template selecionado
                  Navigator.of(context).pop(DocumentTemplate(
                    id: doc.id,
                    name: name,
                    description: description,
                    imageUrl: imageUrl,
                    category: category,
                    usageCount: usageCount,
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Imagem
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: isDark 
                                        ? const Color(0xFF3A3B3C) 
                                        : const Color(0xFFF0F2F5),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: const Color(0xFF1877F2),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: isDark 
                                      ? const Color(0xFF3A3B3C) 
                                      : const Color(0xFFF0F2F5),
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: secondaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: isDark 
                                    ? const Color(0xFF3A3B3C) 
                                    : const Color(0xFFF0F2F5),
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: secondaryColor.withOpacity(0.5),
                                  ),
                                ),
                        ),
                      ),

                      // Info
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Criado por
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: secondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      createdBy,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Usos
                              Row(
                                children: [
                                  Icon(
                                    Icons.file_copy_outlined,
                                    size: 12,
                                    color: const Color(0xFF1877F2),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$usageCount usos',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF1877F2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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