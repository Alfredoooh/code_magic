// lib/widgets/post_feed.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../services/image_service.dart';
import '../models/post_model.dart';
import '../widgets/custom_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostFeed extends StatefulWidget {
  const PostFeed({super.key});

  @override
  State<PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed> {
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return Container(
      color: bgColor,
      child: StreamBuilder<List<Post>>(
        stream: _postService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar posts: ${snapshot.error}'),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(
                    svgString: CustomIcons.home,
                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                    size: 64,
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final isLiked = post.isLikedBy(authProvider.currentUser?.uid ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Base64Avatar(
                  base64Image: post.userAvatar,
                  fallbackText: post.userName,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        timeago.format(post.timestamp, locale: 'pt_BR'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.userId == authProvider.currentUser?.uid)
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                    onPressed: () => _showPostOptions(context, post),
                  ),
              ],
            ),
          ),

          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),

          // Image
          if (post.imageBase64 != null)
            GestureDetector(
              onTap: () => _showImageFullscreen(context, post.imageBase64!),
              child: ImageService.buildImageFromBase64(
                post.imageBase64,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // Stats
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
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                ],
                const Spacer(),
                if (post.comments > 0)
                  Text(
                    '${post.comments} comentários',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                if (post.shares > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${post.shares} compartilhamentos',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.thumb_up_outlined,
                  activeIcon: Icons.thumb_up,
                  label: 'Curtir',
                  isActive: isLiked,
                  onTap: () => _toggleLike(context, post),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.comment_outlined,
                  label: 'Comentar',
                  onTap: () => _showComments(context, post),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.share_outlined,
                  label: 'Compartilhar',
                  onTap: () => _sharePost(context, post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    IconData? activeIcon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final color = isActive
        ? const Color(0xFF1877F2)
        : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B));

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive && activeIcon != null ? activeIcon : icon,
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
    );
  }

  Future<void> _toggleLike(BuildContext context, Post post) async {
    final authProvider = context.read<AuthProvider>();
    final postService = PostService();
    
    try {
      await postService.toggleLike(post.id, authProvider.currentUser!.uid);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _showComments(BuildContext context, Post post) {
    // TODO: Implementar tela de comentários
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comentários em desenvolvimento')),
    );
  }

  Future<void> _sharePost(BuildContext context, Post post) async {
    final postService = PostService();
    
    try {
      await postService.sharePost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post compartilhado!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _showPostOptions(BuildContext context, Post post) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(context, post);
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

  Future<void> _deletePost(BuildContext context, Post post) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Excluir publicação'),
        content: const Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final postService = PostService();
      try {
        await postService.deletePost(post.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicação excluída')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  void _showImageFullscreen(BuildContext context, String base64Image) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: ImageService.buildImageFromBase64(base64Image),
            ),
          ),
        ),
      ),
    );
  }
}