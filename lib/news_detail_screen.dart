// lib/news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'markets_screen.dart';
import 'styles.dart' hide EdgeInsets; // evita conflito com EdgeInsets exportado por styles.dart

class NewsDetailScreen extends StatefulWidget {
  final NewsItem news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isBookmarked = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      setState(() {
        _scrollProgress = (maxScroll > 0) ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
      });
    }
  }

  Future<void> _launchURL() async {
    AppHaptics.medium();
    final Uri url = Uri.parse(widget.news.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) AppSnackbar.error(context, 'Não foi possível abrir o link');
    }
  }

  void _shareNews() {
    AppHaptics.light();
    Share.share(
      '${widget.news.title}\n\n${widget.news.summary}\n\nLeia mais em: ${widget.news.url}',
      subject: widget.news.title,
    );
  }

  void _toggleBookmark() {
    AppHaptics.light();
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    AppSnackbar.info(
      context,
      _isBookmarked ? 'Notícia salva' : 'Notícia removida',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: context.colors.surface,
            elevation: 0,
            pinned: true,
            expandedHeight: 80,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                AppHaptics.light();
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: _shareNews,
              ),
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                ),
                onPressed: _toggleBookmark,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: context.colors.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                minHeight: 2,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.colors.primary.withOpacity(0.1),
                      context.colors.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInWidget(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(widget.news.category),
                            size: 14,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.news.category.toUpperCase(),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      widget.news.title,
                      style: context.textStyles.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.news.favicon,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.article_rounded,
                                color: context.colors.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.news.source,
                                style: context.textStyles.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.news.time,
                                    style: context.textStyles.bodySmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: context.colors.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.remove_red_eye_rounded,
                                    size: 14,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_getRandomViews()} leituras',
                                    style: context.textStyles.bodySmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Divider(color: context.colors.outlineVariant),
                  const SizedBox(height: 32),

                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      widget.news.summary,
                      style: context.textStyles.bodyLarge?.copyWith(
                        height: 1.7,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Conteúdo do artigo (renderização externa / incorporada) ---
                  // Mantive apenas o botão para abrir o artigo completo em vez de
                  // preencher a tela com conteúdo fictício.
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedPrimaryButton(
                        text: 'Ler Artigo Completo',
                        icon: Icons.open_in_new_rounded,
                        onPressed: _launchURL,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nota: tags / seções / notícias relacionadas removidas conforme pedido.
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mercados':
      case 'markets':
        return Icons.trending_up_rounded;
      case 'trading':
        return Icons.show_chart_rounded;
      case 'análise':
      case 'analysis':
        return Icons.analytics_rounded;
      case 'notícias':
      case 'news':
        return Icons.newspaper_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  String _getRandomViews() {
    final views = [234, 567, 892, 1234, 2456, 3421];
    return views[DateTime.now().second % views.length].toString();
  }
}