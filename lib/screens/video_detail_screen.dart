// lib/screens/video_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/post_service.dart';

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
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl);
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      _controller.setLooping(true);
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
              child: GestureDetector(
                onTap: _toggleControls,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_hasError)
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Erro ao carregar vídeo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!_isInitialized)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      else
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),

                      // Play/Pause overlay
                      if (_isInitialized && _showControls)
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),

                      // Video progress bar
                      if (_isInitialized && _showControls)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.blue,
                                    bufferedColor: Colors.grey,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_controller.value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_controller.value.duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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