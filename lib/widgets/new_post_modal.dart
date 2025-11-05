// lib/widgets/new_post_modal.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';

class NewPostModal extends StatefulWidget {
  const NewPostModal({super.key});

  @override
  State<NewPostModal> createState() => _NewPostModalState();
}

class _NewPostModalState extends State<NewPostModal> {
  final _contentController = TextEditingController();
  final _postService = PostService();
  final _imagePicker = ImagePicker();
  
  String? _imageBase64;
  Uint8List? _imageBytes;
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        // Verifica tamanho (max 5MB)
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
          _imageBytes = bytes;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
    });
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _imageBase64 == null) return;

    setState(() => _isPosting = true);

    try {
      final authProvider = context.read<AuthProvider>();

      await _postService.createPost(
        userId: authProvider.user?.uid ?? '',
        userName: authProvider.userData?['name'] ?? 'Usuário',
        userAvatar: authProvider.userData?['photoURL'],
        content: _contentController.text.trim(),
        imageBase64: _imageBase64,
      );

      if (mounted) {
        Navigator.pop(context);
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
            content: Text('Erro ao criar publicação: $e'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          size: 18,
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
                    const SizedBox(width: 32),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
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
                      const SizedBox(height: 16),
                      
                      // Text field
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: _imageBytes != null ? 3 : 6,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
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
                      
                      // Image preview
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
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Add to post section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      onTap: _pickImage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Color(0xFF45BD62),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Post button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isPosting || (_contentController.text.trim().isEmpty && _imageBase64 == null)
                        ? null
                        : _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      disabledForegroundColor: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
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