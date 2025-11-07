// lib/widgets/new_post_modal.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../services/image_service.dart';
import '../screens/fullscreen_new_post.dart';

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
    // Limite 5MB (ajusta se quiseres)
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

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _imageBase64 == null && (_videoUrl == null || _videoUrl!.isEmpty)) return;

    setState(() => _isPosting = true);

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid ?? '';
      final name = auth.userData?['name'] ?? 'Usuário';
      final avatar = auth.userData?['photoURL'];

      // createPost: espera que o teu PostService implemente este método.
      // Se não tiveres, altera para escrever diretamente no Firestore.
      await _postService.createPost(
        userId: uid,
        userName: name,
        userAvatar: avatar,
        content: content,
        imageBase64: _imageBase64,
        videoUrl: _videoUrl,
      );

      if (mounted) {
        Navigator.pop(context); // fechar modal
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
    // envia o estado atual para o fullscreen editor e aguarda o resultado
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

    // resultado esperado: {'content': string, 'imageBase64': string?, 'videoUrl': string?}
    if (result != null && mounted) {
      setState(() {
        _contentController.text = result['content'] ?? _contentController.text;
        _imageBase64 = result['imageBase64'] as String?;
        _videoUrl = result['videoUrl'] as String?;
        _imageBytes = _imageBase64 != null ? ImageService.base64ToBytes(_imageBase64!) : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final authProvider = context.watch<AuthProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.15), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (fechar + titulo + expand)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA), width: 0.3))),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5), shape: BoxShape.circle),
                        child: Icon(Icons.close, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B), size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('Criar publicação',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
                    const Spacer(),
                    // Expand (abrir fullscreen)
                    GestureDetector(
                      onTap: _openFullscreenEditor,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5), shape: BoxShape.circle),
                        child: Icon(Icons.open_in_full, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B), size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // User info
                    Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF1877F2),
                        backgroundImage: authProvider.userData?['photoURL'] != null ? NetworkImage(authProvider.userData!['photoURL']) : null,
                        child: authProvider.userData?['photoURL'] == null
                            ? Text(authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(authProvider.userData?['name'] ?? 'Usuário', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    ]),
                    const SizedBox(height: 12),

                    // Text field
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: _imageBytes != null ? 3 : 5,
                      autofocus: true,
                      style: TextStyle(fontSize: 16, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'No que você está pensando?',
                        hintStyle: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4)),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    // Video URL preview (se existir)
                    if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2D2E) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                        child: Text(_videoUrl!, style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                      ),
                    ],

                    // Image preview
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 12),
                      Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_imageBytes!, width: double.infinity, fit: BoxFit.cover)),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                          ),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),

              // Add to post section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA), width: 0.3))),
                child: Row(children: [
                  Text('Adicionar à publicação', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                  const Spacer(),
                  // photo
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                    },
                    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5), shape: BoxShape.circle), child: const Icon(Icons.image, color: Color(0xFF45BD62), size: 20)),
                  ),
                  const SizedBox(width: 8),
                  // camera
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Color(0xFF1877F2), size: 18)),
                  ),
                  const SizedBox(width: 8),
                  // video url open small dialog
                  GestureDetector(
                    onTap: () async {
                      final url = await showDialog<String?>(
                        context: context,
                        builder: (ctx) {
                          final TextEditingController ctrl = TextEditingController(text: _videoUrl ?? '');
                          return AlertDialog(
                            title: const Text('Adicionar URL de vídeo'),
                            content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Cole a URL do vídeo (YouTube, Facebook, etc)')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
                            ],
                          );
                        },
                      );
                      if (url != null) _setVideoUrl(url);
                    },
                    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5), shape: BoxShape.circle), child: const Icon(Icons.video_library_outlined, color: Color(0xFFFFB020), size: 18)),
                  ),
                ]),
              ),

              // Post button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isPosting || (_contentController.text.trim().isEmpty && _imageBase64 == null && (_videoUrl == null || _videoUrl!.isEmpty))
                        ? null
                        : _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      disabledForegroundColor: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isPosting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Publicar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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