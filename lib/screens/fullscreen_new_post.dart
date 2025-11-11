// lib/screens/fullscreen_new_post.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class _FullscreenNewPostState extends State<FullscreenNewPost> {
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _videoCtrl = TextEditingController();
  final PostService _postService = PostService();
  final FocusNode _contentFocus = FocusNode();

  String? _imageBase64;
  Uint8List? _imageBytes;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl.text = widget.initialContent ?? '';
    _imageBase64 = widget.initialImageBase64;
    _imageBytes = _imageBase64 != null ? ImageService.base64ToBytes(_imageBase64!) : null;
    _videoCtrl.text = widget.initialVideoUrl ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _videoCtrl.dispose();
    _contentFocus.dispose();
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
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
    final ctrl = TextEditingController(text: _videoCtrl.text);

    final url = await showDialog<String?>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB020).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgIcon(
                      svgString: CustomIcons.videoLibrary,
                      color: const Color(0xFFFFB020),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adicionar vídeo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
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
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Cole a URL do vídeo\n(YouTube, Facebook, Vimeo, etc)',
                  hintStyle: TextStyle(color: secondaryColor),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() => _videoCtrl.text = url);
    }
  }

  Future<void> _publish() async {
    final content = _contentCtrl.text.trim();
    final videoUrl = _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim();

    if (content.isEmpty && _imageBase64 == null && videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione conteúdo, imagem ou vídeo'),
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
      debugPrint('❌ Erro ao publicar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao publicar'),
            backgroundColor: Color(0xFFFA383E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
    final characterCount = _contentCtrl.text.length;
    final hasContent = _contentCtrl.text.trim().isNotEmpty || 
                       _imageBase64 != null || 
                       _videoCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgIcon(
            svgString: CustomIcons.close,
            color: textColor,
            size: 24,
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
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Header do usuário
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF007AFF),
                  backgroundImage: authProvider.userData?['photoURL'] != null
                      ? NetworkImage(authProvider.userData!['photoURL'])
                      : null,
                  child: authProvider.userData?['photoURL'] == null
                      ? Text(
                          authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public,
                              size: 14,
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
                ),
              ],
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Campo de texto
                  Container(
                    color: cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _contentCtrl,
                      focusNode: _contentFocus,
                      maxLines: null,
                      minLines: 6,
                      style: TextStyle(
                        fontSize: 17,
                        color: textColor,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'No que você está pensando?',
                        hintStyle: TextStyle(
                          fontSize: 17,
                          color: secondaryColor,
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$characterCount ${characterCount == 1 ? "caractere" : "caracteres"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Preview de imagem
                  if (_imageBytes != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Preview de vídeo
                  if (_videoCtrl.text.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB020).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgIcon(
                                  svgString: CustomIcons.videoLibrary,
                                  color: const Color(0xFFFFB020),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Vídeo anexado',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _removeVideo,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
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

                  const SizedBox(height: 16),

                  // Botões de mídia sempre visíveis
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adicionar à publicação',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
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
                                color: const Color(0xFF007AFF),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
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
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isPosting || !hasContent ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFE5E5EA),
                  disabledForegroundColor: secondaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
        ),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            SvgIcon(
              svgString: icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}