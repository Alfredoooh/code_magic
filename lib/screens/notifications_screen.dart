// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    // Configura timeago para português
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: cardColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                SvgIcon(
                  svgString: CustomIcons.bell,
                  color: iconColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notificações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                height: 0.5,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('recipientId', isEqualTo: currentUserId)
                .orderBy('createdAt', descending: true)
                .limit(50)
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
                          'Erro ao carregar notificações',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
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

              final notifications = snapshot.data?.docs ?? [];

              if (notifications.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sem notificações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Você receberá notificações sobre novas\npublicações, curtidas e comentários',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
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
                    final notificationDoc = notifications[index];
                    final data = notificationDoc.data() as Map<String, dynamic>;
                    
                    final type = data['type'] as String;
                    final senderName = data['senderName'] ?? 'Alguém';
                    final senderPhotoURL = data['senderPhotoURL'];
                    final isRead = data['isRead'] ?? false;
                    final createdAt = data['createdAt'] as Timestamp?;

                    String notificationText = '';
                    IconData notificationIcon = Icons.notifications;
                    Color notificationColor = const Color(0xFF1877F2);

                    switch (type) {
                      case 'new_post':
                        notificationText = 'publicou algo novo';
                        notificationIcon = Icons.article;
                        notificationColor = const Color(0xFF1877F2);
                        break;
                      case 'like':
                        notificationText = 'curtiu sua publicação';
                        notificationIcon = Icons.favorite;
                        notificationColor = const Color(0xFFED4956);
                        break;
                      case 'comment':
                        notificationText = 'comentou sua publicação';
                        notificationIcon = Icons.comment;
                        notificationColor = const Color(0xFF31A24C);
                        break;
                      case 'follow':
                        notificationText = 'começou a seguir você';
                        notificationIcon = Icons.person_add;
                        notificationColor = const Color(0xFF1877F2);
                        break;
                      default:
                        notificationText = 'interagiu com você';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 1),
                      color: isRead ? cardColor : (isDark ? const Color(0xFF2D3236) : const Color(0xFFE7F3FF)),
                      child: ListTile(
                        onTap: () async {
                          // Marca como lida
                          if (!isRead) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(notificationDoc.id)
                                .update({'isRead': true});
                          }
                          // TODO: Navegar para o conteúdo relevante
                        },
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF1877F2),
                              backgroundImage: senderPhotoURL != null
                                  ? NetworkImage(senderPhotoURL)
                                  : null,
                              child: senderPhotoURL == null
                                  ? Text(
                                      senderName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: notificationColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cardColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  notificationIcon,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                            ),
                            children: [
                              TextSpan(
                                text: senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' $notificationText',
                              ),
                            ],
                          ),
                        ),
                        subtitle: createdAt != null
                            ? Text(
                                timeago.format(
                                  createdAt.toDate(),
                                  locale: 'pt_BR',
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                ),
                              )
                            : null,
                        trailing: !isRead
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1877F2),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                  childCount: notifications.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}