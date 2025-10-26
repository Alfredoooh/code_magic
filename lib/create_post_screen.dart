// lib/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

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
    AppDialog.show(
      context: context,
      title: 'Descartar rascunho?',
      content: 'Suas alterações não serão salvas.',
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.error,
      actions: [
        TertiaryButton(
          text: 'Cancelar',
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        PrimaryButton(
          text: 'Descartar',
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showCategoryPicker() {
    AppHaptics.light();
    AppModalBottomSheet.show(
      context: context,
      title: 'Selecione a categoria',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = category['name'] == _selectedCategory;

          return FadeInWidget(
            delay: Duration(milliseconds: 50 * index),
            child: AppListTile(
              leading: Container(
                padding: EdgeInsets.all(AppSpacing.sm),
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
              title: category['name'] as String,
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
      appBar: PrimaryAppBar(
        title: 'Nova Publicação',
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            AppHaptics.light();
            _showDiscardDialog();
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: PrimaryButton(
              text: 'Publicar',
              icon: Icons.send_rounded,
              onPressed: canPublish ? _publishPost : null,
              loading: _isPosting,
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
                  margin: EdgeInsets.all(AppSpacing.lg),
                  padding: EdgeInsets.symmetric(
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
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        _selectedCategory,
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selectedCategoryData['color'] as Color,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
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
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    FadeInWidget(
                      delay: Duration(milliseconds: 100),
                      child: AppTextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        hint: 'Título',
                        textStyle: context.textStyles.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: null,
                        onSubmitted: (_) {
                          _contentFocusNode.requestFocus();
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // Conteúdo
                    FadeInWidget(
                      delay: Duration(milliseconds: 200),
                      child: AppTextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        hint: 'Escreva sua análise, estratégia ou opinião sobre o mercado...',
                        maxLines: null,
                        minLines: 10,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    // Imagens selecionadas
                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xl),
                      FadeInWidget(
                        delay: Duration(milliseconds: 300),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _selectedImages.asMap().entries.map((entry) {
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
                                    child: IconButtonWithBackground(
                                      icon: Icons.close_rounded,
                                      onPressed: () => _removeImage(index),
                                      backgroundColor: Colors.black87,
                                      iconColor: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    SizedBox(height: AppSpacing.massive),
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
                  padding: EdgeInsets.symmetric(
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
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: context.colors.onSurfaceVariant,
                  size: 24,
                ),
                SizedBox(height: AppSpacing.xxs),
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