// lib/widgets/post_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'custom_icons.dart';

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
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final postService = PostService();
    final isLiked = auth.user != null ? post.isLikedBy(auth.user!.uid) : false;

    if (post.isNews && (post.title == null || post.title!.isEmpty) && (post.content.isEmpty || post.content.length < 10)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (c, a, s) => UserDetailScreen(userId: post.userId),
                transitionsBuilder: (c, a, s, ch) {
                  var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOutCubic));
                  return SlideTransition(position: a.drive(tween), child: ch);
                },
                transitionDuration: const Duration(milliseconds: 350),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
                    backgroundImage: post.userAvatar != null ? MemoryImage(base64Decode(post.userAvatar!)) : null,
                    child: post.userAvatar == null ? Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                        const SizedBox(height: 3),
                        Text(_formatTimestamp(post.timestamp), style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93))),
                      ],
                    ),
                  ),
                  if (auth.user?.uid == post.userId) IconButton(icon: SvgPicture.string(CustomIcons.moreHoriz, width: 24, height: 24, colorFilter: ColorFilter.mode(isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93), BlendMode.srcIn)), onPressed: () => _showOptions(context)),
                ],
              ),
            ),
          ),
          if (post.content.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: ExpandableLinkText(text: post.content)),
          if (post.isNews)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (c, a, s) => PostDetailScreen(postId: post.id, isNews: true),
                    transitionsBuilder: (c, a, s, ch) {
                      var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOutCubic));
                      return SlideTransition(position: a.drive(tween), child: ch);
                    },
                    transitionDuration: const Duration(milliseconds: 350),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: ImageService.buildImageFromUrl(post.imageUrls!.first, width: double.infinity, height: 180, fit: BoxFit.cover)),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.title != null) Text(post.title!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (post.summary != null) ...[
                              const SizedBox(height: 8),
                              Text(post.summary!, style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SvgPicture.string(CustomIcons.accessTime, width: 14, height: 14, colorFilter: ColorFilter.mode(isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999), BlendMode.srcIn)),
                                const SizedBox(width: 4),
                                Text(_formatTimestamp(post.timestamp), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999))),
                                const Spacer(),
                                Text('Ler mais', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))),
                                const SizedBox(width: 4),
                                SvgPicture.string(CustomIcons.arrowForward, width: 12, height: 12, colorFilter: ColorFilter.mode(isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF), BlendMode.srcIn)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!post.isNews && post.imageBase64 != null)
            GestureDetector(
              onTap: () => postService.openImageViewer(context, [post.imageBase64!], post.imageBase64!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(post.imageBase64!), width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 200, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0), child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)))),
                ),
              ),
            )
          else if (!post.isNews && post.imageUrls != null && post.imageUrls!.isNotEmpty)
            GestureDetector(
              onTap: () => postService.openImageViewer(context, post.imageUrls!, post.imageUrls!.first),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ImageService.buildImageFromUrl(post.imageUrls!.first, width: double.infinity, fit: BoxFit.cover))),
            ),
          if (!post.isNews && post.videoUrl != null) Padding(padding: const EdgeInsets.all(14), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 16 / 9, child: VideoWidget(url: post.videoUrl!)))),
          if (!post.isNews && (post.likes > 0 || post.comments > 0 || post.shares > 0))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  if (post.likes > 0)
                    Row(children: [
                      Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle), child: SvgPicture.string(CustomIcons.thumbUp, width: 11, height: 11, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
                      const SizedBox(width: 6),
                      Text('${post.likes}', style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666))),
                    ]),
                  const Spacer(),
                  if (post.comments > 0) Text('${post.comments} comentários', style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666))),
                  if (post.shares > 0) ...[const SizedBox(width: 12), Text('${post.shares} compartilhamentos', style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666)))],
                ],
              ),
            ),
          if (!post.isNews) Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 14), color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA)),
          if (!post.isNews)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: auth.user == null ? null : () => postService.toggleLike(post.id, auth.user!.uid),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SvgPicture.string(isLiked ? CustomIcons.thumbUp : CustomIcons.thumbUpOutlined, width: 20, height: 20, colorFilter: ColorFilter.mode(isLiked ? const Color(0xFF007AFF) : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666)), BlendMode.srcIn)),
                          const SizedBox(width: 6),
                          Text('Curtir', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isLiked ? const Color(0xFF007AFF) : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666)))),
                        ]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(PageRouteBuilder(pageBuilder: (c, a, s) => PostDetailScreen(postId: post.id), transitionsBuilder: (c, a, s, ch) {
                          var tw = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOutCubic));
                          return SlideTransition(position: a.drive(tw), child: ch);
                        }, transitionDuration: const Duration(milliseconds: 350)));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.string(CustomIcons.commentOutlined, width: 20, height: 20, colorFilter: ColorFilter.mode(isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666), BlendMode.srcIn)), const SizedBox(width: 6), Text('Comentar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666)))])),
                    ),
                  ),
                  Expanded(
                    child: InkWell(onTap: () => postService.sharePost(post), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.string(CustomIcons.shareOutlined, width: 20, height: 20, colorFilter: ColorFilter.mode(isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666), BlendMode.srcIn)), const SizedBox(width: 6), Text('Compartilhar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666)))]))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 12), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)))),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
                child: InkWell(onTap: () {Navigator.of(context).pop(); PostService().deletePost(post.id);}, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [SvgPicture.string(CustomIcons.delete, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn)), const SizedBox(width: 12), const Text('Excluir', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600))]))),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
                child: InkWell(onTap: () => Navigator.of(context).pop(), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [SvgPicture.string(CustomIcons.edit, width: 20, height: 20, colorFilter: ColorFilter.mode(isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF), BlendMode.srcIn)), const SizedBox(width: 12), Text('Editar', style: TextStyle(color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF), fontSize: 15, fontWeight: FontWeight.w600))]))),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}