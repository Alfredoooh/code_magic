import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CreatePostScreen({
    required this.userData,
    Key? key,
  }) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isProcessingImage = false;
  File? _selectedImage;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  Future<void> _pickImage() async {
    AppBottomSheet.show(
      context,
      height: 200,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const AppSectionTitle(text: 'Adicionar Imagem', fontSize: 18),
          const SizedBox(height: 20),
          _buildImageOption(
            icon: Icons.camera_alt_outlined,
            title: 'Câmera',
            onTap: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
          ),
          const Divider(height: 1),
          _buildImageOption(
            icon: Icons.photo_library_outlined,
            title: 'Galeria',
            onTap: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isProcessingImage = true);

        await Future.delayed(const Duration(milliseconds: 100));

        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);

        String mimeType = 'image/jpeg';
        if (image.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (image.path.toLowerCase().endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (image.path.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        final dataUrl = 'data:$mimeType;base64,$base64Image';
        final sizeInMB = (dataUrl.length * 0.75) / (1024 * 1024);

        setState(() => _isProcessingImage = false);

        if (sizeInMB > 5) {
          AppDialogs.showError(
            context,
            'Imagem muito grande!',
            'Tamanho: ${sizeInMB.toStringAsFixed(2)} MB\nMáximo: 5 MB\n\nEscolha uma imagem menor.',
          );
          return;
        }

        setState(() {
          _selectedImage = File(image.path);
          _imageBase64 = dataUrl;
        });
      }
    } catch (e) {
      setState(() => _isProcessingImage = false);
      AppDialogs.showError(context, 'Erro', 'Erro ao processar imagem: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      AppDialogs.showError(context, 'Atenção', 'Escreva algo para publicar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final postData = {
        'userId': user.uid,
        'username': widget.userData['username'] ?? 'Usuário',
        'displayName': widget.userData['username'] ?? 'Usuário',
        'userProfileImage': widget.userData['profile_image'] ?? '',
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'image': _imageBase64 ?? '',
        'status': 'approved',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('publicacoes').add(postData);

      if (!mounted) return;

      AppDialogs.showSuccess(
        context,
        'Sucesso',
        'Publicação criada com sucesso!',
        onClose: () => Navigator.pop(context, true),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      AppDialogs.showError(context, 'Erro', 'Erro ao publicar: $e');
    }
  }

  Widget _buildUserInfo(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 0,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: widget.userData['profile_image'] != null &&
                    widget.userData['profile_image'].isNotEmpty
                ? ClipOval(
                    child: widget.userData['profile_image'].startsWith('data:image')
                        ? Image.memory(
                            base64Decode(widget.userData['profile_image'].split(',')[1]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitial(),
                          )
                        : Image.network(
                            widget.userData['profile_image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitial(),
                          ),
                  )
                : _buildInitial(),
          ),
          const SizedBox(width: 12),
          Text(
            widget.userData['username'] ?? 'Usuário',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        (widget.userData['username'] ?? 'U')[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContentInput(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 0,
      child: Column(
        children: [
          AppTextField(
            controller: _titleController,
            hintText: 'Título (opcional)',
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _contentController,
            hintText: 'No que você está pensando?',
            maxLines: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_contentController.text.length}/1000',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedImage!,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
    );
  }

  Widget _buildAddImageButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting || _isProcessingImage ? null : _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isProcessingImage ? Icons.hourglass_empty : Icons.image_outlined,
                    color: _isProcessingImage ? Colors.grey : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedImage != null ? 'Alterar Imagem' : 'Adicionar Imagem',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isProcessingImage)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Nova Publicação',
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _contentController.text.trim().isEmpty ? null : _submitPost,
              child: Text(
                'Publicar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _contentController.text.trim().isEmpty
                      ? Colors.grey
                      : AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildUserInfo(isDark),
                Container(
                  height: 0.5,
                  color: isDark ? AppColors.darkSeparator : AppColors.separator,
                ),
                const SizedBox(height: 8),
                _buildContentInput(isDark),
                const SizedBox(height: 8),
                _buildImagePreview(),
                const SizedBox(height: 8),
                _buildAddImageButton(isDark),
                const SizedBox(height: 24),
              ],
            ),
            if (_isProcessingImage)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Processando imagem...',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
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

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}