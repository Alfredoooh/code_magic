import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanel extends StatefulWidget {
  final String language;

  const AdminPanel({required this.language});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Painel Administrativo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuário...',
                prefixIcon: Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar usuários'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFFFF444F)),
            );
          }

          var users = snapshot.data?.docs ?? [];

          if (_searchQuery.isNotEmpty) {
            users = users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final username = (data['username'] ?? '').toLowerCase();
              final email = (data['email'] ?? '').toLowerCase();
              return username.contains(_searchQuery) || email.contains(_searchQuery);
            }).toList();
          }

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum usuário encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              return _buildUserCard(userData, userDoc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId) {
    final isPro = userData['is_pro'] == true;
    final isAdmin = userData['is_admin'] == true;
    final hasAccess = userData['access'] != false;
    final isBlocked = userData['blocked'] == true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: userData['profile_image']?.isNotEmpty == true
              ? NetworkImage(userData['profile_image'])
              : null,
          backgroundColor: Color(0xFFFF444F),
          child: userData['profile_image']?.isEmpty != false
              ? Text(
                  (userData['username'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 20),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userData['username'] ?? 'Usuário',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isPro)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            if (isAdmin)
              Container(
                margin: EdgeInsets.only(left: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF444F),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(userData['email'] ?? ''),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                  size: 14,
                  color: isBlocked ? Colors.red : Colors.green,
                ),
                SizedBox(width: 4),
                Text(
                  isBlocked ? 'Bloqueado' : (hasAccess ? 'Ativo' : 'Sem Acesso'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isBlocked ? Colors.red : (hasAccess ? Colors.green : Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID', userData['id'] ?? userId),
                _buildInfoRow('Email', userData['email'] ?? 'N/A'),
                _buildInfoRow('Nome Completo', userData['full_name'] ?? 'N/A'),
                _buildInfoRow('Telefone', userData['phone']?.isEmpty != false ? 'N/A' : userData['phone']),
                _buildInfoRow('Chave', userData['user_key'] ?? 'N/A'),
                _buildInfoRow('Tokens Usados', '${userData['tokens_used_today'] ?? 0}'),
                _buildInfoRow('Limite Diário', isPro ? 'Ilimitado' : '${userData['max_daily_tokens'] ?? 50}'),
                SizedBox(height: 16),
                Text(
                  'Ações',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionChip(
                      label: isPro ? 'Remover PRO' : 'Tornar PRO',
                      icon: Icons.star_rounded,
                      color: Color(0xFFFFD700),
                      onTap: () => _togglePro(userId, !isPro),
                    ),
                    _buildActionChip(
                      label: isAdmin ? 'Remover Admin' : 'Tornar Admin',
                      icon: Icons.admin_panel_settings_rounded,
                      color: Color(0xFFFF444F),
                      onTap: () => _toggleAdmin(userId, !isAdmin),
                    ),
                    _buildActionChip(
                      label: hasAccess ? 'Remover Acesso' : 'Dar Acesso',
                      icon: hasAccess ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: hasAccess ? Colors.red : Colors.green,
                      onTap: () => _toggleAccess(userId, !hasAccess),
                    ),
                    _buildActionChip(
                      label: isBlocked ? 'Desbloquear' : 'Bloquear',
                      icon: isBlocked ? Icons.check_circle_rounded : Icons.block_rounded,
                      color: isBlocked ? Colors.green : Colors.red,
                      onTap: () => _toggleBlock(userId, !isBlocked),
                    ),
                    _buildActionChip(
                      label: 'Reset Tokens',
                      icon: Icons.refresh_rounded,
                      color: Colors.blue,
                      onTap: () => _resetTokens(userId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePro(String userId, bool isPro) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_pro': isPro,
        'max_daily_tokens': isPro ? 999999 : 50,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPro ? 'Usuário promovido a PRO' : 'PRO removido'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar usuário'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAdmin(String userId, bool isAdmin) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_admin': isAdmin,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin ? 'Usuário promovido a Admin' : 'Admin removido'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar usuário'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAccess(String userId, bool hasAccess) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'access': hasAccess,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasAccess ? 'Acesso concedido' : 'Acesso removido'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar usuário'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleBlock(String userId, bool isBlocked) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'blocked': isBlocked,
        'blocked_until': isBlocked ? DateTime.now().add(Duration(days: 30)).toIso8601String() : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked ? 'Usuário bloqueado' : 'Usuário desbloqueado'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar usuário'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetTokens(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'tokens_used_today': 0,
        'last_token_reset': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tokens resetados com sucesso'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resetar tokens'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}