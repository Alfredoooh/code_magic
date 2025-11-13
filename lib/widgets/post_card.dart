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

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    if (widget.post.isNews) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewsDetailScreen(post: widget.post),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final dividerColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    final postService = PostService();
    final isLiked = auth.user != null ? widget.post.isLikedBy(auth.user!.uid) : false;

    return GestureDetector(
      onTap: widget.post.isNews ? () => _openNewsDetail(context) : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark, textColor, secondaryColor, postService),

            // Media content (IMAGEM NO TOPO)
            _buildMediaContent(context, isDark, textColor, secondaryColor, postService),

            // Content text / Description (ABAIXO DA IMAGEM)
            if (widget.post.content.isNotEmpty && !widget.post.isNews)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Text(
                  widget.post.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Summary para notícias (preview) - ABAIXO DA IMAGEM
            if (widget.post.summary != null && widget.post.summary!.isNotEmpty && widget.post.isNews)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Text(
                  widget.post.summary!,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Stats
            if (widget.post.likes > 0 || widget.post.comments > 0 || widget.post.shares > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (widget.post.likes > 0) ...[
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
                        '${widget.post.likes}',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    ],
                    const Spacer(),
                    if (widget.post.comments > 0)
                      Text(
                        '${widget.post.comments} comentários',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    if (widget.post.shares > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${widget.post.shares} compartilhamentos',
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
                    disabled: widget.post.isNews,
                    onTap: () => postService.toggleLike(widget.post.id, auth.user!.uid),
                  ),
                  _buildActionButton(
                    context,
                    icon: CustomIcons.commentOutlined,
                    label: 'Comentar',
                    onTap: () {
                      if (widget.post.isNews) {
                        _openNewsDetail(context);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: widget.post.id,
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
                    disabled: widget.post.isNews,
                    onTap: () => postService.sharePost(widget.post),
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
            onTap: widget.post.isNews
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(
                          userId: widget.post.userId,
                        ),
                      ),
                    );
                  },
            child: _buildAvatar(isDark, textColor, secondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.userName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTimestamp(widget.post.timestamp),
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
              ],
            ),
          ),
          if (!widget.post.isNews && context.read<AuthProvider>().user?.uid == widget.post.userId)
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

  Widget _buildAvatar(bool isDark, Color textColor, Color secondaryColor) {
    // NOTÍCIA: MOSTRA FAVICON GRANDE E VISÍVEL
    if (widget.post.isNews && widget.post.newsUrl != null) {
      final domain = Uri.parse(widget.post.newsUrl!).host.replaceAll('www.', '');
      
      // Múltiplos fallbacks para garantir que o favicon apareça
      final faviconUrls = [
        'https://www.google.com/s2/favicons?domain=$domain&sz=256',
        'https://$domain/favicon.ico',
        'https://www.google.com/s2/favicons?domain=$domain&sz=128',
      ];

      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF3A3B3C) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildFaviconWithFallback(
            faviconUrls,
            0,
            isDark,
            secondaryColor,
          ),
        ),
      );
    }

    // USUÁRIO NORMAL: Avatar com foto ou inicial
    if (widget.post.userAvatar != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            width: 1,
          ),
        ),
        child: CircleAvatar(
          radius: 21,
          backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
          child: ClipOval(
            child: Image.memory(
              base64Decode(widget.post.userAvatar!),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: 88,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    widget.post.userName.isNotEmpty 
                        ? widget.post.userName[0].toUpperCase() 
                        : 'U',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          widget.post.userName.isNotEmpty 
              ? widget.post.userName[0].toUpperCase() 
              : 'U',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // Widget recursivo para tentar múltiplas URLs de favicon
  Widget _buildFaviconWithFallback(
    List<String> urls,
    int index,
    bool isDark,
    Color secondaryColor,
  ) {
    if (index >= urls.length) {
      // Último fallback: ícone genérico
      return Container(
        color: isDark ? const Color(0xFF3A3B3C) : Colors.white,
        child: Center(
          child: Icon(
            Icons.article_outlined,
            size: 24,
            color: const Color(0xFF1877F2),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: urls[index],
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      memCacheWidth: 88,
      maxWidthDiskCache: 88,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        color: isDark ? const Color(0xFF3A3B3C) : Colors.white,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Tenta próxima URL
        return _buildFaviconWithFallback(
          urls,
          index + 1,
          isDark,
          secondaryColor,
        );
      },
    );
  }

  Widget _buildMediaContent(BuildContext context, bool isDark, Color textColor, Color secondaryColor, PostService postService) {
    // Vídeo
    if (widget.post.videoUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VideoDetailScreen(
                  videoUrl: widget.post.videoUrl!,
                  post: widget.post,
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
        ),
      );
    }

    // PRIORIDADE 1: imageUrls (notícias ou posts com URL)
    if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        child: RepaintBoundary(
          child: CachedNetworkImage(
            imageUrl: widget.post.imageUrls!.first,
            width: double.infinity,
            fit: BoxFit.cover,
            maxHeightDiskCache: 800,
            memCacheHeight: 800,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => Container(
              height: 250,
              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              return _buildErrorImage(isDark, secondaryColor, 'Imagem indisponível');
            },
          ),
        ),
      );
    }

    // PRIORIDADE 2: imageBase64 (URL ou Base64)
    if (widget.post.imageBase64 != null && widget.post.imageBase64!.isNotEmpty) {
      // Verifica se é URL
      if (widget.post.imageBase64!.startsWith('http://') || 
          widget.post.imageBase64!.startsWith('https://')) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          child: RepaintBoundary(
            child: CachedNetworkImage(
              imageUrl: widget.post.imageBase64!,
              width: double.infinity,
              fit: BoxFit.cover,
              maxHeightDiskCache: 800,
              memCacheHeight: 800,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => Container(
                height: 250,
                color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                return _buildErrorImage(isDark, secondaryColor, 'Imagem indisponível');
              },
            ),
          ),
        );
      }

      // Se é Base64
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        child: RepaintBoundary(
          child: FutureBuilder<Image>(
            future: _decodeBase64Image(widget.post.imageBase64!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return GestureDetector(
                  onTap: () => postService.openImageViewer(
                    context,
                    [widget.post.imageBase64!],
                    widget.post.imageBase64!,
                  ),
                  child: snapshot.data!,
                );
              }
              return Container(
                height: 250,
                color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<Image> _decodeBase64Image(String base64String) async {
    final bytes = base64Decode(base64String);
    return Image.memory(
      bytes,
      width: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 800,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 250,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 48),
        );
      },
    );
  }

  Widget _buildErrorImage(bool isDark, Color secondaryColor, String message) {
    return Container(
      height: 250,
      color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
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
          borderRadius: BorderRadius.circular(8),
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
              postService.deletePost(widget.post.id);
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
    final controller = TextEditingController(text: widget.post.content);

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
                postService.updatePost(widget.post.id, controller.text.trim());
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