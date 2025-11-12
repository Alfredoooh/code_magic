// lib/screens/new_request_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
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
    {'name': 'Currículo', 'icon': CustomIcons.person, 'category': DocumentCategory.curriculum},
    {'name': 'Certificado', 'icon': CustomIcons.certificate, 'category': DocumentCategory.certificate},
    {'name': 'Carta', 'icon': CustomIcons.envelope, 'category': DocumentCategory.letter},
    {'name': 'Relatório', 'icon': CustomIcons.description, 'category': DocumentCategory.report},
    {'name': 'Contrato', 'icon': CustomIcons.contract, 'category': DocumentCategory.contract},
    {'name': 'Fatura', 'icon': CustomIcons.invoice, 'category': DocumentCategory.invoice},
    {'name': 'Apresentação', 'icon': CustomIcons.presentation, 'category': DocumentCategory.presentation},
    {'name': 'Trabalho', 'icon': CustomIcons.school, 'category': DocumentCategory.essay},
    {'name': 'Outro', 'icon': CustomIcons.folder, 'category': DocumentCategory.other},
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTemplates() async {
    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione uma categoria primeiro'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await Navigator.of(context).push<DocumentTemplate>(
      MaterialPageRoute(
        builder: (_) => TemplatesGalleryScreen(category: _selectedCategory!),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedTemplate = result);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o que precisa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido enviado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.close,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Novo Pedido',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Categorias horizontais
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: cardColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['category'];

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat['category'];
                    _selectedTemplate = null;
                  }),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1877F2)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          cat['icon'] as String,
                          width: 28,
                          height: 28,
                          colorFilter: ColorFilter.mode(
                            isSelected ? Colors.white : textColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Área de conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedCategory == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            SvgPicture.string(
                              CustomIcons.folder,
                              width: 64,
                              height: 64,
                              colorFilter: ColorFilter.mode(
                                secondaryColor.withOpacity(0.5),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Selecione uma categoria',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Template selecionado
                    if (_selectedTemplate != null) ...[
                      Text(
                        'Template Selecionado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _selectedTemplate!.imageUrl.startsWith('http')
                                  ? Image.network(
                                      _selectedTemplate!.imageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedTemplate!.imageUrl),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTemplate = null),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.string(
                                    CustomIcons.close,
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Descrição
                    Text(
                      'Descreva seu pedido',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 6,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Descreva detalhadamente o que você precisa...',
                          hintStyle: TextStyle(
                            color: secondaryColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Barra inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Botão adicionar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: SvgPicture.string(
                        CustomIcons.add,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF1877F2),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: _selectedCategory == null
                          ? null
                          : () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  child: SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: secondaryColor.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1877F2).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: SvgPicture.string(
                                              CustomIcons.image,
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                Color(0xFF1877F2),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'Galeria',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Escolher da galeria',
                                            style: TextStyle(color: secondaryColor),
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _pickImage();
                                          },
                                        ),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1877F2).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: SvgPicture.string(
                                              CustomIcons.folder,
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                Color(0xFF1877F2),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'Templates',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Escolher um template',
                                            style: TextStyle(color: secondaryColor),
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _openTemplates();
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Botão enviar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Enviar Pedido',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.string(
                            CustomIcons.send,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
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