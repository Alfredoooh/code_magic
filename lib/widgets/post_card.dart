// lib/widgets/post_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../widgets/expandable_link_text.dart';
import '../widgets/video_widget.dart';
import '../services/image_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_detail_screen.dart';

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
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final postService = PostService();

    final isLiked = auth.user != null ? post.isLikedBy(auth.user!.uid) : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserDetailScreen(userId: post.userId)));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: post.userAvatar != null ? MemoryImage(base64Decode(post.userAvatar!)) : null,
                child: post.userAvatar == null ? Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U') : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.userName, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 2),
                  Text(_formatTimestamp(post.timestamp), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                ]),
              ),
              if (auth.user?.uid == post.userId)
                IconButton(
                  icon: Icon(Icons.more_horiz, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
                  onPressed: () => _showOptions(context),
                )
            ]),
          ),
        ),

        // content
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ExpandableLinkText(text: post.content),
          ),

        // imageBase64 (prioriza)
        if (post.imageBase64 != null)
          GestureDetector(
            onTap: () => postService.openImageViewer(context, [], ''), // se quiser fullscreen, adapta
            child: Image.memory(
              base64Decode(post.imageBase64!),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
          GestureDetector(
            onTap: () => postService.openImageViewer(context, post.imageUrls!, post.imageUrls!.first),
            child: ImageService.buildImageFromUrl(post.imageUrls!.first, width: double.infinity, fit: BoxFit.cover),
          ),

        // video
        if (post.videoUrl != null)
          Padding(padding: const EdgeInsets.all(12), child: AspectRatio(aspectRatio: 16 / 9, child: VideoWidget(url: post.videoUrl!))),

        // news card
        if (post.isNews)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id, isNews: true))),
              child: Container(
                decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2D2E) : const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (post.imageUrls != null && post.imageUrls!.isNotEmpty) SizedBox(height: 140, child: ImageService.buildImageFromUrl(post.imageUrls!.first, fit: BoxFit.cover)),
                  const SizedBox(height: 8),
                  Text(post.title ?? '(notícia)', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  Text(post.summary ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                ]),
              ),
            ),
          ),

        // stats
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
                onTap: auth.user == null ? null : () => postService.toggleLike(post.id, auth.user!.uid),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: isLiked ? const Color(0xFF1877F2) : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
                    const SizedBox(width: 6),
                    Text('Curtir', style: TextStyle(fontWeight: FontWeight.w600, color: isLiked ? const Color(0xFF1877F2) : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)))),
                  ]),
                ),
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
      ]),
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
          // abrir editor (implementar se quiser)
        }),
      ]));
    });
  }
}