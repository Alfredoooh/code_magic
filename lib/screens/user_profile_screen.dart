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
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Meu Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
              icon: const Icon(Icons.edit, color: Color(0xFF1877F2)),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
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
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 64,
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
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1877F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'gallery_app') {
                              _openAvatarGallery();
                            } else if (value == 'gallery_device') {
                              _pickImageFromGallery();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'gallery_app',
                              child: Row(
                                children: [
                                  Icon(Icons.photo_library,
                                      size: 20, color: textColor),
                                  const SizedBox(width: 12),
                                  Text('Galeria do App',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'gallery_device',
                              child: Row(
                                children: [
                                  Icon(Icons.photo, size: 20, color: textColor),
                                  const SizedBox(width: 12),
                                  Text('Galeria do Dispositivo',
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name and Type
            if (!_isEditing) ...[
              Text(
                userData?['name'] ?? 'Usuário',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              if (userData?['nickname'] != null)
                Text(
                  '@${userData?['nickname']}',
                  style: TextStyle(
                    fontSize: 15,
                    color: hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getUserTypeIcon(userData?['userType']),
                      size: 16,
                      color: const Color(0xFF1877F2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getUserTypeLabel(userData?['userType']),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1877F2),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info Cards
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 6,
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
                        Icons.person,
                        textColor,
                        hintColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildEditField(
                        'Bio',
                        _bioController,
                        Icons.info,
                        textColor,
                        hintColor,
                        isDark,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildEditField(
                        'Escola/Instituição',
                        _schoolController,
                        Icons.school,
                        textColor,
                        hintColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildEditField(
                        'Telefone',
                        _phoneController,
                        Icons.phone,
                        textColor,
                        hintColor,
                        isDark,
                      ),
                    ] else ...[
                      _buildInfoTile(
                        Icons.email,
                        'Email',
                        userData?['email'] ?? '-',
                        textColor,
                        hintColor,
                      ),
                      // ✅ CORREÇÃO: Verificação de bio com bool explícito
                      if (userData?['bio'] != null &&
                          (userData!['bio'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          Icons.info,
                          'Bio',
                          userData['bio'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                      // ✅ CORREÇÃO: Verificação de school com bool explícito
                      if (userData?['school'] != null &&
                          (userData!['school'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          Icons.school,
                          'Escola/Instituição',
                          userData['school'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                      // ✅ CORREÇÃO: Verificação de phoneNumber com bool explícito
                      if (userData?['phoneNumber'] != null &&
                          (userData!['phoneNumber'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          Icons.phone,
                          'Telefone',
                          userData['phoneNumber'] ?? '-',
                          textColor,
                          hintColor,
                        ),
                      ],
                      if (userData?['birthDate'] != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          Icons.cake,
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

            const SizedBox(height: 24),
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

  IconData _getUserTypeIcon(String? userType) {
    switch (userType) {
      case 'student':
        return Icons.school;
      case 'professional':
        return Icons.work;
      case 'company':
        return Icons.business;
      default:
        return Icons.person;
    }
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color hintColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1877F2),
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
    IconData icon,
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
            Icon(icon, size: 16, color: hintColor),
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
            fillColor: isDark
                ? const Color(0xFF3A3B3C)
                : const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}