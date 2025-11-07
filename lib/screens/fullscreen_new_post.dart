// lib/screens/fullscreen_new_post.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../services/image_service.dart';
import '../widgets/custom_icons.dart';

class FullscreenNewPost extends StatefulWidget {
  final String? initialContent;
  final String? initialImageBase64;
  final String? initialVideoUrl;

  const FullscreenNewPost({
    super.key,
    this.initialContent,
    this.initialImageBase64,
    this.initialVideoUrl,
  });

  @override
  State<FullscreenNewPost> createState() => _FullscreenNewPostState();
}

class _FullscreenNewPostState extends State<FullscreenNewPost> with SingleTickerProviderStateMixin {
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _videoCtrl = TextEditingController();
  final PostService _postService = PostService();
  final FocusNode _contentFocus = FocusNode();

  String? _imageBase64;
  Uint8List? _imageBytes;
  bool _isPosting = false;
  bool _showMediaOptions = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _contentCtrl.text = widget.initialContent ?? '';
    _imageBase64 = widget.initialImageBase64;
    _imageBytes = _imageBase64 != null ? ImageService.base64ToBytes(_imageBase64!) : null;
    _videoCtrl.text = widget.initialVideoUrl ?? '';
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto-focus no campo de texto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _videoCtrl.dispose();
    _contentFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImageGallery() async {
    final base64 = await ImageService.pickImageAsBase64(source: ImageSource.gallery);
    if (base64 == null) return;
    
    final bytes = ImageService.base64ToBytes(base64);
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem muito grande. Máximo 5MB.'),
            backgroundColor: Color(0xFFFA383E),
          ),
        );
      }
      return;
    }
    
    setState(() {
      _imageBase64 = base64;
      _imageBytes = bytes;
      _showMediaOptions = false;
    });
  }

  Future<void> _pickImageCamera() async {
    final base64 = await ImageService.pickImageAsBase64(source: ImageSource.camera);
    if (base64 == null) return;
    
    final bytes = ImageService.base64ToBytes(base64);
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem muito grande. Máximo 5MB.'),
            backgroundColor: Color(0xFFFA383E),
          ),
        );
      }
      return;
    }
    
    setState(() {
      _imageBase64 = base64;
      _imageBytes = bytes;
      _showMediaOptions = false;
    });
  }

  void _removeImage() {
    setState(() {
      _imageBase64 = null;
      _imageBytes = null;
    });
  }

  void _removeVideo() {
    setState(() {
      _videoCtrl.clear();
    });
  }

  Future<void> _showVideoDialog() async {
    final url = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final isDark = context.read<ThemeProvider>().isDarkMode;
        final ctrl = TextEditingController(text: _videoCtrl.text);
        
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB020).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.string(
                        CustomIcons.videoLibrary,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFFFB020),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Adicionar URL de vídeo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cole a URL do vídeo (YouTube, Facebook, Vimeo, etc)',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    
    if (url != null && url.isNotEmpty) {
      setState(() {
        _videoCtrl.text = url;
        _showMediaOptions = false;
      });
    }
  }

  Future<void> _publish() async {
    final content = _contentCtrl.text.trim();
    final videoUrl = _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim();

    if (content.isEmpty && _imageBase64 == null && videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione conteúdo, imagem ou vídeo antes de publicar'),
          backgroundColor: Color(0xFFFA383E),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid ?? '';
      final name = auth.userData?['name'] ?? 'Usuário';
      final avatar = auth.userData?['photoURL'];

      await _postService.createPost(
        userId: uid,
        userName: name,
        userAvatar: avatar,
        content: content,
        imageBase64: _imageBase64,
        videoUrl: videoUrl,
      );

      if (mounted) {
        Navigator.pop(context, {'published': true});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicação criada com sucesso'),
            backgroundColor: Color(0xFF31A24C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _saveAndReturn() {
    Navigator.pop(context, {
      'content': _contentCtrl.text,
      'imageBase64': _imageBase64,
      'videoUrl': _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
    });
  }

  int _getCharacterCount() {
    return _contentCtrl.text.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final characterCount = _getCharacterCount();
    final hasContent = _contentCtrl.text.trim().isNotEmpty || _imageBase64 != null || _videoCtrl.text.trim().isNotEmpty;

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
          'Criar publicação',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (hasContent && !_isPosting)
            TextButton(
              onPressed: _saveAndReturn,
              child: Row(
                children: [
                  SvgPicture.string(
                    CustomIcons.save,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1877F2),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Color(0xFF1877F2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header do usuário
          Container(
            color: cardColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1877F2),
                  backgroundImage: authProvider.userData?['photoURL'] != null
                      ? NetworkImage(authProvider.userData!['photoURL'])
                      : null,
                  child: authProvider.userData?['photoURL'] == null
                      ? Text(
                          authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userData?['name'] ?? 'Usuário',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 12,
                                  color: secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Público',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
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

          // Conteúdo principal
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de texto
                  Container(
                    color: cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _contentCtrl,
                      focusNode: _contentFocus,
                      maxLines: null,
                      minLines: 8,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'No que você está pensando?',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Contador de caracteres
                  if (characterCount > 0)
                    Container(
                      color: cardColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$characterCount caracteres',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Preview de imagem
                  if (_imageBytes != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cardColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SvgPicture.string(
                                  CustomIcons.image,
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    secondaryColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Imagem anexada',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: _removeImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.string(
                                      CustomIcons.delete,
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.red,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Preview de vídeo
                  if (_videoCtrl.text.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cardColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.string(
                                CustomIcons.videoLibrary,
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFFFB020),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vídeo anexado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _removeVideo,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.string(
                                    CustomIcons.delete,
                                    width: 18,
                                    height: 18,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.red,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _videoCtrl.text.trim(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Opções de mídia
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Adicionar à publicação',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showMediaOptions = !_showMediaOptions;
                                });
                              },
                              child: Icon(
                                _showMediaOptions
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (_showMediaOptions) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MediaButton(
                                  icon: CustomIcons.image,
                                  label: 'Galeria',
                                  color: const Color(0xFF45BD62),
                                  onTap: _pickImageGallery,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MediaButton(
                                  icon: CustomIcons.camera,
                                  label: 'Câmera',
                                  color: const Color(0xFF1877F2),
                                  onTap: _pickImageCamera,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MediaButton(
                                  icon: CustomIcons.videoLibrary,
                                  label: 'Vídeo',
                                  color: const Color(0xFFFFB020),
                                  onTap: _showVideoDialog,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _MediaIconButton(
                                icon: CustomIcons.image,
                                color: const Color(0xFF45BD62),
                                onTap: _pickImageGallery,
                              ),
                              _MediaIconButton(
                                icon: CustomIcons.camera,
                                color: const Color(0xFF1877F2),
                                onTap: _pickImageCamera,
                              ),
                              _MediaIconButton(
                                icon: CustomIcons.videoLibrary,
                                color: const Color(0xFFFFB020),
                                onTap: _showVideoDialog,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isPosting || !hasContent ? null : _publish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF3A3B3C)
                            : const Color(0xFFE4E6EB),
                        disabledForegroundColor: isDark
                            ? const Color(0xFF4E4F50)
                            : const Color(0xFFBCC0C4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Publicar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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

// Widget para botões de mídia (versão expandida)
class _MediaButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SvgPicture.string(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para botões de mídia (versão colapsada)
class _MediaIconButton extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _MediaIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.string(
            icon,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}