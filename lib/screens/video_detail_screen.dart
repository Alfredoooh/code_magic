// lib/screens/video_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/post_service.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

class VideoDetailScreen extends StatefulWidget {
  final String videoUrl;
  final Post post;

  const VideoDetailScreen({
    super.key,
    required this.videoUrl,
    required this.post,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final String _viewId = 'video-player-${DateTime.now().millisecondsSinceEpoch}';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Register view factory for HTML video element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final videoElement = html.VideoElement()
          ..src = widget.videoUrl
          ..controls = true
          ..autoplay = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..setAttribute('playsinline', 'true');

        return videoElement;
      },
    );

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    final postService = PostService();
    final isLiked = auth.user != null ? widget.post.isLikedBy(auth.user!.uid) : false;

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
                      widget.post.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Video Player
            Expanded(
              child: Container(
                color: Colors.black,
                child: _isInitialized
                    ? HtmlElementView(viewType: _viewId)
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
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
                        : () => postService.toggleLike(widget.post.id, auth.user!.uid),
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
                    onTap: () => postService.sharePost(widget.post),
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
                  if (widget.post.likes > 0)
                    Text(
                      '${widget.post.likes} ${widget.post.likes == 1 ? "curtida" : "curtidas"}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  if (widget.post.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${widget.post.userName} ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: widget.post.content,
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