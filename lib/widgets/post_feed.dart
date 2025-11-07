// lib/widgets/post_feed.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import 'post_card.dart';

class PostFeed extends StatefulWidget {
  const PostFeed({super.key});

  @override
  State<PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed> {
  final PostService _postService = PostService();
  late final Stream<List<Post>> _stream;

  @override
  void initState() {
    super.initState();
    _postService.ensureStarted();
    _stream = _postService.stream;
  }

  @override
  void dispose() {
    _postService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return Container(
      color: bgColor,
      child: StreamBuilder<List<Post>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar posts: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(child: Text('Nenhuma publicação ainda', style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))));
          }

          return LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) => PostCard(post: posts[index]),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length,
                itemBuilder: (context, index) => PostCard(post: posts[index]),
              );
            }
          });
        },
      ),
    );
  }
}