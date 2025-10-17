import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, color: Color(0xFFFF444F)),
                SizedBox(width: 8),
                Text(
                  'Câmera',
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, color: Color(0xFFFF444F)),
                SizedBox(width: 8),
                Text(
                  'Galeria',
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
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

        // Processar imagem em background
        await Future.delayed(Duration(milliseconds: 100));

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
          _showErrorDialog(
            'Imagem muito grande!\n\n'
            'Tamanho: ${sizeInMB.toStringAsFixed(2)} MB\n'
            'Máximo: 5 MB\n\n'
            'Escolha uma imagem menor.'
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
      _showErrorDialog('Erro ao processar imagem: $e');
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
      _showErrorDialog('Escreva algo para publicar.');
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

      Navigator.pop(context, true); // Retorna true para indicar sucesso
      
      // Mostrar toast de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white),
              SizedBox(width: 8),
              Text('Publicação criada com sucesso!'),
            ],
          ),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Erro ao publicar: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, color: Color(0xFFFF3B30), size: 22),
            SizedBox(width: 8),
            Text('Erro'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: Color(0xFFFF444F))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(bool isDark) {
    return Container(
      color: isDark ? Color(0xFF000000) : CupertinoColors.white,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF444F),
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
          SizedBox(width: 12),
          Text(
            widget.userData['username'] ?? 'Usuário',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
        style: TextStyle(
          fontSize: 18,
          color: CupertinoColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContentInput(bool isDark) {
    return Container(
      color: isDark ? Color(0xFF000000) : CupertinoColors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _titleController,
            placeholder: 'Título (opcional)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            decoration: BoxDecoration(color: Colors.transparent),
            padding: EdgeInsets.zero,
            maxLength: 100,
            placeholderStyle: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          CupertinoTextField(
            controller: _contentController,
            placeholder: 'No que você está pensando?',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            decoration: BoxDecoration(color: Colors.transparent),
            padding: EdgeInsets.zero,
            maxLines: null,
            minLines: 5,
            maxLength: 1000,
            placeholderStyle: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.xmark,
                  color: CupertinoColors.white,
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
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onPressed: _isSubmitting || _isProcessingImage ? null : _pickImage,
        child: Row(
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              color: _isProcessingImage ? CupertinoColors.systemGrey : Color(0xFFFF444F),
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedImage != null ? 'Alterar Imagem' : 'Adicionar Imagem',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_isProcessingImage)
              CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Cancelar', style: TextStyle(color: Color(0xFFFF444F), fontSize: 17)),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        middle: Text(
          'Nova Publicação',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: _isSubmitting
              ? CupertinoActivityIndicator()
              : Text(
                  'Publicar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _contentController.text.trim().isEmpty
                        ? CupertinoColors.systemGrey
                        : Color(0xFFFF444F),
                    fontSize: 17,
                  ),
                ),
          onPressed: _isSubmitting || _contentController.text.trim().isEmpty
              ? null
              : _submitPost,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildUserInfo(isDark),
                Container(height: 0.5, color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA)),
                _buildContentInput(isDark),
                SizedBox(height: 8),
                _buildImagePreview(),
                SizedBox(height: 8),
                _buildAddImageButton(isDark),
                SizedBox(height: 24),
              ],
            ),
            if (_isProcessingImage)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(radius: 16),
                        SizedBox(height: 16),
                        Text(
                          'Processando imagem...',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
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