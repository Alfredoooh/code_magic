// lib/widgets/comments_widget.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/post_model.dart';
import 'custom_icons.dart';

class CommentsWidget extends StatefulWidget {
  final String postId;
  final bool isNews;

  const CommentsWidget({
    super.key,
    required this.postId,
    this.isNews = false,
  });

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final uid = auth.user?.uid;

    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: widget.isNews
              ? _getNewsCommentsStream()
              : _getPostCommentsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Erro ao carregar comentários',
                    style: TextStyle(color: secondaryColor),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SvgPicture.string(
                        CustomIcons.commentOutlined,
                        width: 48,
                        height: 48,
                        colorFilter: ColorFilter.mode(
                          secondaryColor.withOpacity(0.5),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sem comentários ainda',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seja o primeiro a comentar!',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
              ),
              itemBuilder: (context, index) {
                final d = docs[index];
                final comment = Comment.fromFirestore(d);

                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark 
                            ? const Color(0xFF2C2C2E) 
                            : const Color(0xFFF0F0F0),
                        backgroundImage: comment.userAvatar != null
                            ? MemoryImage(base64Decode(comment.userAvatar!))
                            : null,
                        child: comment.userAvatar == null
                            ? Text(
                                comment.userName.isNotEmpty
                                    ? comment.userName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    comment.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(comment.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.content,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 8),

        // Input de comentário
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark 
                      ? const Color(0xFF2C2C2E) 
                      : const Color(0xFFF0F0F0),
                  backgroundImage: auth.userData?['photoBase64'] != null
                      ? MemoryImage(base64Decode(auth.userData!['photoBase64']))
                      : null,
                  child: auth.userData?['photoBase64'] == null
                      ? Text(
                          auth.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2C2C2E) 
                          : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Escreve um comentário...',
                        hintStyle: TextStyle(color: secondaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(color: textColor),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: uid == null 
                        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
                        : const Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: SvgPicture.string(
                      CustomIcons.arrowUp,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        uid == null ? secondaryColor : Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: uid == null ? null : _sendComment,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getPostCommentsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getNewsCommentsStream() {
    return FirebaseFirestore.instance
        .collection('news_comments')
        .where('newsId', isEqualTo: widget.postId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _sendComment() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;

    if (uid == null) return;

    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    try {
      final now = FieldValue.serverTimestamp();

      if (widget.isNews) {
        // Comentário em notícia - salva em coleção separada
        await FirebaseFirestore.instance.collection('news_comments').add({
          'newsId': widget.postId,
          'userId': uid,
          'userName': auth.userData?['name'] ?? 'Usuário',
          'userAvatar': auth.userData?['photoBase64'],
          'content': text,
          'timestamp': now,
          'likes': 0,
          'likedBy': [],
        });
      } else {
        // Comentário em post normal
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add({
          'postId': widget.postId,
          'userId': uid,
          'userName': auth.userData?['name'] ?? 'Usuário',
          'userAvatar': auth.userData?['photoBase64'],
          'content': text,
          'timestamp': now,
          'likes': 0,
          'likedBy': [],
        });

        // Incrementa contador
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({'comments': FieldValue.increment(1)});
      }

      _ctrl.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}