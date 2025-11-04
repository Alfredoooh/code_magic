// lib/screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Usuários Online',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isOnline', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar usuários',
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                ),
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

          final onlineUsers = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: cardColor,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF31A24C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ),
              Expanded(
                child: onlineUsers.isEmpty
                    ? Center(
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
                              'Nenhum usuário online',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: onlineUsers.length,
                        itemBuilder: (context, index) {
                          final userData = onlineUsers[index].data() as Map<String, dynamic>;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 1),
                            color: cardColor,
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF1877F2),
                                    child: Text(
                                      userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF31A24C),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                userData['name'] ?? 'Usuário',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Text(
                                'Online agora',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}