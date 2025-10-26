// news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'markets_screen.dart';
import 'styles.dart';

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
        _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _launchURL() async {
    AppHaptics.medium();
    final Uri url = Uri.parse(widget.news.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppSnackbar.error(context, 'Não foi possível abrir o link');
      }
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
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInWidget(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
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

                  ..._buildContentSections(),

                  const SizedBox(height: 32),

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

                  _buildTags(),

                  const SizedBox(height: 32),
                  Divider(color: context.colors.outlineVariant),
                  const SizedBox(height: 24),

                  _buildRelatedNews(),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSections() {
    final sections = [
      {
        'title': 'Contexto do Mercado',
        'content': 'Os mercados financeiros globais continuam a demonstrar alta volatilidade em meio a incertezas econômicas. Analistas apontam que fatores macroeconômicos, incluindo políticas monetárias dos bancos centrais e indicadores de inflação, têm exercido pressão significativa sobre os ativos de risco.',
        'icon': Icons.public_rounded,
        'delay': 350,
      },
      {
        'title': 'Análise Técnica',
        'content': 'Do ponto de vista técnico, os principais índices apresentam padrões de consolidação, com resistências importantes sendo testadas. Traders experientes recomendam cautela e o uso adequado de stop-loss em posições atuais.',
        'icon': Icons.analytics_rounded,
        'delay': 400,
      },
      {
        'title': 'Perspectivas Futuras',
        'content': 'Para os próximos dias, espera-se que a volatilidade permaneça elevada, especialmente durante divulgações de dados econômicos importantes. Investidores devem manter-se atualizados sobre eventos macroeconômicos que podem impactar significativamente as cotações.',
        'icon': Icons.trending_up_rounded,
        'delay': 450,
      },
    ];

    return sections.map((section) {
      return FadeInWidget(
        delay: Duration(milliseconds: section['delay'] as int),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      section['icon'] as IconData,
                      size: 20,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section['title'] as String,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                section['content'] as String,
                style: context.textStyles.bodyMedium?.copyWith(
                  height: 1.6,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTags() {
    final tags = ['Trading', 'Mercados', 'Análise', 'Volatilidade'];

    return FadeInWidget(
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: context.textStyles.titleSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: context.colors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 14,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: context.textStyles.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedNews() {
    final relatedNews = [
      {
        'title': 'Volatilidade Atinge Níveis Recordes',
        'summary': 'Mercados globais registram maior movimento em meses',
        'source': 'Bloomberg',
        'time': '1h atrás',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Estratégias para Mercados Turbulentos',
        'summary': 'Especialistas compartilham dicas de gerenciamento de risco',
        'source': 'MarketWatch',
        'time': '3h atrás',
        'icon': Icons.psychology_rounded,
      },
      {
        'title': 'Índices Sintéticos Ganham Popularidade',
        'summary': 'Traders preferem mercados disponíveis 24/7',
        'source': 'Finance Weekly',
        'time': '5h atrás',
        'icon': Icons.show_chart_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInWidget(
          delay: const Duration(milliseconds: 550),
          child: Text(
            'Notícias Relacionadas',
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...relatedNews.asMap().entries.map((entry) {
          final index = entry.key;
          final news = entry.value;

          return FadeInWidget(
            delay: Duration(milliseconds: 600 + (index * 50)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppHaptics.light();
                    AppSnackbar.info(context, 'Abrindo notícia...');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            news['icon'] as IconData,
                            color: context.colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news['title'] as String,
                                style: context.textStyles.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                news['summary'] as String,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    news['source'] as String,
                                    style: context.textStyles.labelSmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: context.colors.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    news['time'] as String,
                                    style: context.textStyles.labelSmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
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