// lib/widgets/post_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../widgets/expandable_link_text.dart';
import '../services/image_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_detail_screen.dart';
import '../screens/video_detail_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    final cardColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF262626);
    final postService = PostService();

    final isLiked = auth.user != null ? post.isLikedBy(auth.user!.uid) : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFDBDBDB),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Instagram Style
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                    UserDetailScreen(userId: post.userId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar com gradiente Instagram
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
                        backgroundImage: post.userAvatar != null
                            ? MemoryImage(base64Decode(post.userAvatar!))
                            : null,
                        child: post.userAvatar == null
                            ? Text(
                                post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        if (post.isNews)
                          Text(
                            _formatTimestamp(post.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF737373),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (auth.user?.uid == post.userId)
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: textColor,
                        size: 24,
                      ),
                      onPressed: () => _showOptionsDialog(context, postService),
                    ),
                ],
              ),
            ),
          ),

          // Vídeo - Apenas Thumbnail
          if (post.videoUrl != null)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VideoDetailScreen(
                      videoUrl: post.videoUrl!,
                      post: post,
                    ),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 400,
                    color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
                    child: const Icon(
                      Icons.play_circle_outline,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'Tocar vídeo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          // Imagem
          else if (post.imageBase64 != null)
            GestureDetector(
              onTap: () => postService.openImageViewer(
                context,
                [post.imageBase64!],
                post.imageBase64!,
              ),
              child: Image.memory(
                base64Decode(post.imageBase64!),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),
            )
          else if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
            GestureDetector(
              onTap: () => postService.openImageViewer(
                context,
                post.imageUrls!,
                post.imageUrls!.first,
              ),
              child: ImageService.buildImageFromUrl(
                post.imageUrls!.first,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // Actions Bar - Instagram Style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: post.isNews || auth.user == null
                      ? null
                      : () => postService.toggleLike(post.id, auth.user!.uid),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 28,
                    color: isLiked ? Colors.red : textColor,
                  ),
                ),
                const SizedBox(width: 18),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          postId: post.id,
                          isNews: post.isNews,
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 26,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 18),
                InkWell(
                  onTap: post.isNews ? null : () => postService.sharePost(post),
                  child: Icon(
                    Icons.send_outlined,
                    size: 26,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.bookmark_border,
                  size: 26,
                  color: textColor,
                ),
              ],
            ),
          ),

          // Likes Count
          if (post.likes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${post.likes} ${post.likes == 1 ? "curtida" : "curtidas"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ),

          // Content
          if (post.isNews ? (post.title?.isNotEmpty == true || post.summary?.isNotEmpty == true) : post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isNews && post.title?.isNotEmpty == true)
                    Text(
                      post.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (post.isNews && post.summary?.isNotEmpty == true || !post.isNews && post.content.isNotEmpty)
                    RichText(
                      text: TextSpan(
                        children: [
                          if (!post.isNews)
                            TextSpan(
                              text: '${post.userName} ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          TextSpan(
                            text: post.isNews ? post.summary : post.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

          // Comments Preview
          if (post.comments > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(
                        postId: post.id,
                        isNews: post.isNews,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Ver todos os ${post.comments} comentários',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF737373),
                  ),
                ),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              _formatTimestamp(post.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF737373),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, PostService postService) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDBDBDB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text(
                  'Editar publicação',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditDialog(context, postService);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Excluir publicação',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context, postService);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PostService postService) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Excluir publicação?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF262626),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir esta publicação? Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF737373),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF262626),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              postService.deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Publicação excluída'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Excluir',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, PostService postService) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final controller = TextEditingController(text: post.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Editar publicação',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF262626),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF262626),
          ),
          decoration: InputDecoration(
            hintText: 'O que você está pensando?',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF737373) : const Color(0xFFA8A8A8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDBDBDB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDBDBDB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF262626),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                postService.updatePost(post.id, controller.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Publicação atualizada'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}