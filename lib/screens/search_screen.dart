// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: 'Pesquisar usuários...',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 16,
            ),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: hintColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearching = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
              _isSearching = value.trim().isNotEmpty;
            });
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: _isSearching
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
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
                          'Erro ao pesquisar',
                          style: TextStyle(
                            fontSize: 16,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  );
                }

                final allUsers = snapshot.data?.docs ?? [];
                final filteredUsers = allUsers.where((doc) {
                  if (doc.id == currentUserId) return false;
                  
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toLowerCase();
                  final nickname = (data['nickname'] ?? '').toLowerCase();
                  final email = (data['email'] ?? '').toLowerCase();
                  
                  return name.contains(_searchQuery) ||
                         nickname.contains(_searchQuery) ||
                         email.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
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
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) => Container(
                    height: 1,
                    color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                  ),
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final isOnline = userData['isOnline'] == true;
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
                      color: cardColor,
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                recipientId: userDoc.id,
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
                              color: hintColor,
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
                                color: hintColor,
                              ),
                            ),
                            if (userData['nickname'] != null)
                              Text(
                                '@${userData['nickname']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hintColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Digite para pesquisar usuários',
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
}