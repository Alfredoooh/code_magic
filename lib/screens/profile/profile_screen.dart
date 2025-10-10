import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:madeeasy/models/user_model.dart';
import 'package:madeeasy/services/email_service.dart';
import 'package:madeeasy/services/auth_service.dart';
import 'package:madeeasy/widgets/design_system.dart';
import 'package:madeeasy/localization/app_localizations.dart';

import 'package:madeeasy/screens/themes_screen.dart';
import 'package:madeeasy/screens/languages_screen.dart';
import 'package:madeeasy/screens/integrations_screen.dart';
import 'package:madeeasy/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUpdatingBio = false;
  UserModel? _userModel;
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Usuário não autenticado, redirecionar para login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userModel = UserModel.fromJson(doc.data()!);
            _bioController.text = _userModel!.bio;
          });
        }
      } else {
        // Documento não existe, criar um básico
        final userData = {
          'email': user.email,
          'full_name': user.displayName ?? 'Usuário',
          'bio': '',
          'points': 0,
          'followed_users': [],
          'profile_image': null,
          'created_at': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
        
        if (mounted) {
          _loadUserData(); // Recarregar dados
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_loading_profile') ?? 
              'Erro ao carregar perfil'
            ),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateBio() async {
    if (_bioController.text.trim() == _userModel?.bio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('no_changes') ?? 
            'Nenhuma alteração feita'
          ),
          backgroundColor: info,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUpdatingBio = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'bio': _bioController.text.trim(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('bio_updated') ?? 
                'Bio atualizada com sucesso!'
              ),
              backgroundColor: success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_updating_bio') ?? 
              'Erro ao atualizar bio'
            ),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingBio = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    setState(() => _isUploadingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Upload para Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(File(pickedFile.path));

      // Mostrar progresso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
      });

      await uploadTask;
      final url = await storageRef.getDownloadURL();

      // Atualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profile_image': url,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('image_updated') ?? 
              'Imagem atualizada com sucesso!'
            ),
            backgroundColor: success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'unauthorized':
            errorMessage = 'Sem permissão para fazer upload';
            break;
          case 'canceled':
            errorMessage = 'Upload cancelado';
            break;
          case 'unknown':
            errorMessage = 'Erro desconhecido ao fazer upload';
            break;
          default:
            errorMessage = 'Erro ao fazer upload: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_uploading_image') ?? 
              'Erro ao fazer upload da imagem'
            ),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _exportAndSendData() async {
    setState(() => _isLoading = true);

    try {
      if (_userModel == null) {
        throw Exception('Dados do usuário não carregados');
      }

      // Remove dados sensíveis antes de enviar
      final exportData = _userModel!.toJson();
      exportData.remove('password'); // Garantir que não tem senha
      exportData.remove('two_factor_code');
      exportData.remove('otp');

      await EmailService().sendUserData(exportData, 'alfredopjonas@gmail.com');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('data_sent') ?? 
              'Dados enviados com sucesso!'
            ),
            backgroundColor: success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_sending_data') ?? 
              'Erro ao enviar dados'
            ),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: secondaryBg,
        title: Text(
          AppLocalizations.of(context)!.translate('confirm_logout') ?? 
          'Confirmar Logout'
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('logout_message') ?? 
          'Tem certeza que deseja sair?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.translate('cancel') ?? 'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.translate('logout') ?? 'Sair',
              style: TextStyle(color: danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      await AuthService().signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_logout') ?? 
              'Erro ao fazer logout'
            ),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userModel == null) {
      return Center(child: CustomProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _uploadProfileImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: accentPrimary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: secondaryBg,
                      backgroundImage: _userModel!.profileImage != null 
                          ? NetworkImage(_userModel!.profileImage!) 
                          : null,
                      child: _isUploadingImage
                          ? CircularProgressIndicator(color: accentPrimary)
                          : (_userModel!.profileImage == null 
                              ? const Icon(Icons.person_rounded, size: 60, color: accentPrimary) 
                              : null),
                    ),
                  ),
                  if (!_isUploadingImage)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _userModel!.fullName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('bio') ?? 'Bio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _bioController,
                    label: AppLocalizations.of(context)!.translate('bio') ?? 'Bio',
                    icon: Icons.edit_rounded,
                    maxLines: 3,
                    enabled: !_isUpdatingBio,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: _isUpdatingBio 
                        ? '' 
                        : (AppLocalizations.of(context)!.translate('update_bio') ?? 'Atualizar Bio'),
                    isLoading: _isUpdatingBio,
                    onPressed: _isUpdatingBio ? null : _updateBio,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.translate('statistics') ?? 'Estatísticas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.star_rounded, color: warning, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '${_userModel!.points}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.translate('points') ?? 'Pontos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.group_rounded, color: accentPrimary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '${_userModel!.followedUsers.length}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.translate('followers') ?? 'Seguidores',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.translate('settings') ?? 'Configurações',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                CustomListTile(
                  leadingIcon: Icons.palette_rounded,
                  title: AppLocalizations.of(context)!.translate('themes') ?? 'Temas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ThemesScreen()),
                    );
                  },
                ),
                CustomDivider(),
                CustomListTile(
                  leadingIcon: Icons.language_rounded,
                  title: AppLocalizations.of(context)!.translate('languages') ?? 'Idiomas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LanguagesScreen()),
                    );
                  },
                ),
                CustomDivider(),
                CustomListTile(
                  leadingIcon: Icons.link_rounded,
                  title: AppLocalizations.of(context)!.translate('integrations') ?? 'Integrações',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IntegrationsScreen()),
                    );
                  },
                ),
                CustomDivider(),
                CustomListTile(
                  leadingIcon: Icons.security_rounded,
                  title: AppLocalizations.of(context)!.translate('security') ?? 'Segurança',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.translate('coming_soon') ?? 
                          'Em breve!'
                        ),
                        backgroundColor: info,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: _isLoading 
                ? '' 
                : (AppLocalizations.of(context)!.translate('export_data') ?? 'Exportar Dados'),
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _exportAndSendData,
            color: info,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('logout') ?? 'Sair',
            color: danger,
            onPressed: _confirmLogout,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}