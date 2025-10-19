// lib/screens/profile_screen.dart
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AppSectionTitle(text: 'Escolher Foto', fontSize: 18),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text(
                'Câmera',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(
                'Galeria',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            SizedBox(height: 20),
          ],
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
            Icons.person_rounded,
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
            Icons.person_rounded,
            size: 50,
            color: Colors.white,
          ),
        );
      }
    } else {
      imageWidget = Icon(
        Icons.person_rounded,
        size: 50,
        color: Colors.white,
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
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
                physics: BouncingScrollPhysics(),
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
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBackground : Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
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
                            letterSpacing: -0.2,
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
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.grid_on_rounded, color: AppColors.primary, size: 28),
                                SizedBox(height: 12),
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Publicações',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
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
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 28),
                                SizedBox(height: 12),
                                Text(
                                  '${_userData?['tokens'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tokens',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
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
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
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
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${_usernameController.text.length}/30',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
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
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${_bioController.text.length}/150',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
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
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mail_rounded, color: AppColors.primary, size: 20),
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
                                        fontWeight: FontWeight.w600,
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
                              Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
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
                                        fontWeight: FontWeight.w700,
                                        color: (_userData?['pro'] == true)
                                            ? Color(0xFFFCAF45)
                                            : Colors.grey.shade600,
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
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangePasswordScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Alterar Senha',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Delete Account
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _startAccountDeletion,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppDesignConfig.buttonRadius),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Excluir Conta',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
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