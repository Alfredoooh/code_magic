// lib/screens/new_request_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import 'templates_gallery_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DocumentCategory? _selectedCategory;
  DocumentTemplate? _selectedTemplate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Currículo', 'icon': Icons.person_outline, 'category': DocumentCategory.curriculum},
    {'name': 'Certificado', 'icon': Icons.workspace_premium_outlined, 'category': DocumentCategory.certificate},
    {'name': 'Carta', 'icon': Icons.mail_outline, 'category': DocumentCategory.letter},
    {'name': 'Relatório', 'icon': Icons.description_outlined, 'category': DocumentCategory.report},
    {'name': 'Contrato', 'icon': Icons.gavel_outlined, 'category': DocumentCategory.contract},
    {'name': 'Fatura', 'icon': Icons.receipt_outlined, 'category': DocumentCategory.invoice},
    {'name': 'Apresentação', 'icon': Icons.slideshow_outlined, 'category': DocumentCategory.presentation},
    {'name': 'Trabalho', 'icon': Icons.school_outlined, 'category': DocumentCategory.essay},
    {'name': 'Outro', 'icon': Icons.folder_outlined, 'category': DocumentCategory.other},
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        setState(() {
          _selectedTemplate = DocumentTemplate(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Imagem',
            description: 'Da galeria',
            imageUrl: file.path,
            usageCount: 0,
            category: _selectedCategory ?? DocumentCategory.other,
            createdAt: DateTime.now(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _openTemplates() async {
    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma categoria primeiro')));
      }
      return;
    }

    final result = await Navigator.of(context).push<DocumentTemplate>(
      MaterialPageRoute(builder: (_) => TemplatesGalleryScreen(category: _selectedCategory!)),
    );

    if (result != null && mounted) {
      setState(() => _selectedTemplate = result);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma categoria')));
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descreva o que precisa')));
      return;
    }

    // Envio simples (implementação real no DocumentService)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido enviado!')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Novo Pedido',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['category'];

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat['category'];
                    _selectedTemplate = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1877F2) : cardColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 18, color: isSelected ? Colors.white : textColor),
                        const SizedBox(width: 6),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : textColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedCategory == null
                ? Center(child: Text('Selecione uma categoria', style: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93))))
                : _selectedTemplate != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _selectedTemplate!.imageUrl.startsWith('http')
                                      ? Image.network(_selectedTemplate!.imageUrl, height: 200, fit: BoxFit.cover)
                                      : Image.file(File(_selectedTemplate!.imageUrl), height: 200, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedTemplate = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E5E5), width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1877F2)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                          decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(height: 20),
                                ListTile(
                                  leading: const Icon(Icons.image_outlined, color: Color(0xFF1877F2)),
                                  title: const Text('Galeria'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.folder_outlined, color: Color(0xFF1877F2)),
                                  title: const Text('Templates'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openTemplates();
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Descreva o que precisa...',
                          hintStyle: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}