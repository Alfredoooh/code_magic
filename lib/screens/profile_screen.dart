import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'change_password_screen.dart'; // IMPORT ADICIONADO

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
  File? _selectedImage;

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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Foto de Perfil'),
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
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showImageUploadDialog();
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar imagem: $e');
    }
  }

  void _showImageUploadDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Upload de Foto'),
        content: Text(
          'Para alterar sua foto de perfil, envie a imagem para o suporte. Em breve implementaremos upload direto.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedImage = null);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, insira um nome de usuário.');
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Sucesso!'),
            content: Text('Perfil atualizado com sucesso.'),
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
      _showErrorDialog('Erro ao salvar perfil: $e');
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
          child: Icon(
            CupertinoIcons.back,
            color: Color(0xFFFF444F),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
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
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: 32),
                  // Profile Image
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF444F),
                              border: Border.all(
                                color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
                                width: 4,
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (_userData?['profile_image'] != null &&
                                        (_userData!['profile_image'] as String).isNotEmpty)
                                    ? ClipOval(
                                        child: Image.network(
                                          _userData!['profile_image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Center(
                                            child: Text(
                                              (_userData?['username'] ?? 'U')[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 48,
                                                color: CupertinoColors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (_userData?['username'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 48,
                                            color: CupertinoColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
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
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
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
                          child: _buildStatCard(
                            title: 'Publicações',
                            value: '0',
                            icon: CupertinoIcons.doc_text_fill,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tokens',
                            value: '${_userData?['tokens'] ?? 0}',
                            icon: CupertinoIcons.money_dollar_circle_fill,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Form Fields
                  _buildSectionHeader('Informações Básicas', isDark),
                  _buildInputCard(
                    icon: CupertinoIcons.person_fill,
                    title: 'Nome de Usuário',
                    controller: _usernameController,
                    placeholder: 'Digite seu nome',
                    maxLength: 30,
                    isDark: isDark,
                  ),

                  SizedBox(height: 12),

                  _buildInputCard(
                    icon: CupertinoIcons.text_quote,
                    title: 'Bio',
                    controller: _bioController,
                    placeholder: 'Conte algo sobre você',
                    maxLength: 150,
                    maxLines: 3,
                    isDark: isDark,
                  ),

                  SizedBox(height: 24),

                  _buildSectionHeader('Conta', isDark),
                  _buildInfoCard(
                    icon: CupertinoIcons.mail_solid,
                    title: 'Email',
                    value: _userData?['email'] ?? 'Não informado',
                    isDark: isDark,
                  ),

                  SizedBox(height: 12),

                  _buildInfoCard(
                    icon: CupertinoIcons.star_fill,
                    title: 'Status',
                    value: (_userData?['pro'] == true) ? 'PRO' : 'FREEMIUM',
                    valueColor: Color(0xFFFF444F),
                    isDark: isDark,
                  ),

                  SizedBox(height: 24),

                  // NOVA SEÇÃO: Segurança
                  _buildSectionHeader('Segurança', isDark),
                  
                  // BOTÃO PARA ALTERAR SENHA
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(0xFFFF444F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.lock_shield_fill,
                                color: Color(0xFFFF444F),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alterar Senha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark 
                                        ? CupertinoColors.white 
                                        : CupertinoColors.black,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Mantenha sua conta segura',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
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

                  SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionHeader('Zona de Perigo', isDark),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: Text('Excluir Conta'),
                            content: Text(
                              'Esta ação é irreversível. Todos os seus dados serão permanentemente excluídos.',
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
                                  // Implementar exclusão de conta
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.destructiveRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.destructiveRed.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.trash_fill,
                              color: CupertinoColors.destructiveRed,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Excluir Conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: CupertinoColors.destructiveRed,
                              size: 20,
                            ),
                          ],
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Color(0xFFFF444F),
            size: 28,
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String placeholder,
    required int maxLength,
    int maxLines = 1,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFFF444F), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              maxLength: maxLength,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFFFF444F), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? (isDark ? CupertinoColors.white : CupertinoColors.black),
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
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}