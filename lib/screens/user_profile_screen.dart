// lib/screens/user_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_snackbar.dart';
import 'avatar_gallery_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _schoolController = TextEditingController();
  final _phoneController = TextEditingController();
  final _photoUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _loadUserData(Map<String, dynamic>? userData) {
    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _nicknameController.text = userData['nickname'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _schoolController.text = userData['school'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';
      _photoUrlController.text = userData['photoURL'] ?? '';
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _photoUrlController.text = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          message: 'Erro ao carregar imagem',
          isDark: context.read<ThemeProvider>().isDarkMode,
        );
      }
    }
  }

  Future<void> _openAvatarGallery() async {
    final selectedAvatar = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarGalleryScreen(
          currentAvatarUrl: _photoUrlController.text,
        ),
      ),
    );

    if (selectedAvatar != null) {
      setState(() {
        _photoUrlController.text = selectedAvatar;
      });
      if (mounted) {
        CustomSnackbar.showSuccess(
          context,
          message: 'Avatar selecionado!',
          isDark: context.read<ThemeProvider>().isDarkMode,
        );
      }
    }
  }

  void _showImageSourceBottomSheet(BuildContext context, Color cardColor, Color textColor) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.string(
                    CustomIcons.image,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1877F2),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(
                  'Galeria do App',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Escolher um avatar',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B),
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAvatarGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.string(
                    CustomIcons.folder,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1877F2),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(
                  'Galeria do Dispositivo',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Escolher da galeria',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B),
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final isDark = context.read<ThemeProvider>().isDarkMode;

    try {
      await authProvider.updateProfile(
        displayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        photoURL: _photoUrlController.text.trim().isNotEmpty
            ? _photoUrlController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        school: _schoolController.text.trim().isNotEmpty
            ? _schoolController.text.trim()
            : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() => _isEditing = false);
        CustomSnackbar.showSuccess(
          context,
          message: 'Perfil atualizado com sucesso',
          isDark: isDark,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          message: 'Erro ao atualizar perfil',
          isDark: isDark,
        );
      }
    }
  }

  String _getUserTypeIcon(String? userType) {
    switch (userType) {
      case 'student':
        return CustomIcons.school;
      case 'professional':
        return CustomIcons.briefcase;
      case 'company':
        return CustomIcons.building;
      default:
        return CustomIcons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final userData = authProvider.userData;

    if (!_isEditing && userData != null) {
      _loadUserData(userData);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Meu Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(userData);
                });
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              icon: SvgPicture.string(
                CustomIcons.edit,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1877F2),
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 72,
                      backgroundColor: const Color(0xFF1877F2),
                      backgroundImage: _photoUrlController.text.isNotEmpty
                          ? (_photoUrlController.text.startsWith('data:image')
                              ? MemoryImage(base64Decode(
                                  _photoUrlController.text.split(',')[1]))
                              : NetworkImage(_photoUrlController.text))
                              as ImageProvider
                          : null,
                      child: _photoUrlController.text.isEmpty
                          ? Text(
                              userData?['name']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showImageSourceBottomSheet(context, cardColor, textColor),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1877F2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SvgPicture.string(
                            CustomIcons.camera,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Name and Type
            if (!_isEditing) ...[
              Text(
                userData?['name'] ?? 'Usuário',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              if (userData?['nickname'] != null)
                Text(
                  '@${userData?['nickname']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF1877F2).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      _getUserTypeIcon(userData?['userType']),
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1877F2),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getUserTypeLabel(userData?['userType']),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1877F2),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Info Cards
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      _buildEditField(
                        'Nome',
                        _nameController,
                        CustomIcons.person,
                        textColor,
                        hintColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildEditField(
                        'Bio',
                        _bioController,
                        CustomIcons.info,
                        textColor,
                        hintColor,
                        isDark,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildEditField(
                        'Escola/Instituição',
                        _schoolController,
                        CustomIcons.school,
                        textColor,
                        hintColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildEditField(
                        'Telefone',
                        _phoneController,
                        CustomIcons.phone,
                        textColor,
                        hintColor,
                        isDark,
                      ),
                    ] else ...[
                      _buildInfoTile(
                        CustomIcons.email,
                        'Email',
                        userData?['email'] ?? '-',
                        textColor,
                        hintColor,
                      ),
                      if (userData?['bio'] != null && (userData!['bio'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          CustomIcons.info,
                          'Bio',
                          userData['bio'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                      if (userData?['school'] != null && (userData!['school'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          CustomIcons.school,
                          'Escola/Instituição',
                          userData['school'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                      if (userData?['phoneNumber'] != null && (userData!['phoneNumber'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          CustomIcons.phone,
                          'Telefone',
                          userData['phoneNumber'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                      if (userData?['birthDate'] != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          CustomIcons.calendar,
                          'Data de Nascimento',
                          userData?['birthDate'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Button
            if (_isEditing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF31A24C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Salvar Alterações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getUserTypeLabel(String? userType) {
    switch (userType) {
      case 'student':
        return 'Estudante';
      case 'professional':
        return 'Profissional';
      case 'company':
        return 'Empresa';
      default:
        return 'Pessoa';
    }
  }

  Widget _buildInfoTile(
    String icon,
    String label,
    String value,
    Color textColor,
    Color hintColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.string(
            icon,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1877F2),
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    String icon,
    Color textColor,
    Color hintColor,
    bool isDark, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.string(
              icon,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}