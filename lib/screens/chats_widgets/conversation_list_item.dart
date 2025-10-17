import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat_detail_screen.dart';

class ConversationListItem extends StatelessWidget {
  final QueryDocumentSnapshot conversation;
  final User currentUser;
  final bool isDark;

  const ConversationListItem({
    Key? key,
    required this.conversation,
    required this.currentUser,
    required this.isDark,
  }) : super(key: key);

  String _getOtherUserId(Map<String, dynamic> conversationData) {
    // Tentar obter participants como lista
    final participants = conversationData['participants'];
    
    if (participants is List) {
      final participantsList = List<String>.from(participants);
      return participantsList.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => '',
      );
    }
    
    // Fallback: verificar se existe userId direto
    if (conversationData.containsKey('userId') && 
        conversationData['userId'] != currentUser.uid) {
      return conversationData['userId'];
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final conversationData = conversation.data() as Map<String, dynamic>?;
    
    // Validação robusta dos dados
    if (conversationData == null) {
      print('⚠️ conversationData é null para: ${conversation.id}');
      return const SizedBox.shrink();
    }

    print('📋 Dados da conversa: $conversationData');

    final otherUserId = _getOtherUserId(conversationData);

    if (otherUserId.isEmpty) {
      print('⚠️ Nenhum outro usuário encontrado na conversa: ${conversation.id}');
      return const SizedBox.shrink();
    }

    print('✅ Carregando conversa com usuário: $otherUserId');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .snapshots(),
      builder: (context, userSnapshot) {
        // Validação do snapshot
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingTile(isDark);
        }

        if (userSnapshot.hasError) {
          print('❌ Erro ao carregar usuário $otherUserId: ${userSnapshot.error}');
          return const SizedBox.shrink();
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          print('⚠️ Snapshot sem dados para usuário: $otherUserId');
          return const SizedBox.shrink();
        }

        final userDoc = userSnapshot.data!;
        if (!userDoc.exists) {
          print('⚠️ Usuário não existe: $otherUserId');
          return const SizedBox.shrink();
        }

        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) {
          print('⚠️ userData é null para: $otherUserId');
          return const SizedBox.shrink();
        }

        print('✅ Dados do usuário carregados: ${userData['username']}');

        final isOnline = userData['isOnline'] == true;
        final lastMessage = conversationData['lastMessage'] ?? 'Sem mensagens';
        final lastMessageTime = conversationData['lastMessageTime'] as Timestamp?;
        
        // Calcular unread count com fallback
        int unreadCount = 0;
        try {
          unreadCount = conversationData['unreadCount_${currentUser.uid}'] ?? 0;
          if (unreadCount is! int) {
            unreadCount = int.tryParse(unreadCount.toString()) ?? 0;
          }
        } catch (e) {
          print('⚠️ Erro ao processar unreadCount: $e');
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? CupertinoColors.black : CupertinoColors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark 
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6,
                width: 0.5,
              ),
            ),
          ),
          child: CupertinoListTile(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: _buildAvatar(userData, isOnline, isDark),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    userData['username'] ?? userData['email'] ?? 'Usuário',
                    style: TextStyle(
                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 17,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                ),
                if (lastMessageTime != null)
                  Text(
                    _formatTime(lastMessageTime),
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 
                          ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                          : CupertinoColors.systemGrey,
                      fontSize: 15,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () async {
              // Marcar mensagens como lidas ao abrir
              try {
                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(conversation.id)
                    .update({
                  'unreadCount_${currentUser.uid}': 0,
                });
              } catch (e) {
                print('⚠️ Erro ao marcar como lido: $e');
              }

              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ChatDetailScreen(
                    recipientId: otherUserId,
                    recipientName: userData['username'] ?? userData['email'] ?? 'Usuário',
                    recipientImage: userData['profile_image'] ?? '',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> userData, bool isOnline, bool isDark) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF444F),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF444F).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildAvatarContent(userData),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: CupertinoColors.activeGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent(Map<String, dynamic> userData) {
    final profileImage = userData['profile_image'];
    final username = userData['username'] ?? userData['email'] ?? 'U';
    
    if (profileImage != null && profileImage.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileImage,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CupertinoActivityIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('⚠️ Erro ao carregar imagem: $error');
            return _buildInitialAvatar(username);
          },
        ),
      );
    }
    
    return _buildInitialAvatar(username);
  }

  Widget _buildInitialAvatar(String username) {
    return Center(
      child: Text(
        username[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 22,
          color: CupertinoColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingTile(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.black : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}