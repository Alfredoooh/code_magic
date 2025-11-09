// lib/screens/video_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/post_service.dart';

class VideoDetailScreen extends StatelessWidget {
  final String videoUrl;
  final Post post;

  const VideoDetailScreen({
    super.key,
    required this.videoUrl,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    final postService = PostService();
    final isLiked = auth.user != null ? post.isLikedBy(auth.user!.uid) : false;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      post.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Video Player - Iframe
            Expanded(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 80,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Vídeo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Abre o vídeo em nova aba
                            // ignore: avoid_web_libraries_in_flutter
                            // import 'dart:html' as html;
                            // html.window.open(videoUrl, '_blank');
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Abrir vídeo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000000) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFDBDBDB),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: auth.user == null
                        ? null
                        : () => postService.toggleLike(post.id, auth.user!.uid),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 28,
                      color: isLiked ? Colors.red : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 26,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 18),
                  InkWell(
                    onTap: () => postService.sharePost(post),
                    child: Icon(
                      Icons.send_outlined,
                      size: 26,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.bookmark_border,
                    size: 26,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ),

            // Likes and content
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF000000) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.likes > 0)
                    Text(
                      '${post.likes} ${post.likes == 1 ? "curtida" : "curtidas"}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${post.userName} ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: post.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}