import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _saving = false;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _usernameController.text = _userData?['username'] ?? '';
          _bioController.text = _userData?['bio'] ?? '';
          _profileImageBase64 = _userData?['profile_image'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
                SizedBox(width: 12),
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
                SizedBox(width: 12),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // Mostrar loading
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(color: CupertinoColors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processando imagem...',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ],
              ),
            ),
          ),
        );

        // Converter para Base64
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Determinar tipo MIME
        String mimeType = 'image/jpeg';
        if (image.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        }

        final dataUrl = 'data:$mimeType;base64,$base64Image';

        // Fechar loading
        Navigator.pop(context);

        // Verificar tamanho (máx 2MB)
        final sizeInMB = (dataUrl.length * 0.75) / (1024 * 1024);
        
        if (sizeInMB > 2) {
          _showErrorDialog('Imagem muito grande! Tamanho máximo: 2 MB');
          return;
        }

        setState(() {
          _profileImageBase64 = dataUrl;
        });
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Erro ao processar imagem');
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, insira um nome de usuário');
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profile_image': _profileImageBase64 ?? '',
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.systemGreen,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text('Sucesso!'),
              ],
            ),
            content: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Perfil atualizado com sucesso'),
            ),
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
      _showErrorDialog('Erro ao salvar perfil');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Erro'),
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

  void _startAccountDeletion() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.destructiveRed,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Excluir Conta?'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Esta ação é permanente e irreversível.\n\n'
            'Todos os seus dados serão perdidos:\n'
            '• Publicações\n'
            '• Tokens\n'
            '• Configurações\n\n'
            'Deseja continuar?',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Excluir'),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CupertinoColors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(color: CupertinoColors.white),
              SizedBox(height: 16),
              Text(
                'Excluindo conta...',
                style: TextStyle(color: CupertinoColors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      await user.delete();

      Navigator.pop(context);

      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Conta Excluída'),
          content: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Sua conta foi excluída permanentemente'),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: TextStyle(color: Color(0xFFFF444F))),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      
      if (e.toString().contains('requires-recent-login')) {
        _showErrorDialog('Sua sessão expirou. Faça login novamente.');
      } else {
        _showErrorDialog('Erro ao excluir conta');
      }
    }
  }

  Widget _buildProfileImage({required bool isDark}) {
    Widget imageWidget;

    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      if (_profileImageBase64!.startsWith('data:image')) {
        try {
          final base64String = _profileImageBase64!.split(',')[1];
          final bytes = base64Decode(base64String);
          imageWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          );
        } catch (e) {
          imageWidget = Icon(
            CupertinoIcons.person_fill,
            size: 50,
            color: CupertinoColors.white,
          );
        }
      } else {
        imageWidget = Image.network(
          _profileImageBase64!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (context, error, stack) => Icon(
            CupertinoIcons.person_fill,
            size: 50,
            color: CupertinoColors.white,
          ),
        );
      }
    } else {
      imageWidget = Icon(
        CupertinoIcons.person_fill,
        size: 50,
        color: CupertinoColors.white,
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFF444F).withOpacity(0.2),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageWidget,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: Color(0xFFFF444F),
                size: 24,
              ),
              SizedBox(width: 4),
              Text(
                'Voltar',
                style: TextStyle(
                  color: Color(0xFFFF444F),
                  fontSize: 17,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: _saving
            ? CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Salvar',
                  style: TextStyle(
                    color: Color(0xFFFF444F),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _saveProfile,
              ),
      ),
      child: SafeArea(
        child: _loading
            ? Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: EdgeInsets.symmetric(vertical: 24),
                children: [
                  // Profile Image
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              _buildProfileImage(isDark: isDark),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF444F),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? Color(0xFF000000) : CupertinoColors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.camera_fill,
                                    size: 16,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Alterar foto',
                          style: TextStyle(
                            color: Color(0xFFFF444F),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Stats
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.square_grid_2x2_fill,
                                  color: Color(0xFFFF444F),
                                  size: 28,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Publicações',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.money_dollar_circle_fill,
                                  color: Color(0xFFFF444F),
                                  size: 28,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '${_userData?['tokens'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tokens',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Form
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOME',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemGrey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                CupertinoTextField(
                                  controller: _usernameController,
                                  placeholder: 'Nome de usuário',
                                  style: TextStyle(
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                    fontSize: 17,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(12),
                                  maxLength: 30,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 0.5,
                            color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BIOGRAFIA',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemGrey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                CupertinoTextField(
                                  controller: _bioController,
                                  placeholder: 'Escreva algo sobre você',
                                  style: TextStyle(
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                    fontSize: 17,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(12),
                                  maxLines: 3,
                                  maxLength: 150,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Account Info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.mail_solid,
                                color: Color(0xFFFF444F),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EMAIL',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _userData?['email'] ?? 'Não informado',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 0.5,
                            color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.star_fill,
                                color: Color(0xFFFF444F),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STATUS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      (_userData?['pro'] == true) ? 'PRO' : 'FREEMIUM',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: (_userData?['pro'] == true)
                                            ? Color(0xFFFCAF45)
                                            : CupertinoColors.systemGrey,
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
                  ),

                  SizedBox(height: 24),

                  // Change Password
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => ChangePasswordScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.lock_shield_fill,
                              color: Color(0xFFFF444F),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Alterar Senha',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: CupertinoColors.systemGrey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Delete Account
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _startAccountDeletion,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Excluir Conta',
                            style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}