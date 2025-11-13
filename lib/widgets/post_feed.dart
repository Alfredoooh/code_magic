// lib/widgets/post_feed.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import 'post_card.dart';
import 'custom_icons.dart';

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

  void _showFilterModal() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final currentFilter = _postService.currentFilter;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle visual
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.string(
                              CustomIcons.filterList,
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF1877F2),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filtrar Feed',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Escolha o tipo de conteúdo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentFilter != FeedFilter.mixed)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _postService.setFilter(FeedFilter.mixed);
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF3A3A3C)
                                    : const Color(0xFFF0F2F5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Limpar',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF0A84FF)
                                      : const Color(0xFF007AFF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Opções de filtro
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _FilterOptionTile(
                            emoji: '🌐',
                            title: 'Feed Misto',
                            subtitle: 'Posts e notícias intercalados',
                            isSelected: currentFilter == FeedFilter.mixed,
                            color: const Color(0xFF1877F2),
                            onTap: () {
                              setModalState(() {
                                _postService.setFilter(FeedFilter.mixed);
                              });
                              Future.delayed(const Duration(milliseconds: 300), () {
                                Navigator.pop(context);
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _FilterOptionTile(
                            emoji: '👤',
                            title: 'Apenas Posts',
                            subtitle: 'Publicações de usuários',
                            isSelected: currentFilter == FeedFilter.postsOnly,
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              setModalState(() {
                                _postService.setFilter(FeedFilter.postsOnly);
                              });
                              Future.delayed(const Duration(milliseconds: 300), () {
                                Navigator.pop(context);
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _FilterOptionTile(
                            emoji: '📰',
                            title: 'Apenas Notícias',
                            subtitle: 'Conteúdo em tempo real',
                            isSelected: currentFilter == FeedFilter.newsOnly,
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              setModalState(() {
                                _postService.setFilter(FeedFilter.newsOnly);
                              });
                              Future.delayed(const Duration(milliseconds: 300), () {
                                Navigator.pop(context);
                              });
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Botão de filtro no topo
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              color: isDark ? const Color(0xFF242526) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: isDark ? 0 : 1,
              shadowColor: Colors.black.withOpacity(0.05),
              child: InkWell(
                onTap: _showFilterModal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _postService.currentFilter != FeedFilter.mixed
                              ? (isDark ? const Color(0xFF0A84FF).withOpacity(0.15) : const Color(0xFF007AFF).withOpacity(0.1))
                              : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.string(
                          CustomIcons.filterList,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            _postService.currentFilter != FeedFilter.mixed
                                ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                                : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getFilterText(_postService.currentFilter),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _postService.currentFilter != FeedFilter.mixed
                                ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                                : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                          ),
                        ),
                      ),
                      if (_postService.currentFilter != FeedFilter.mixed)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      SvgPicture.string(
                        CustomIcons.expandMore,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Feed de posts
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar feed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          CustomIcons.inbox,
                          width: 64,
                          height: 64,
                          colorFilter: ColorFilter.mode(
                            isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(_postService.currentFilter),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptySubtitle(_postService.currentFilter),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  );
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
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: posts.length,
                      itemBuilder: (context, index) => PostCard(post: posts[index]),
                    );
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterText(FeedFilter filter) {
    switch (filter) {
      case FeedFilter.mixed:
        return 'Feed Misto';
      case FeedFilter.postsOnly:
        return 'Apenas Posts';
      case FeedFilter.newsOnly:
        return 'Apenas Notícias';
    }
  }

  String _getEmptyMessage(FeedFilter filter) {
    switch (filter) {
      case FeedFilter.mixed:
        return 'Nenhum conteúdo disponível';
      case FeedFilter.postsOnly:
        return 'Nenhuma publicação ainda';
      case FeedFilter.newsOnly:
        return 'Nenhuma notícia disponível';
    }
  }

  String _getEmptySubtitle(FeedFilter filter) {
    switch (filter) {
      case FeedFilter.mixed:
        return 'Aguardando posts e notícias';
      case FeedFilter.postsOnly:
        return 'Seja o primeiro a publicar';
      case FeedFilter.newsOnly:
        return 'Aguardando notícias em tempo real';
    }
  }
}

class _FilterOptionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterOptionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}