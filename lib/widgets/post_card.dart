// lib/widgets/post_card.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_detail_screen.dart';
import '../screens/video_detail_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    
    // Cores ajustadas - tema mais suave
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
    final dividerColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    
    final postService = PostService();
    final isLiked = auth.user != null ? post.isLikedBy(auth.user!.uid) : false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com blur se houver imagem
            _buildHeader(context, isDark, cardColor, textColor, secondaryColor, postService),

            // Conteúdo de mídia com blur effect
            _buildMediaContent(context, isDark, textColor, secondaryColor, postService),

            // Informações e ações
            _buildContent(context, isDark, textColor, secondaryColor, dividerColor, postService, isLiked),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color cardColor, Color textColor, Color secondaryColor, PostService postService) {
    final hasMedia = post.imageBase64 != null || 
                      (post.imageUrls?.isNotEmpty ?? false) || 
                      post.videoUrl != null;

    Widget headerContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar com gradiente
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: post.isNews
                  ? const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                radius: 20,
                backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                backgroundImage: post.userAvatar != null
                    ? MemoryImage(base64Decode(post.userAvatar!))
                    : null,
                child: post.userAvatar == null
                    ? Text(
                        post.isNews ? '📰' : (post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U'),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: post.isNews ? 18 : 16,
                        ),
                      )
                    : null,
              ),
            ),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          ),
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
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (!post.isNews && context.read<AuthProvider>().user?.uid == post.userId)
            IconButton(
              icon: SvgIcon(
                svgString: CustomIcons.moreVert,
                color: textColor,
                size: 20,
              ),
              onPressed: () => _showOptionsDialog(context, postService),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );

    // Se tiver mídia, adiciona blur no header
    if (hasMedia) {
      return Stack(
        children: [
          // Background blur da primeira imagem
          if (post.imageUrls?.isNotEmpty ?? false)
            Positioned.fill(
              child: Image.network(
                post.imageUrls!.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            )
          else if (post.imageBase64 != null)
            Positioned.fill(
              child: Image.memory(
                base64Decode(post.imageBase64!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: cardColor.withOpacity(0.7),
              ),
            ),
          ),
          // Header content
          headerContent,
        ],
      );
    }

    return headerContent;
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
          color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
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
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
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

    // Imagem Base64 (posts de usuários)
    if (post.imageBase64 != null) {
      return GestureDetector(
        onTap: () => postService.openImageViewer(
          context,
          [post.imageBase64!],
          post.imageBase64!,
        ),
        child: Hero(
          tag: 'post_image_${post.id}',
          child: Image.memory(
            base64Decode(post.imageBase64!),
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorImage(isDark, secondaryColor, 'Erro ao carregar imagem');
            },
          ),
        ),
      );
    }

    // Imagem URL (notícias da API)
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          if (post.newsUrl?.isNotEmpty == true) {
            // Implementar abertura de URL
            print('🔗 Abrir notícia: ${post.newsUrl}');
          }
        },
        child: Hero(
          tag: 'news_image_${post.id}',
          child: Image.network(
            post.imageUrls!.first,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 300,
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Carregando...',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erro ao carregar imagem: $error');
              return _buildErrorImage(isDark, secondaryColor, 'Imagem indisponível');
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorImage(bool isDark, Color secondaryColor, String message) {
    return Container(
      height: 300,
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              svgString: CustomIcons.warning,
              size: 48,
              color: secondaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color textColor, Color secondaryColor, Color dividerColor, PostService postService, bool isLiked) {
    final auth = context.read<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e conteúdo
          if (post.isNews && post.title != null && post.title!.isNotEmpty) ...[
            Text(
              post.title!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          if ((post.isNews && post.summary != null && post.summary!.isNotEmpty) || 
              (!post.isNews && post.content.isNotEmpty)) ...[
            RichText(
              text: TextSpan(
                children: [
                  if (!post.isNews)
                    TextSpan(
                      text: '${post.userName} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                  TextSpan(
                    text: post.isNews ? post.summary : post.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Divider
          Container(
            height: 1,
            color: dividerColor,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),

          // Actions e estatísticas
          Row(
            children: [
              // Like
              _buildActionButton(
                icon: isLiked ? CustomIcons.thumbUp : CustomIcons.thumbUpOutlined,
                color: isLiked ? Colors.blue : textColor,
                label: post.likes > 0 ? '${post.likes}' : null,
                onTap: post.isNews || auth.user == null
                    ? null
                    : () => postService.toggleLike(post.id, auth.user!.uid),
                disabled: post.isNews,
              ),
              const SizedBox(width: 4),

              // Comentários
              _buildActionButton(
                icon: CustomIcons.commentOutlined,
                color: textColor,
                label: post.comments > 0 ? '${post.comments}' : null,
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
              ),
              const SizedBox(width: 4),

              // Compartilhar
              _buildActionButton(
                icon: CustomIcons.shareOutlined,
                color: textColor,
                onTap: post.isNews ? null : () => postService.sharePost(post),
                disabled: post.isNews,
              ),

              const Spacer(),

              // Botão de notícia ou favorito
              if (post.newsUrl?.isNotEmpty == true)
                GestureDetector(
                  onTap: () {
                    print('🔗 Abrir: ${post.newsUrl}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ler mais',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                )
              else
                IconButton(
                  icon: SvgIcon(
                    svgString: CustomIcons.star,
                    color: secondaryColor,
                    size: 22,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required Color color,
    String? label,
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  svgString: icon,
                  color: color,
                  size: 22,
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, PostService postService) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: Text('Editar publicação', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, postService);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Excluir publicação', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
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
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Excluir publicação?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              postService.deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicação excluída')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
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
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Editar publicação', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
            child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
            child: const Text('Salvar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}