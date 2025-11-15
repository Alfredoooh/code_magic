// lib/screens/templates_gallery_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../models/document_template_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';

class TemplatesGalleryScreen extends StatefulWidget {
  final DocumentCategory category;
  const TemplatesGalleryScreen({super.key, required this.category});

  @override
  State<TemplatesGalleryScreen> createState() => _TemplatesGalleryScreenState();
}

class _TemplatesGalleryScreenState extends State<TemplatesGalleryScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allTemplates = <Map<String, dynamic>>[];
      int fileIndex = 1;
      int consecutiveErrors = 0;
      const maxConsecutiveErrors = 3;

      // Tenta carregar templates.json, templates1.json, templates2.json, etc
      while (consecutiveErrors < maxConsecutiveErrors) {
        final fileName = fileIndex == 1 ? 'templates.json' : 'templates$fileIndex.json';
        final url = 'https://raw.githubusercontent.com/Alfredoooh/data-server/main/public/$fileName';

        try {
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final templates = (data['templates'] as List).cast<Map<String, dynamic>>();
            
            if (templates.isNotEmpty) {
              allTemplates.addAll(templates);
              consecutiveErrors = 0; // Reset contador de erros
              print('✅ Carregado: $fileName (${templates.length} templates)');
            }
          } else if (response.statusCode == 404) {
            consecutiveErrors++;
            print('⚠️ Não encontrado: $fileName');
          } else {
            consecutiveErrors++;
            print('❌ Erro ${response.statusCode}: $fileName');
          }
        } catch (e) {
          consecutiveErrors++;
          print('❌ Erro ao carregar $fileName: $e');
        }

        fileIndex++;
        await Future.delayed(const Duration(milliseconds: 200));
      }

      print('📊 Total de templates carregados: ${allTemplates.length}');

      setState(() {
        _templates = allTemplates
            .where((t) => t['category'] == widget.category.name)
            .toList();
        _isLoading = false;
        
        print('🎯 Templates da categoria ${widget.category.name}: ${_templates.length}');
      });
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

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

  void _showTemplatePreview(BuildContext context, Map<String, dynamic> template) {
    final images = (template['images'] as List).cast<String>();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _TemplatePreviewScreen(
          templateName: template['name'],
          images: images,
        ),
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
        centerTitle: true,
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
          _categoryName(widget.category),
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1877F2),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadTemplates,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 64,
                            color: secondaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum template disponível',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        final images = (template['images'] as List).cast<String>();
                        final hasMultiplePages = images.length > 1;

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(DocumentTemplate(
                              id: template['id'],
                              name: template['name'],
                              description: template['description'],
                              imageUrl: images.first,
                              category: widget.category,
                              usageCount: template['usageCount'] ?? 0,
                              createdAt: DateTime.parse(template['createdAt']),
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
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          images.first,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                      if (hasMultiplePages)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.collections,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${images.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => _showTemplatePreview(context, template),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1877F2),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.visibility,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
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
                                              template['createdBy'],
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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.file_copy_outlined,
                                            size: 12,
                                            color: Color(0xFF1877F2),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${template['usageCount']} usos',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF1877F2),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _TemplatePreviewScreen extends StatefulWidget {
  final String templateName;
  final List<String> images;

  const _TemplatePreviewScreen({
    required this.templateName,
    required this.images,
  });

  @override
  State<_TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<_TemplatePreviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFF000000);
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.templateName,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF1877F2)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPage + 1}/${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}