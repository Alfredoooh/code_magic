// lib/widgets/post_feed.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PostFeed extends StatelessWidget {
  const PostFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return Container(
      color: bgColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar publicações',
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma publicação ainda',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return PostCard(
                authorName: data['authorName'] ?? 'Usuário',
                content: data['content'] ?? '',
                timestamp: data['timestamp'] as Timestamp?,
                category: data['category'] ?? 'geral',
                imageUrl: data['imageUrl'],
              );
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String authorName;
  final String content;
  final Timestamp? timestamp;
  final String category;
  final String? imageUrl;

  const PostCard({
    super.key,
    required this.authorName,
    required this.content,
    this.timestamp,
    required this.category,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1877F2),
                  child: Text(
                    authorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            authorName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (category == 'marketplace') ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 12,
                              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Marketplace',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                ),
              ],
            ),
          ),
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                  child: const Center(child: Icon(Icons.error_outline)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 18,
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Curtir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Comentar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Partilhar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Agora';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}