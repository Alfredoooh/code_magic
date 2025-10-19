import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
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
    AppBottomSheet.show(
      context,
      height: 200,
      child: Column(
        children: [
          SizedBox(height: 8),
          AppSectionTitle(text: 'Escolher Foto', fontSize: 18),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.camera_alt, color: AppColors.primary),
            title: Text('Câmera'),
            onTap: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: AppColors.primary),
            title: Text('Galeria'),
            onTap: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
          ),
        ],
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: AppCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Processando imagem...'),
                  ],
                ),
              ),
            ),
          ),
        );

        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);

        String mimeType = 'image/jpeg';
        if (image.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        }

        final dataUrl = 'data:$mimeType;base64,$base64Image';

        Navigator.pop(context);

        final sizeInMB = (dataUrl.length * 0.75) / (1024 * 1024);

        if (sizeInMB > 2) {
          AppDialogs.showError(context, 'Erro', 'Imagem muito grande! Tamanho máximo: 2 MB');
          return;
        }

        setState(() {
          _profileImageBase64 = dataUrl;
        });
      }
    } catch (e) {
      Navigator.pop(context);
      AppDialogs.showError(context, 'Erro', 'Erro ao processar imagem');
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Por favor, insira um nome de usuário');
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
        AppDialogs.showSuccess(
          context,
          'Sucesso!',
          'Perfil atualizado com sucesso',
          onClose: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      AppDialogs.showError(context, 'Erro', 'Erro ao salvar perfil');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _startAccountDeletion() {
    AppDialogs.showConfirmation(
      context,
      'Excluir Conta?',
      'Esta ação é permanente e irreversível.\n\n'
      'Todos os seus dados serão perdidos:\n'
      '• Publicações\n'
      '• Tokens\n'
      '• Configurações\n\n'
      'Deseja continuar?',
      onConfirm: _deleteAccount,
      isDestructive: true,
      confirmText: 'Excluir',
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Excluindo conta...'),
              ],
            ),
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

      AppDialogs.showSuccess(
        context,
        'Conta Excluída',
        'Sua conta foi excluída permanentemente',
        onClose: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      Navigator.pop(context);

      if (e.toString().contains('requires-recent-login')) {
        AppDialogs.showError(context, 'Erro', 'Sua sessão expirou. Faça login novamente.');
      } else {
        AppDialogs.showError(context, 'Erro', 'Erro ao excluir conta');
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
            Icons.person,
            size: 50,
            color: Colors.white,
          );
        }
      } else {
        imageWidget = Image.network(
          _profileImageBase64!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (context, error, stack) => Icon(
            Icons.person,
            size: 50,
            color: Colors.white,
          ),
        );
      }
    } else {
      imageWidget = Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.2),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Editar Perfil',
        actions: [
          if (_saving)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Salvar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
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
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBackground : Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
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
                            color: AppColors.primary,
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
                          child: AppCard(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.grid_on, color: AppColors.primary, size: 28),
                                  SizedBox(height: 12),
                                  Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Publicações',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.monetization_on, color: AppColors.primary, size: 28),
                                  SizedBox(height: 12),
                                  Text(
                                    '${_userData?['tokens'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tokens',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
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

                  SizedBox(height: 24),

                  // Form
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(text: 'NOME'),
                                SizedBox(height: 8),
                                AppTextField(
                                  controller: _usernameController,
                                  hintText: 'Nome de usuário',
                                  maxLength: 30,
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkSeparator : AppColors.separator,
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFieldLabel(text: 'BIOGRAFIA'),
                                SizedBox(height: 8),
                                AppTextField(
                                  controller: _bioController,
                                  hintText: 'Escreva algo sobre você',
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
                    child: AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.mail, color: AppColors.primary, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(text: 'EMAIL'),
                                      SizedBox(height: 4),
                                      Text(
                                        _userData?['email'] ?? 'Não informado',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: isDark ? AppColors.darkSeparator : AppColors.separator,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.star, color: AppColors.primary, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(text: 'STATUS'),
                                      SizedBox(height: 4),
                                      Text(
                                        (_userData?['pro'] == true) ? 'PRO' : 'FREEMIUM',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: (_userData?['pro'] == true)
                                              ? Color(0xFFFCAF45)
                                              : Colors.grey,
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
                  ),

                  SizedBox(height: 24),

                  // Change Password
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangePasswordScreen(),
                          ),
                        );
                      },
                      child: AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Alterar Senha',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Delete Account
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: AppSecondaryButton(
                      text: 'Excluir Conta',
                      onPressed: _startAccountDeletion,
                      textColor: Colors.red,
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