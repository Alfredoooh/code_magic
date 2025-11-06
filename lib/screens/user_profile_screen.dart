// lib/screens/user_profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditing = false;
  bool _isChangingPassword = false;

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _schoolController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _coverPhotoUrlController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    _coverPhotoUrlController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData(Map<String, dynamic>? userData) {
    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _nicknameController.text = userData['nickname'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _schoolController.text = userData['school'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _cityController.text = userData['city'] ?? '';
      _stateController.text = userData['state'] ?? '';
      _countryController.text = userData['country'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';
      _photoUrlController.text = userData['photoURL'] ?? '';
      _coverPhotoUrlController.text = userData['coverPhotoURL'] ?? '';
    }
  }

  Future<void> _pickImage(bool isCoverPhoto) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        if (isCoverPhoto) {
          _coverPhotoUrlController.text = base64Image;
        } else {
          _photoUrlController.text = base64Image;
        }

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar imagem: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfile(
        displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        photoURL: _photoUrlController.text.trim().isNotEmpty ? _photoUrlController.text.trim() : null,
        coverPhotoURL: _coverPhotoUrlController.text.trim().isNotEmpty ? _coverPhotoUrlController.text.trim() : null,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        school: _schoolController.text.trim().isNotEmpty ? _schoolController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso'),
            backgroundColor: Color(0xFF31A24C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      // TODO: Implementar mudança de senha com reautenticação

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade de mudança de senha em desenvolvimento'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
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

    String getUserTypeLabel(String? userType) {
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

    IconData getUserTypeIcon(String? userType) {
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Minha conta',
          style: TextStyle(
            fontSize: 20,
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
                ),
              ),
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Cover Photo
          if (!_isEditing)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: _coverPhotoUrlController.text.isNotEmpty
                    ? DecorationImage(
                        image: _coverPhotoUrlController.text.startsWith('data:image')
                            ? MemoryImage(base64Decode(_coverPhotoUrlController.text.split(',')[1]))
                            : NetworkImage(_coverPhotoUrlController.text) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto de capa',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hintColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: _coverPhotoUrlController.text.isNotEmpty
                          ? DecorationImage(
                              image: _coverPhotoUrlController.text.startsWith('data:image')
                                  ? MemoryImage(base64Decode(_coverPhotoUrlController.text.split(',')[1]))
                                  : NetworkImage(_coverPhotoUrlController.text) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.add_a_photo, color: Color(0xFF1877F2), size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _coverPhotoUrlController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ou cole URL da imagem',
                      hintStyle: TextStyle(color: hintColor, fontSize: 13),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Avatar
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF1877F2),
                  backgroundImage: _photoUrlController.text.isNotEmpty
                      ? (_photoUrlController.text.startsWith('data:image')
                          ? MemoryImage(base64Decode(_photoUrlController.text.split(',')[1]))
                          : NetworkImage(_photoUrlController.text)) as ImageProvider
                      : null,
                  child: _photoUrlController.text.isEmpty
                      ? Text(
                          userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_isEditing) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _photoUrlController,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ou cole URL da foto de perfil',
                  hintStyle: TextStyle(color: hintColor, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // User Info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEditing) ...[
                  _buildInfoRow('Nome', userData?['name'] ?? '-', textColor, hintColor),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nome de usuário', userData?['nickname'] ?? '-', textColor, hintColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        getUserTypeIcon(userData?['userType']),
                        size: 16,
                        color: hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getUserTypeLabel(userData?['userType']),
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Email', userData?['email'] ?? '-', textColor, hintColor),
                  if (userData?['phoneNumber'] != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Telefone', userData?['phoneNumber'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['birthDate'] != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Data de nascimento', userData?['birthDate'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['bio'] != null && (userData?['bio'].toString().isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Bio', userData?['bio'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['school'] != null && (userData?['school'].toString().isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Escola/Instituição', userData?['school'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['address'] != null && (userData?['address'].toString().isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Endereço', userData?['address'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['city'] != null && (userData?['city'].toString().isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Cidade', userData?['city'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['state'] != null && (userData?['state'].toString().isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Estado', userData?['state'] ?? '-', textColor, hintColor),
                  ],
                  if (userData?['country'] != null && (userData?['country'].toString().isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('País', userData?['country'] ?? '-', textColor, hintColor),
                  ],
                ] else ...[
                  _buildEditField('Nome', _nameController, textColor, hintColor, isDark),
                  const SizedBox(height: 16),
                  _buildEditField('Bio', _bioController, textColor, hintColor, isDark, maxLines: 3),
                  const SizedBox(height: 16),
                  _buildEditField('Escola/Instituição', _schoolController, textColor, hintColor, isDark),
                  const SizedBox(height: 16),
                  _buildEditField('Telefone', _phoneController, textColor, hintColor, isDark),
                  const SizedBox(height: 16),
                  _buildEditField('Endereço', _addressController, textColor, hintColor, isDark),
                  const SizedBox(height: 16),
                  _buildEditField('Cidade', _cityController, textColor, hintColor, isDark),
                  const SizedBox(height: 16),
                  _buildEditField('Estado', _stateController, textColor, hintColor, isDark),
                  const SizedBox(height: 16),
                  _buildEditField('País', _countryController, textColor, hintColor, isDark),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          if (!_isEditing && !_isChangingPassword)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Editar perfil',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isChangingPassword = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1877F2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1877F2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Alterar senha',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_isEditing)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF31A24C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Salvar alterações',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else if (_isChangingPassword) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alterar senha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField('Senha atual', _currentPasswordController, textColor, hintColor, isDark),
                  const SizedBox(height: 12),
                  _buildPasswordField('Nova senha', _newPasswordController, textColor, hintColor, isDark),
                  const SizedBox(height: 12),
                  _buildPasswordField('Confirmar nova senha', _confirmPasswordController, textColor, hintColor, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isChangingPassword = false;
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hintColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: hintColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Alterar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    Color textColor,
    Color hintColor,
    bool isDark, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hintColor,
          ),
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
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    Color textColor,
    Color hintColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hintColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}