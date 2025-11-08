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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Filtrar Feed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Opção: Misto
                  _FilterOption(
                    icon: CustomIcons.dashboard,
                    title: 'Misto',
                    subtitle: 'Posts e notícias intercalados',
                    isSelected: currentFilter == FeedFilter.mixed,
                    onTap: () {
                      _postService.setFilter(FeedFilter.mixed);
                      Navigator.pop(context);
                    },
                  ),

                  // Opção: Só Posts
                  _FilterOption(
                    icon: CustomIcons.person,
                    title: 'Apenas Posts',
                    subtitle: 'Exibir somente publicações de usuários',
                    isSelected: currentFilter == FeedFilter.postsOnly,
                    onTap: () {
                      _postService.setFilter(FeedFilter.postsOnly);
                      Navigator.pop(context);
                    },
                  ),

                  // Opção: Só Notícias
                  _FilterOption(
                    icon: CustomIcons.newspaper,
                    title: 'Apenas Notícias',
                    subtitle: 'Exibir somente notícias em tempo real',
                    isSelected: currentFilter == FeedFilter.newsOnly,
                    onTap: () {
                      _postService.setFilter(FeedFilter.newsOnly);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
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
                      SvgPicture.string(
                        CustomIcons.filterList,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getFilterText(_postService.currentFilter),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
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
                  return const Center(child: CircularProgressIndicator());
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

class _FilterOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0A84FF).withOpacity(0.12) : const Color(0xFF007AFF).withOpacity(0.08))
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9F9F9)),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDark ? const Color(0xFF0A84FF).withOpacity(0.3) : const Color(0xFF007AFF).withOpacity(0.2),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF0A84FF).withOpacity(0.15) : const Color(0xFF007AFF).withOpacity(0.1))
                      : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.string(
                  icon,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B)),
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
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                            : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                SvgPicture.string(
                  CustomIcons.checkCircle,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}