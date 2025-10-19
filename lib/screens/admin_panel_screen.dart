import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
import 'admin_modals.dart';
import 'admin_user_edit.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ImageProvider? _getImageFromBase64(String? imageData) {
    if (imageData == null || imageData.isEmpty) return null;

    try {
      if (imageData.startsWith('data:image')) {
        final base64String = imageData.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } else if (imageData.length > 100) {
        final bytes = base64Decode(imageData);
        return MemoryImage(bytes);
      } else if (imageData.startsWith('http')) {
        return NetworkImage(imageData);
      }
    } catch (e) {
      print('Erro ao decodificar imagem: $e');
    }
    return null;
  }

  void _showAdminMenu() {
    AppBottomSheet.show(
      context,
      height: 320,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const AppSectionTitle(text: 'Menu Admin', fontSize: 18),
          const SizedBox(height: 24),
          _buildMenuOption(
            icon: Icons.analytics_outlined,
            title: 'Estatísticas',
            onTap: () {
              Navigator.pop(context);
              _showStatisticsModal();
            },
          ),
          const Divider(height: 1),
          _buildMenuOption(
            icon: Icons.settings_outlined,
            title: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              _showSettingsModal();
            },
          ),
          const Divider(height: 1),
          _buildMenuOption(
            icon: Icons.assessment_outlined,
            title: 'Relatórios',
            onTap: () {
              Navigator.pop(context);
              _showReportsModal();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatisticsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatisticsModal(),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsModal(),
    );
  }

  void _showReportsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReportsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Painel Admin',
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: AppColors.primary),
            onPressed: _showAdminMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            child: AppTextField(
              controller: _searchController,
              hintText: 'Buscar usuários...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconCircle(
                          icon: Icons.people_outline,
                          size: 40,
                          iconColor: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum usuário encontrado',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final username = (data['username'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final fullName = (data['full_name'] ?? '').toString().toLowerCase();

                  return _searchQuery.isEmpty ||
                      username.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      fullName.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconCircle(
                          icon: Icons.search_off,
                          size: 40,
                          iconColor: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum resultado encontrado',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 72,
                      color: isDark ? AppColors.darkSeparator : AppColors.separator,
                    ),
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final user = UserModel.fromMap({...userData, 'id': users[index].id});
                      return _buildUserTile(user, isDark);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, bool isDark) {
    final imageProvider = _getImageFromBase64(user.profileImage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showUserEditModal(context, user, isDark),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Text(
                            user.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  if (user.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.admin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on_outlined, 
                          size: 14, 
                          color: Colors.grey[600]
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.tokens} tokens',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: user.access ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.access ? 'Ativo' : 'Bloqueado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: user.access ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}