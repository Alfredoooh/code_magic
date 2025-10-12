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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha uma opção'),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, color: Color(0xFFFF444F)),
                SizedBox(width: 8),
                Text('Câmera'),
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
                Text('Galeria'),
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
INSTRUÇÕES IMPORTANTES:
1. Faça upload da imagem anexada para seu servidor de hospedagem
2. Crie um link público para a imagem
3. Atualize o documento no Firestore:
   - Coleção: publicacoes
   - Documento ID: $postId
   - Campo a atualizar: image (com o link da imagem)
   - Campo a atualizar: status (de "pending" para "approved")

A imagem está pronta para ser anexada neste email.
''');

    final mailtoUrl = 'mailto:$_uploadEmail?subject=$subject&body=$body';

    try {
      await _createPendingPost(postId);

      if (await canLaunch(mailtoUrl)) {
        await launch(mailtoUrl);
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text('Email Aberto'),
              content: Text('Por favor, anexe a imagem selecionada e envie o email. Sua publicação será processada em breve.\n\nIMPORTANTE: Anexe a imagem ao email antes de enviar.'),
              actions: [
                CupertinoDialogAction(
                  child: Text('Entendi'),
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
      _showErrorDialog('Erro ao abrir email: $e');
    }
  }

  Future<void> _createPendingPost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('publicacoes').doc(postId).set({
      'id': postId,
      'userId': user.uid,
      'userName': widget.userData['username'],
      'userProfileImage': widget.userData['profile_image'] ?? '',
      'title': _titleController.text,
      'content': _contentController.text,
      'image': '',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'likedBy': [],
    });
  }

  Future<void> _submitPostWithoutImage() async {
    if (_contentController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, escreva algo para publicar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('publicacoes').add({
        'userId': user.uid,
        'userName': widget.userData['username'],
        'userProfileImage': widget.userData['profile_image'] ?? '',
        'title': _titleController.text,
        'content': _contentController.text,
        'image': '',
        'status': 'approved',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Sucesso!'),
            content: Text('Sua publicação foi criada com sucesso.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showPublishOptions() {
    if (_selectedImage != null) {
      _sendImageViaEmail();
    } else {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text('Como deseja publicar?'),
          message: Text('Escolha se deseja adicionar uma imagem ou publicar apenas texto.'),
          actions: [
            CupertinoActionSheetAction(
              child: Text('Adicionar Imagem e Publicar'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            CupertinoActionSheetAction(
              child: Text('Publicar sem Imagem'),
              onPressed: () {
                Navigator.pop(context);
                _submitPostWithoutImage();
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        middle: Text('Nova Publicação'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: _isSubmitting
              ? CupertinoActivityIndicator()
              : Text(
                  'Publicar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF444F),
                  ),
                ),
          onPressed: _isSubmitting ? null : _showPublishOptions,
        ),
        border: null,
      ),
      child: SafeArea(
        child: _loadingEmail
            ? Center(child: CupertinoActivityIndicator(radius: 16))
            : ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFFF444F),
                        backgroundImage: widget.userData['profile_image'] != null &&
                                widget.userData['profile_image'].isNotEmpty
                            ? NetworkImage(widget.userData['profile_image'])
                            : null,
                        child: widget.userData['profile_image'] == null ||
                                widget.userData['profile_image'].isEmpty
                            ? Text(
                                (widget.userData['username'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userData['username'] ?? 'Usuário',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF444F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.star_fill,
                                  color: CupertinoColors.white,
                                  size: 10,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _titleController,
                          placeholder: 'Título (opcional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          maxLength: 100,
                        ),
                        SizedBox(height: 16),
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
                          maxLines: 10,
                          maxLength: 1000,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: _selectedImage != null ? 300 : 150,
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedImage != null 
                              ? Color(0xFFFF444F).withOpacity(0.5)
                              : (isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey5),
                          width: 2,
                        ),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _selectedImage!,
                                    width: double.infinity,
                                    height: double.infinity,
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
                                        color: Colors.black.withOpacity(0.6),
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
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFF444F),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark_circle_fill,
                                          color: CupertinoColors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Imagem Selecionada',
                                          style: TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.photo_on_rectangle,
                                  size: 48,
                                  color: Color(0xFFFF444F),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Toque para adicionar imagem',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Câmera ou Galeria',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFFF444F).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle_fill,
                              color: Color(0xFFFF444F),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _selectedImage != null ? 'Publicar com Imagem' : 'Como Funciona',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_selectedImage != null)
                          Text(
                            'Ao publicar, um email será aberto automaticamente. Anexe a imagem selecionada e envie o email. Sua publicação será processada em breve.',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                              height: 1.5,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• Adicione uma imagem tocando no botão acima',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                '• Ou publique apenas texto clicando em "Publicar"',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                '• Publicações com imagem são enviadas via email',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF444F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFFF444F).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.star_fill,
                          color: Color(0xFFFF444F),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recursos PRO desbloqueados: Publicações ilimitadas, imagens, prioridade na moderação',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                        ),
                      ],
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