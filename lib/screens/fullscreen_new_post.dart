// lib/screens/fullscreen_new_post.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../services/image_service.dart';

/// Fullscreen editor — abre como fullscreen dialog. Retorna um Map com os dados se o utilizador fizer "Salvar e Fechar"/
class FullscreenNewPost extends StatefulWidget {
  final String? initialContent;
  final String? initialImageBase64;
  final String? initialVideoUrl;

  const FullscreenNewPost({super.key, this.initialContent, this.initialImageBase64, this.initialVideoUrl});

  @override
  State<FullscreenNewPost> createState() => _FullscreenNewPostState();
}

class _FullscreenNewPostState extends State<FullscreenNewPost> {
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _videoCtrl = TextEditingController();
  final PostService _postService = PostService();

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
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageGallery() async {
    final base64 = await ImageService.pickImageAsBase64(source: ImageSource.gallery);
    if (base64 == null) return;
    setState(() {
      _imageBase64 = base64;
      _imageBytes = ImageService.base64ToBytes(base64);
    });
  }

  Future<void> _pickImageCamera() async {
    final base64 = await ImageService.pickImageAsBase64(source: ImageSource.camera);
    if (base64 == null) return;
    setState(() {
      _imageBase64 = base64;
      _imageBytes = ImageService.base64ToBytes(base64);
    });
  }

  void _removeImage() {
    setState(() {
      _imageBase64 = null;
      _imageBytes = null;
    });
  }

  Future<void> _publish() async {
    final content = _contentCtrl.text.trim();
    final videoUrl = _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim();

    if (content.isEmpty && _imageBase64 == null && (videoUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione conteúdo, imagem ou vídeo antes de publicar'), backgroundColor: Color(0xFFFA383E)));
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e'), backgroundColor: const Color(0xFFFA383E)));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _saveAndReturn() {
    // retorna dados para modal anterior sem publicar
    Navigator.pop(context, {
      'content': _contentCtrl.text,
      'imageBase64': _imageBase64,
      'videoUrl': _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar publicação (tela cheia)'),
        actions: [
          TextButton(onPressed: _saveAndReturn, child: Text('Salvar', style: TextStyle(color: textColor))),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: _contentCtrl,
                    minLines: 6,
                    maxLines: null,
                    decoration: InputDecoration(hintText: 'Escreve o teu post...', border: InputBorder.none),
                    style: TextStyle(fontSize: 16, color: textColor, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    ElevatedButton.icon(onPressed: _pickImageGallery, icon: const Icon(Icons.photo_library), label: const Text('Galeria')),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: _pickImageCamera, icon: const Icon(Icons.camera_alt), label: const Text('Câmera')),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = await showDialog<String?>(
                          context: context,
                          builder: (ctx) {
                            final ctrl = TextEditingController(text: _videoCtrl.text);
                            return AlertDialog(
                              title: const Text('Inserir URL de vídeo'),
                              content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'URL do vídeo (YouTube, Facebook, etc)')),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK'))],
                            );
                          },
                        );
                        if (url != null) setState(() => _videoCtrl.text = url);
                      },
                      icon: const Icon(Icons.video_call),
                      label: const Text('Vídeo'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (_imageBytes != null)
                    Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
                      Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _removeImage)),
                    ]),
                  const SizedBox(height: 12),
                  Text('Preview do vídeo', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 8),
                  if (_videoCtrl.text.trim().isNotEmpty)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isDark ? const Color(0xFF2C2D2E) : const Color(0xFFF3F4F6)),
                      child: Padding(padding: const EdgeInsets.all(8), child: Text(_videoCtrl.text.trim(), style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)))),
                    )
                  else
                    Text('Sem vídeo', style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _publish,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1877F2)),
                  child: _isPosting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Publicar'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
            ]),
          ]),
        ),
      ),
    );
  }
}