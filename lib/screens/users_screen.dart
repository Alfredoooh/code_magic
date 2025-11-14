// lib/screens/users_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Agora';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    
    return '${dateTime.day}/${dateTime.month}';
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

    // Se não está logado
    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 64, color: hintColor),
              const SizedBox(height: 16),
              Text(
                'Faça login para ver suas conversas',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          // Erro
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifique sua conexão',
                      style: TextStyle(fontSize: 14, color: hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
              ),
            );
          }

          // Pegar os chats
          final chats = snapshot.data?.docs ?? [];

          // Ordenar por lastMessageTime
          final sortedChats = List<QueryDocumentSnapshot>.from(chats);
          sortedChats.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = aData?['lastMessageTime'] as Timestamp?;
            final bTime = bData?['lastMessageTime'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Vazio
          if (sortedChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: hintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa ainda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use a pesquisa para encontrar pessoas',
                    style: TextStyle(fontSize: 14, color: hintColor),
                  ),
                ],
              ),
            );
          }

          // Lista
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedChats.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            ),
            itemBuilder: (context, index) {
              final chatDoc = sortedChats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>?;
              
              if (chatData == null) return const SizedBox.shrink();

              final participants = List<String>.from(chatData['participants'] ?? []);
              final recipientId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (recipientId.isEmpty) return const SizedBox.shrink();

              final lastMessage = chatData['lastMessage'] ?? '';
              final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
              final unreadCount = chatData['unreadCount_$currentUserId'] as int? ?? 0;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(recipientId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  // Loading do usuário
                  if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                    return Container(
                      color: cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final isOnline = userData['isOnline'] == true;
                  final lastActive = userData['lastActive'] as Timestamp?;
                  final photoBase64 = userData['photoBase64'];
                  final photoURL = userData['photoURL'];
                  final userName = userData['name'] ?? 'Usuário';

                  return Container(
                    color: cardColor,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              recipientId: recipientId,
                              recipientName: userName,
                              recipientPhotoURL: photoURL,
                              isOnline: isOnline,
                              lastActive: lastActive,
                            ),
                          ),
                        );
                      },
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1877F2),
                            backgroundImage: photoBase64 != null
                                ? MemoryImage(base64Decode(photoBase64))
                                : (photoURL != null
                                    ? NetworkImage(photoURL)
                                    : null),
                            child: photoBase64 == null && photoURL == null
                                ? Text(
                                    userName.isNotEmpty 
                                        ? userName.substring(0, 1).toUpperCase()
                                        : 'U',
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
                                  border: Border.all(color: cardColor, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage.isEmpty ? 'Toque para conversar' : lastMessage,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                color: unreadCount > 0 ? textColor : hintColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(lastMessageTime.toDate()),
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0
                                    ? const Color(0xFF1877F2)
                                    : hintColor,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}