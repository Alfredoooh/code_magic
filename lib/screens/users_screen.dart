// lib/screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: cardColor,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: hintColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pesquisar usuários...',
                        style: TextStyle(
                          fontSize: 15,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
              height: 0.5,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('isOnline', descending: true)
                .orderBy('lastActive', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar usuários',
                          style: TextStyle(
                            fontSize: 16,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  ),
                );
              }

              final allUsers = snapshot.data?.docs ?? [];
              final users = allUsers.where((doc) => doc.id != currentUserId).toList();
              
              final onlineUsers = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isOnline'] == true;
              }).toList();

              final offlineUsers = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isOnline'] != true;
              }).toList();

              if (users.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum usuário encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Header online
                    if (index == 0) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 1),
                        color: cardColor,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF31A24C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${onlineUsers.length} ${onlineUsers.length == 1 ? "usuário online" : "usuários online"}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Lista de usuários online
                    if (index <= onlineUsers.length) {
                      final userDoc = onlineUsers[index - 1];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      return _buildUserTile(context, userDoc.id, userData, true, cardColor, textColor, isDark);
                    }

                    // Header offline
                    if (index == onlineUsers.length + 1) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 8, bottom: 1),
                        color: cardColor,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: hintColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Lista de usuários offline
                    final offlineIndex = index - onlineUsers.length - 2;
                    final userDoc = offlineUsers[offlineIndex];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    return _buildUserTile(context, userDoc.id, userData, false, cardColor, textColor, isDark);
                  },
                  childCount: users.length + 2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
    bool isOnline,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final lastActive = userData['lastActive'] as Timestamp?;
    final userType = userData['userType'] ?? 'person';
    
    String userTypeLabel = '';
    IconData? userTypeIcon;
    
    switch (userType) {
      case 'student':
        userTypeLabel = 'Estudante';
        userTypeIcon = Icons.school;
        break;
      case 'professional':
        userTypeLabel = 'Profissional';
        userTypeIcon = Icons.work;
        break;
      case 'company':
        userTypeLabel = 'Empresa';
        userTypeIcon = Icons.business;
        break;
      default:
        userTypeLabel = 'Pessoa';
        userTypeIcon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: cardColor,
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                recipientId: userId,
                recipientName: userData['name'] ?? 'Usuário',
                recipientPhotoURL: userData['photoURL'],
                isOnline: isOnline,
              ),
            ),
          );
        },
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1877F2),
              backgroundImage: userData['photoURL'] != null
                  ? NetworkImage(userData['photoURL'])
                  : null,
              child: userData['photoURL'] == null
                  ? Text(
                      userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF31A24C),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cardColor,
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                userData['name'] ?? 'Usuário',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              userTypeIcon,
              size: 14,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userTypeLabel,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isOnline ? 'Online agora' : _getLastActiveText(lastActive),
              style: TextStyle(
                fontSize: 13,
                color: isOnline
                    ? const Color(0xFF31A24C)
                    : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Conversar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1877F2),
            ),
          ),
        ),
      ),
    );
  }

  String _getLastActiveText(Timestamp? lastActive) {
    if (lastActive == null) return 'Offline';

    final now = DateTime.now();
    final activeTime = lastActive.toDate();
    final difference = now.difference(activeTime);

    if (difference.inMinutes < 1) {
      return 'Ativo agora';
    } else if (difference.inMinutes < 60) {
      return 'Ativo há ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Ativo há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Ativo há ${difference.inDays}d';
    } else {
      return 'Offline';
    }
  }
}