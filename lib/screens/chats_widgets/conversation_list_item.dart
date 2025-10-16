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

  @override
  Widget build(BuildContext context) {
    final conversationData = conversation.data() as Map<String, dynamic>;
    final participants = List<String>.from(conversationData['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final isOnline = userData['isOnline'] == true;
        final lastMessage = conversationData['lastMessage'] ?? '';
        final unreadCount = conversationData['unreadCount_${currentUser.uid}'] ?? 0;

        return Container(
          color: isDark ? CupertinoColors.black : CupertinoColors.white,
          child: CupertinoListTile(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF444F),
                  ),
                  child: userData['profile_image'] != null &&
                          userData['profile_image'].isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            userData['profile_image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                (userData['username'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            (userData['username'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
            ),
            title: Text(
              userData['username'] ?? 'Usuário',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 15,
              ),
            ),
            trailing: unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    constraints: const BoxConstraints(minWidth: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ChatDetailScreen(
                    recipientId: otherUserId,
                    recipientName: userData['username'] ?? 'Usuário',
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
}