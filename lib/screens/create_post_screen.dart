import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
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
  String? _uploadEmail;
  bool _loadingEmail = true;
  File? _selectedImage;
  String? _imageFileName;

  @override
  void initState() {
    super.initState();
    _loadUploadEmail();
  }

  Future<void> _loadUploadEmail() async {
    try {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/data/EMAILS/emails.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _uploadEmail = data['upload_email'];
            _loadingEmail = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingEmail = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEmail = false);
      }
    }
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
        setState(() {
          _selectedImage = File(image.path);
          _imageFileName = image.name;
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar imagem: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageFileName = null;
    });
  }

  Future<void> _sendImageViaEmail() async {
    if (_uploadEmail == null) {
      _showErrorDialog('Email de upload não disponível. Tente novamente mais tarde.');
      return;
    }

    if (_selectedImage == null) {
      _showErrorDialog('Por favor, selecione uma imagem primeiro.');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, escreva algo para publicar.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Usuário não autenticado.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final postId = FirebaseFirestore.instance.collection('publicacoes').doc().id;

      final subject = Uri.encodeComponent('Nova Publicação - K Paga - $postId');
      final body = Uri.encodeComponent('''
Detalhes da Publicação:

ID da Publicação: $postId
Usuário: ${widget.userData['username']}
User ID: ${user.uid}
Título: ${_titleController.text}
Conteúdo: ${_contentController.text}
Nome do Arquivo: $_imageFileName

---
INSTRUÇÕES:
1. Faça upload da imagem anexada
2. Crie um link público para a imagem
3. Atualize o documento no Firestore:
   - Coleção: publicacoes
   - Documento ID: $postId
   - Campo: image (com o link da imagem)
   - Campo: status (de "pending" para "approved")
''');

      await _createPendingPost(postId);

      final mailtoUrl = 'mailto:$_uploadEmail?subject=$subject&body=$body';

      if (await canLaunch(mailtoUrl)) {
        await launch(mailtoUrl);

        if (mounted) {
          showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CupertinoAlertDialog(
              title: Text('Email Aberto'),
              content: Text('Anexe a imagem selecionada e envie o email. Sua publicação será processada em breve.'),
              actions: [
                CupertinoDialogAction(
                  child: Text('Entendi', style: TextStyle(color: Color(0xFFFF444F))),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        }
      } else {
        _showErrorDialog('Não foi possível abrir o cliente de email.');
      }
    } catch (e) {
      _showErrorDialog('Erro ao processar publicação: $e');
      print('Erro detalhado: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _createPendingPost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final postData = {
      'userId': user.uid,
      'username': widget.userData['username'] ?? 'Usuário',
      'displayName': widget.userData['username'] ?? 'Usuário',
      'userProfileImage': widget.userData['profile_image'] ?? '',
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'image': '',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('publicacoes')
        .doc(postId)
        .set(postData);
  }

  Future<void> _submitPostWithoutImage() async {
    if (_contentController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, escreva algo para publicar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog('Usuário não autenticado.');
        return;
      }

      final postData = {
        'userId': user.uid,
        'username': widget.userData['username'] ?? 'Usuário',
        'displayName': widget.userData['username'] ?? 'Usuário',
        'userProfileImage': widget.userData['profile_image'] ?? '',
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'image': '',
        'status': 'approved',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('publicacoes')
          .add(postData);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Sucesso!'),
            content: Text('Sua publicação foi criada com sucesso.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: TextStyle(color: Color(0xFFFF444F))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Erro ao criar publicação: $e');
      print('Erro detalhado: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: Color(0xFFFF444F))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _handlePublish() {
    if (_isSubmitting) return;

    if (_selectedImage != null) {
      _sendImageViaEmail();
    } else {
      _submitPostWithoutImage();
    }
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
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Color(0xFFFF444F),
              fontSize: 17,
            ),
          ),
          onPressed: () => Navigator.pop(context),
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
              : _handlePublish,
        ),
      ),
      child: SafeArea(
        child: _loadingEmail
            ? Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  // User Info
                  Container(
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
                                  child: Image.network(
                                    widget.userData['profile_image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        (widget.userData['username'] ?? 'U')[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    (widget.userData['username'] ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
                  ),

                  // Divider
                  Container(
                    height: 0.5,
                    color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
                  ),

                  // Content Input
                  Container(
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
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
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
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          padding: EdgeInsets.zero,
                          maxLines: null,
                          minLines: 5,
                          maxLength: 1000,
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // Image Preview
                  if (_selectedImage != null)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  color: CupertinoColors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 8),

                  // Action Button
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onPressed: _pickImage,
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.photo,
                            color: Color(0xFFFF444F),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _selectedImage != null ? 'Alterar Imagem' : 'Adicionar Imagem',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
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