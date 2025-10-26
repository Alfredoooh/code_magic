// create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'styles.dart';

class CreatePostScreen extends StatefulWidget {
  final String token;

  const CreatePostScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _isPosting = false;
  List<XFile> _selectedImages = [];
  String _selectedCategory = 'Análise';
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Análise', 'icon': Icons.analytics_rounded, 'color': AppColors.primary},
    {'name': 'Estratégia', 'icon': Icons.psychology_rounded, 'color': AppColors.success},
    {'name': 'Notícia', 'icon': Icons.newspaper_rounded, 'color': AppColors.info},
    {'name': 'Dica', 'icon': Icons.lightbulb_rounded, 'color': AppColors.warning},
    {'name': 'Pergunta', 'icon': Icons.help_rounded, 'color': AppColors.secondary},
    {'name': 'Discussão', 'icon': Icons.forum_rounded, 'color': AppColors.tertiary},
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(AppMotion.short, () {
      if (mounted) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      AppHaptics.light();
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
        AppHaptics.success();
      }
    } catch (e) {
      if (mounted) {
        AppHaptics.error();
        AppSnackbar.error(context, 'Erro ao selecionar imagem');
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      AppHaptics.light();
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        AppHaptics.success();
      }
    } catch (e) {
      if (mounted) {
        AppHaptics.error();
        AppSnackbar.error(context, 'Erro ao selecionar imagens');
      }
    }
  }

  void _removeImage(int index) {
    AppHaptics.light();
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _publishPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Adicione um título ou conteúdo');
      return;
    }

    setState(() => _isPosting = true);
    AppHaptics.medium();

    // Simular upload e publicação
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      AppHaptics.success();
      Navigator.pop(context, {
        'title': title,
        'content': content,
        'category': _selectedCategory,
        'images': _selectedImages.length,
      });

      AppSnackbar.success(context, 'Publicado com sucesso!');
    }
  }

  void _showDiscardDialog() {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty &&
        _selectedImages.isEmpty) {
      Navigator.pop(context);
      return;
    }

    AppHaptics.warning();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar rascunho?'),
        content: const Text('Suas alterações não serão salvas.'),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Selecione a categoria',
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final isSelected = category['name'] == _selectedCategory;

                return FadeInWidget(
                  delay: Duration(milliseconds: 50 * index),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: category['color'] as Color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category['name'] as String,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () {
                      AppHaptics.selection();
                      setState(() {
                        _selectedCategory = category['name'] as String;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = (_titleController.text.trim().isNotEmpty ||
                            _contentController.text.trim().isNotEmpty) &&
                        !_isPosting;

    final selectedCategoryData = _categories.firstWhere(
      (cat) => cat['name'] == _selectedCategory,
      orElse: () => _categories[0],
    );

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            AppHaptics.light();
            _showDiscardDialog();
          },
        ),
        title: const Text('Nova Publicação'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: AnimatedPrimaryButton(
              text: 'Publicar',
              icon: Icons.send_rounded,
              onPressed: canPublish ? _publishPost : null,
              isLoading: _isPosting,
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isPosting,
        message: 'Publicando...',
        child: Column(
          children: [
            // Categoria
            FadeInWidget(
              child: GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: (selectedCategoryData['color'] as Color)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: (selectedCategoryData['color'] as Color)
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selectedCategoryData['icon'] as IconData,
                        color: selectedCategoryData['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _selectedCategory,
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selectedCategoryData['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: selectedCategoryData['color'] as Color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    FadeInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: context.textStyles.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Título',
                          hintStyle: context.textStyles.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _contentFocusNode.requestFocus();
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Conteúdo
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        style: context.textStyles.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Escreva sua análise, estratégia ou opinião sobre o mercado...',
                          hintStyle: context.textStyles.bodyLarge?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        minLines: 10,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    // Imagens selecionadas
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      FadeInWidget(
                        delay: const Duration(milliseconds: 300),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children:
                              _selectedImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            
                            return StaggeredListItem(
                              index: index,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    child: Image.file(
                                      File(image.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: AppSpacing.xs,
                                    right: AppSpacing.xs,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.massive),
                  ],
                ),
              ),
            ),

            // Barra de ferramentas
            Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: context.colors.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _buildToolbarButton(
                        icon: Icons.image_rounded,
                        label: 'Foto',
                        onTap: _pickImage,
                      ),
                      _buildToolbarButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeria',
                        onTap: _pickMultipleImages,
                      ),
                      _buildToolbarButton(
                        icon: Icons.attach_file_rounded,
                        label: 'Anexar',
                        onTap: () {
                          AppHaptics.light();
                          AppSnackbar.info(
                            context,
                            'Em breve: Anexar arquivos',
                          );
                        },
                      ),
                      _buildToolbarButton(
                        icon: Icons.format_bold_rounded,
                        label: 'Formato',
                        onTap: () {
                          AppHaptics.light();
                          AppSnackbar.info(
                            context,
                            'Em breve: Formatação de texto',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: context.colors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}