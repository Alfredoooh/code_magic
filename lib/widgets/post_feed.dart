// lib/widgets/post_feed.dart
import 'dart:async';
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
  late StreamSubscription<List<Post>> _sub;
  List<Post> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _sub = _postService.stream.listen((list) {
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
          _error = '';
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    });
    _postService.ensureStarted(); // começa listeners / timers
  }

  @override
  void dispose() {
    _sub.cancel();
    _postService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    if (_loading) {
      return Container(color: bgColor, child: const Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Container(
        color: bgColor,
        child: Center(child: Text('Erro ao carregar feed: $_error')),
      );
    }

    if (_items.isEmpty) {
      return Container(
        color: bgColor,
        child: Center(
          child: Text('Nenhuma publicação ainda', style: TextStyle(color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B))),
        ),
      );
    }

    // Responsive: se largura grande, mostrar grid de 2 colunas
    return Container(
      color: bgColor,
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return PostCard(post: _items[index]);
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _items.length,
            itemBuilder: (context, index) => PostCard(post: _items[index]),
          );
        }
      }),
    );
  }
}