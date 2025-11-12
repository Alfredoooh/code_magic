// lib/screens/new_request_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
import 'document_request_detail_screen.dart';
import 'templates_gallery_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  
  DocumentCategory? _selectedCategory;
  bool _showCategories = false;
  bool _showTemplateOptions = false;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

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

  String _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum:
        return CustomIcons.person;
      case DocumentCategory.certificate:
        return CustomIcons.certificate;
      case DocumentCategory.letter:
        return CustomIcons.envelope;
      case DocumentCategory.report:
        return CustomIcons.description;
      case DocumentCategory.contract:
        return CustomIcons.contract;
      case DocumentCategory.invoice:
        return CustomIcons.invoice;
      case DocumentCategory.presentation:
        return CustomIcons.presentation;
      case DocumentCategory.essay:
        return CustomIcons.school;
      case DocumentCategory.other:
        return CustomIcons.folder;
    }
  }

  Color _getCategoryColor(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum:
        return const Color(0xFF1877F2);
      case DocumentCategory.certificate:
        return const Color(0xFF4CAF50);
      case DocumentCategory.letter:
        return const Color(0xFF9C27B0);
      case DocumentCategory.report:
        return const Color(0xFF2196F3);
      case DocumentCategory.contract:
        return const Color(0xFFFF5722);
      case DocumentCategory.invoice:
        return const Color(0xFF009688);
      case DocumentCategory.presentation:
        return const Color(0xFFFF9800);
      case DocumentCategory.essay:
        return const Color(0xFF673AB7);
      case DocumentCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  void _selectCategory(DocumentCategory category) {
    setState(() {
      _selectedCategory = category;
      _showCategories = false;
    });
    _inputFocus.requestFocus();
  }

  void _removeCategory() {
    setState(() {
      _selectedCategory = null;
    });
  }

  void _toggleCategories() {
    setState(() {
      _showCategories = !_showCategories;
      if (_showCategories) {
        _showTemplateOptions = false;
        _inputFocus.unfocus();
      }
    });
  }

  void _toggleTemplateOptions() {
    setState(() {
      _showTemplateOptions = !_showTemplateOptions;
      if (_showTemplateOptions) {
        _showCategories = false;
        _inputFocus.unfocus();
      }
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Processar imagem da galeria
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem selecionada da galeria')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _navigateToTemplates() {
    if (_selectedCategory != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplatesGalleryScreen(category: _selectedCategory!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria primeiro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final borderColor = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB);

    return GestureDetector(
      onTap: () {
        setState(() {
          _showCategories = false;
          _showTemplateOptions = false;
        });
        _inputFocus.unfocus();
      },
      child: Container(
        color: bgColor,
        child: SafeArea(
          child: Stack(
            children: [
              // Área principal (vazia quando não há categorias/opções abertas)
              if (!_showCategories && !_showTemplateOptions)
                Center(
                  child: Opacity(
                    opacity: 0.3,
                    child: SvgPicture.string(
                      CustomIcons.addCircle,
                      width: 120,
                      height: 120,
                      colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                    ),
                  ),
                ),

              // Painel de categorias
              if (_showCategories)
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecione uma categoria',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: DocumentCategory.values.map((category) {
                              final color = _getCategoryColor(category);
                              return GestureDetector(
                                onTap: () => _selectCategory(category),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.string(
                                        _getCategoryIcon(category),
                                        width: 20,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(
                                          color,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getCategoryName(category),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Painel de opções de template
              if (_showTemplateOptions)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TemplateOptionCard(
                          icon: CustomIcons.image,
                          title: 'Template da Galeria',
                          description: 'Escolher uma imagem da galeria',
                          color: const Color(0xFF4CAF50),
                          onTap: _pickFromGallery,
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          hintColor: hintColor,
                        ),
                        const SizedBox(height: 16),
                        _TemplateOptionCard(
                          icon: CustomIcons.folder,
                          title: 'Templates',
                          description: 'Ver templates disponíveis',
                          color: const Color(0xFF1877F2),
                          onTap: _navigateToTemplates,
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          hintColor: hintColor,
                        ),
                      ],
                    ),
                  ),
                ),

              // Barra de input (sempre no bottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(
                      top: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tag da categoria selecionada
                      if (_selectedCategory != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(_selectedCategory!)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.string(
                                      _getCategoryIcon(_selectedCategory!),
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                        _getCategoryColor(_selectedCategory!),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getCategoryName(_selectedCategory!),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _getCategoryColor(_selectedCategory!),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: _removeCategory,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: _getCategoryColor(_selectedCategory!),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Input principal
                      Row(
                        children: [
                          // Botão de categorias
                          GestureDetector(
                            onTap: _toggleCategories,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _showCategories
                                    ? const Color(0xFF1877F2).withOpacity(0.15)
                                    : (isDark
                                        ? const Color(0xFF3A3B3C)
                                        : const Color(0xFFF0F2F5)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.string(
                                  CustomIcons.addCircle,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    _showCategories
                                        ? const Color(0xFF1877F2)
                                        : hintColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Campo de texto
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3A3B3C)
                                    : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _inputController,
                                focusNode: _inputFocus,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Descreva o que deseja criar...',
                                  hintStyle: TextStyle(color: hintColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Botão de template/arquivo
                          GestureDetector(
                            onTap: _toggleTemplateOptions,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _showTemplateOptions
                                    ? const Color(0xFF1877F2).withOpacity(0.15)
                                    : (isDark
                                        ? const Color(0xFF3A3B3C)
                                        : const Color(0xFFF0F2F5)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: _showTemplateOptions
                                      ? const Color(0xFF1877F2)
                                      : hintColor,
                                  size: 24,
                                ),
                              ),
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
      ),
    );
  }
}

class _TemplateOptionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;

  const _TemplateOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
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
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.string(
                  icon,
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: hintColor,
            ),
          ],
        ),
      ),
    );
  }
}