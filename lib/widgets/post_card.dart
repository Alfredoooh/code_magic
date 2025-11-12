// lib/widgets/post_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_detail_screen.dart';
import '../screens/video_detail_screen.dart';
import '../screens/news_detail_screen.dart';
import '../widgets/custom_icons.dart';

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

  void _openNewsDetail(BuildContext context) {
    if (post.isNews) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewsDetailScreen(post: post),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();

    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final dividerColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    final postService = PostService();
    final isLiked = auth.user != null ? post.isLikedBy(auth.user!.uid) : false;

    return GestureDetector(
      onTap: post.isNews ? () => _openNewsDetail(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        color: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark, textColor, secondaryColor, postService),

            // Content text (somente para posts normais, não para notícias)
            if (post.content.isNotEmpty && !post.isNews)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Summary para notícias (preview)
            if (post.summary != null && post.summary!.isNotEmpty && post.isNews)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  post.summary!,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Media content
            _buildMediaContent(context, isDark, textColor, secondaryColor, postService),

            // Stats
            if (post.likes > 0 || post.comments > 0 || post.shares > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (post.likes > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.thumb_up,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likes}',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    ],
                    const Spacer(),
                    if (post.comments > 0)
                      Text(
                        '${post.comments} comentários',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    if (post.shares > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${post.shares} compartilhamentos',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    ],
                  ],
                ),
              ),

            // Divider
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: dividerColor,
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  _buildActionButton(
                    context,
                    icon: CustomIcons.thumbUpOutlined,
                    activeIcon: CustomIcons.thumbUp,
                    label: 'Curtir',
                    isActive: isLiked,
                    disabled: post.isNews,
                    onTap: () => postService.toggleLike(post.id, auth.user!.uid),
                  ),
                  _buildActionButton(
                    context,
                    icon: CustomIcons.commentOutlined,
                    label: 'Comentar',
                    onTap: () {
                      if (post.isNews) {
                        _openNewsDetail(context);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: post.id,
                              isNews: false,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: CustomIcons.shareOutlined,
                    label: 'Compartilhar',
                    disabled: post.isNews,
                    onTap: () => postService.sharePost(post),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor, Color secondaryColor, PostService postService) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: post.isNews
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(
                          userId: post.userId,
                        ),
                      ),
                    );
                  },
            child: _buildAvatar(isDark, textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.isNews) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEWS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
              ],
            ),
          ),
          if (!post.isNews && context.read<AuthProvider>().user?.uid == post.userId)
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: secondaryColor,
              ),
              onPressed: () => _showOptionsDialog(context, postService),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark, Color textColor) {
    // Para notícias, usa favicon
    if (post.isNews && post.newsUrl != null) {
      final domain = Uri.parse(post.newsUrl!).host.replaceAll('www.', '');
      final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
      
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: faviconUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
              child: const Icon(Icons.language, size: 20),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
              child: const Icon(Icons.language, size: 20),
            ),
          ),
        ),
      );
    }

    // Para usuários normais
    if (post.userAvatar != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        child: ClipOval(
          child: Image.memory(
            base64Decode(post.userAvatar!),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: 80,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
      child: Text(
        post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, bool isDark, Color textColor, Color secondaryColor, PostService postService) {
    // Vídeo
    if (post.videoUrl != null) {
      return GestureDetector(
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
        child: Container(
          width: double.infinity,
          height: 300,
          color: isDark ? const Color(0xFF000000) : const Color(0xFFF0F2F5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgIcon(
                svgString: CustomIcons.videoLibrary,
                size: 64,
                color: secondaryColor.withOpacity(0.3),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Assistir vídeo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Imagem Base64 (posts de usuários) - OTIMIZADO
    if (post.imageBase64 != null) {
      return GestureDetector(
        onTap: () => postService.openImageViewer(
          context,
          [post.imageBase64!],
          post.imageBase64!,
        ),
        child: Image.memory(
          base64Decode(post.imageBase64!),
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheHeight: 1000,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage(isDark, secondaryColor, 'Erro ao carregar imagem');
          },
        ),
      );
    }

    // Imagem URL (notícias) - Abre detalhes ao clicar
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: post.imageUrls!.first,
        width: double.infinity,
        fit: BoxFit.cover,
        maxHeightDiskCache: 1000,
        memCacheHeight: 1000,
        placeholder: (context, url) => Container(
          height: 200,
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return _buildErrorImage(isDark, secondaryColor, 'Imagem indisponível');
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorImage(bool isDark, Color secondaryColor, String message) {
    return Container(
      height: 200,
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: secondaryColor),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: secondaryColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    String? activeIcon,
    required String label,
    bool isActive = false,
    bool disabled = false,
    required VoidCallback onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final color = isActive
        ? const Color(0xFF1877F2)
        : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B));

    return Expanded(
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  svgString: isActive && activeIcon != null ? activeIcon : icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, PostService postService) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, postService);
            },
            child: const Text('Editar publicação'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, postService);
            },
            isDestructiveAction: true,
            child: const Text('Excluir publicação'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PostService postService) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Excluir publicação'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              postService.deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicação excluída')),
              );
            },
            child: const Text('Excluir'),
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
        backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Editar publicação',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'O que você está pensando?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                postService.updatePost(post.id, controller.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Publicação atualizada')),
                );
              }
            },
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Color(0xFF1877F2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}