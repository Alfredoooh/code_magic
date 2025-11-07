// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../widgets/video_widget.dart';
import '../widgets/expandable_link_text.dart';
import '../services/image_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_detail_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final postService = PostService();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserDetailScreen(userId: post.userId)));
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.userAvatar != null ? NetworkImage(post.userAvatar!) as ImageProvider : null,
                    child: post.userAvatar == null ? Text(post.userName.substring(0, 1).toUpperCase()) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(post.userName, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 2),
                      Text(_timeAgo(post.timestamp), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                    ]),
                  ),
                  if (auth.user?.uid == post.userId)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
                      onPressed: () => _showOptions(context),
                    )
                ],
              ),
            ),
          ),

          // content text (linkify + ver mais)
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ExpandableLinkText(text: post.content),
            ),

          // images (first image or carousel)
          if (post.images != null && post.images!.isNotEmpty)
            GestureDetector(
              onTap: () {
                postService.openImageViewer(context, post.images!, post.images!.first);
              },
              child: ImageService.buildImageFromUrl(post.images!.first, width: double.infinity, fit: BoxFit.cover),
            ),

          // video (YouTube or generic)
          if (post.videoUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AspectRatio(aspectRatio: 16 / 9, child: VideoWidget(url: post.videoUrl!)),
            ),

          // news card link (if news type)
          if (post.isNews && post.newsUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id, isNews: true)));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2D2E) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (post.newsImage != null)
                      SizedBox(
                        height: 140,
                        child: ImageService.buildImageFromUrl(post.newsImage!, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 8),
                    Text(post.title ?? '(notícia)', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 6),
                    Text(post.summary ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                  ]),
                ),
              ),
            ),

          // stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              if (post.likes > 0)
                Row(children: [
                  Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle), child: const Icon(Icons.thumb_up, size: 12, color: Colors.white)),
                  const SizedBox(width: 6),
                  Text('${post.likes}', style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                ]),
              const Spacer(),
              if (post.comments > 0) Text('${post.comments} comentários', style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
              if (post.shares > 0) ...[const SizedBox(width: 12), Text('${post.shares} compartilhamentos', style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)))],
            ]),
          ),

          // divider
          Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 12), color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA)),

          // actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => postService.toggleLike(post.id, Provider.of<AuthProvider>(context, listen: false).user!.uid),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: post.isLiked ? const Color(0xFF1877F2) : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                    const SizedBox(width: 6),
                    Text('Curtir', style: TextStyle(fontWeight: FontWeight.w600, color: post.isLiked ? const Color(0xFF1877F2) : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)))),
                  ])),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id))),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.comment_outlined, size: 20, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
                    const SizedBox(width: 6),
                    Text('Comentar', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                  ])),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => postService.sharePost(post),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.share_outlined, size: 20, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
                    const SizedBox(width: 6),
                    Text('Compartilhar', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                  ])),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) {
      return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Excluir'), onTap: () {
          Navigator.of(context).pop();
          PostService().deletePost(post.id);
        }),
        ListTile(leading: const Icon(Icons.edit), title: const Text('Editar'), onTap: () {
          Navigator.of(context).pop();
          // abrir editor (não implementado aqui)
        }),
      ]));
    });
  }
}