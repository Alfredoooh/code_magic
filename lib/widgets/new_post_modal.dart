// lib/widgets/new_post_modal.dart
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
import '../screens/fullscreen_new_post.dart';
import '../screens/plans_screen.dart'; // Importe sua tela de planos
import 'custom_icons.dart';

class NewPostModal extends StatefulWidget {
  const NewPostModal({super.key});

  @override
  State<NewPostModal> createState() => _NewPostModalState();
}

class _NewPostModalState extends State<NewPostModal> {
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService();

  String? _imageBase64;
  Uint8List? _imageBytes;
  String? _videoUrl;
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final base64 = await ImageService.pickImageAsBase64(source: ImageSource.gallery);
    if (base64 == null) return;

    final bytes = ImageService.base64ToBytes(base64);
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem muito grande. Máximo 5MB.'), backgroundColor: Color(0xFFFA383E)),
        );
      }
      return;
    }

    setState(() {
      _imageBase64 = base64;
      _imageBytes = bytes;
    });
  }

  Future<void> _takePhoto() async {
    final base64 = await ImageService.pickImageAsBase64(source: ImageSource.camera);
    if (base64 == null) return;
    final bytes = ImageService.base64ToBytes(base64);
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem muito grande. Máximo 5MB.'), backgroundColor: Color(0xFFFA383E)),
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

  void _setVideoUrl(String? url) {
    setState(() {
      _videoUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : null;
    });
  }

  Future<void> _showVideoUrlModal() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    final TextEditingController urlController = TextEditingController(text: _videoUrl ?? '');

    final url = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle visual
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB020).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adicionar Vídeo',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Cole o link do vídeo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: urlController,
                        autofocus: true,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://youtube.com/watch?v=...',
                          hintStyle: TextStyle(
                            color: secondaryColor,
                            fontSize: 15,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.string(
                              CustomIcons.link,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                secondaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dica
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Suporta YouTube, Facebook, Vimeo e outros',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark
                                  ? const Color(0xFF3A3B3C)
                                  : const Color(0xFFF0F2F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, urlController.text.trim()),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFFFFB020),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Adicionar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (url != null && mounted) {
      _setVideoUrl(url);
    }
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _imageBase64 == null && (_videoUrl == null || _videoUrl!.isEmpty)) return;

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
        videoUrl: _videoUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicação criada com sucesso'), backgroundColor: Color(0xFF31A24C)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar publicação: $e'), backgroundColor: const Color(0xFFFA383E)),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _openFullscreenEditor() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FullscreenNewPost(
          initialContent: _contentController.text,
          initialImageBase64: _imageBase64,
          initialVideoUrl: _videoUrl,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _contentController.text = result['content'] ?? _contentController.text;
        _imageBase64 = result['imageBase64'] as String?;
        _videoUrl = result['videoUrl'] as String?;
        _imageBytes = _imageBase64 != null ? ImageService.base64ToBytes(_imageBase64!) : null;
      });
    }
  }

  void _navigateToPlans() {
    Navigator.pop(context); // Fecha o modal
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlansScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);
    final authProvider = context.watch<AuthProvider>();
    final isPro = authProvider.userData?['isPro'] ?? false;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90, // Aumentado de 0.85 para 0.90
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                      width: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            CustomIcons.close,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Criar publicação',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: isPro ? _openFullscreenEditor : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            CustomIcons.openInFull,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
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
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            authProvider.userData?['name'] ?? 'Usuário',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: _imageBytes != null ? 3 : 5,
                        autofocus: true,
                        style: TextStyle(fontSize: 16, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'No que você está pensando?',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
                          ),
                          border: InputBorder.none,
                        ),
                        readOnly: !isPro,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2D2E) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFB020).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB020).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SvgPicture.string(
                                  CustomIcons.videoLibrary,
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFFFB020),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _videoUrl!,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _videoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_imageBytes != null) ...[
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.string(
                                    CustomIcons.close,
                                    width: 18,
                                    height: 18,
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
                      ],
                      
                      // Banner de upgrade para usuários gratuitos
                      if (!isPro) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1877F2), Color(0xFF0E5DC1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Desbloqueie Recursos Premium',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Crie posts ilimitados',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '✓ Posts com texto, imagens e vídeos\n✓ Editor em tela cheia\n✓ Sem limites de publicações',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _navigateToPlans,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1877F2),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver Planos',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Adicionar à publicação
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                      width: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Adicionar à publicação',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: isPro ? _pickImage : null,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            CustomIcons.image,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF45BD62),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isPro ? _takePhoto : null,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            CustomIcons.camera,
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF1877F2),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isPro ? _showVideoUrlModal : null,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.string(
                            CustomIcons.videoLibrary,
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFFFB020),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botão publicar
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isPosting ||
                            (_contentController.text.trim().isEmpty &&
                                _imageBase64 == null &&
                                (_videoUrl == null || _videoUrl!.isEmpty)) ||
                            !isPro
                        ? null
                        : _createPost,
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
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Publicar',
                            style: TextStyle(
                              fontSize: 15,
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
    );
  }
}