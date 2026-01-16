import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ionicons/ionicons.dart';
import '../models.dart';
import '../rss_service.dart';
import '../news_card_widget.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/matches_card.dart';
import '../widgets/skeleton_loader.dart';

class FeedScreen extends StatefulWidget {
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final bool isDarkTheme;

  const FeedScreen({
    Key? key,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<NewsArticle> _articles = [];
  final RssService _rssService = RssService();
  int _currentMatchPage = 0;
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _translationCache = {};
  late NewsCardWidgets _cardWidgets;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _initCardWidgets();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkTheme != widget.isDarkTheme) {
      _initCardWidgets();
    }
  }

  void _initCardWidgets() {
    _cardWidgets = NewsCardWidgets(
      isDarkTheme: widget.isDarkTheme,
      onTapUrl: _launchUrl,
      getTranslatedTitle: _getTranslatedTitle,
      getTranslatedDescription: _getTranslatedDescription,
      onTranslate: _handleTranslate,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 0 && !_isRefreshing) {
      // Pull to refresh no topo
    }
  }

  Future<void> _loadContent() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      // Carrega artigos de todas as fontes em paralelo
      final articles = await _rssService.fetchAllArticles();
      
      if (!mounted) return;

      // EMBARALHA AS NOTÍCIAS PARA MISTURAR AS FONTES
      final shuffledArticles = _shuffleArticlesBySource(articles);

      setState(() {
        _articles = shuffledArticles;
        _isLoading = false;
        _isRefreshing = false;
      });

      // Traduz em background (não bloqueia UI)
      _prefetchTranslationsInBackground(_articles);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      print('Error loading content: $e');
    }
  }

  // FUNÇÃO CRÍTICA: Embaralha artigos garantindo diversidade de fontes
  List<NewsArticle> _shuffleArticlesBySource(List<NewsArticle> articles) {
    if (articles.isEmpty) return articles;

    // Agrupa por fonte
    final Map<String, List<NewsArticle>> bySource = {};
    for (var article in articles) {
      final sourceName = article.source.name;
      bySource.putIfAbsent(sourceName, () => []).add(article);
    }

    // Cria lista balanceada alternando entre fontes
    final List<NewsArticle> balanced = [];
    final sources = bySource.keys.toList()..shuffle();
    
    int maxArticlesPerSource = (articles.length / sources.length).ceil();
    int currentIndex = 0;
    
    // Algoritmo round-robin para distribuir uniformemente
    while (balanced.length < articles.length) {
      bool addedAny = false;
      
      for (var source in sources) {
        final sourceArticles = bySource[source]!;
        final sourceIndex = (currentIndex * sources.length + sources.indexOf(source)) % sourceArticles.length;
        
        if (sourceIndex < sourceArticles.length) {
          // Verifica se o último artigo adicionado não é da mesma fonte
          if (balanced.isEmpty || balanced.last.source.name != source) {
            final article = sourceArticles[sourceIndex];
            if (!balanced.contains(article)) {
              balanced.add(article);
              addedAny = true;
            }
          }
        }
      }
      
      if (!addedAny) break;
      currentIndex++;
    }

    // Adiciona artigos restantes (se houver)
    for (var article in articles) {
      if (!balanced.contains(article)) {
        balanced.add(article);
      }
    }

    return balanced;
  }

  List<NewsArticle> get _filteredArticles {
    if (_selectedTab == 0) return _articles;
    
    if (_selectedTab == 1) {
      // Últimas 24h
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      return _articles.where((a) => 
        a.pubDate != null && a.pubDate!.isAfter(yesterday)
      ).toList();
    }
    
    if (_selectedTab == 2) {
      // Transferências
      return _articles.where((a) {
        final title = a.title.toLowerCase();
        final desc = (a.description ?? '').toLowerCase();
        return title.contains('transfer') || 
               title.contains('mercado') || 
               title.contains('signing') ||
               title.contains('contrat') ||
               desc.contains('transfer') || 
               desc.contains('mercado');
      }).toList();
    }
    
    return _articles;
  }

  // Tradução em background sem bloquear UI
  Future<void> _prefetchTranslationsInBackground(List<NewsArticle> articles) async {
    if (articles.isEmpty) return;

    // Traduz apenas os primeiros 15 artigos visíveis
    final visibleArticles = articles.take(15).toList();
    
    for (var article in visibleArticles) {
      if (!mounted) return;
      
      // Traduz título
      final keyTitle = '${article.title.hashCode}_pt';
      if (!_translationCache.containsKey(keyTitle)) {
        final translated = await _translateText(article.title, target: 'pt');
        if (translated != null && mounted) {
          setState(() => _translationCache[keyTitle] = translated);
        }
      }
      
      // Pequeno delay para não sobrecarregar
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<String?> _translateText(String text, {String target = 'pt'}) async {
    if (text.trim().isEmpty) return null;
    final key = '${text.hashCode}_$target';
    if (_translationCache.containsKey(key)) return _translationCache[key];

    try {
      final resp = await http.post(
        Uri.parse('https://libretranslate.com/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text, 
          'source': 'auto', 
          'target': target, 
          'format': 'text'
        }),
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final translated = data['translatedText'] as String?;
        if (translated != null) {
          _translationCache[key] = translated;
          return translated;
        }
      }
    } catch (e) {
      // Silenciosamente ignora erros de tradução
    }
    return null;
  }

  String? _getTranslatedTitle(NewsArticle a) {
    final key = '${a.title.hashCode}_pt';
    return _translationCache[key];
  }

  String? _getTranslatedDescription(NewsArticle a) {
    if (a.description == null || a.description!.trim().isEmpty) return null;
    final key = '${a.description!.hashCode}_pt';
    return _translationCache[key];
  }

  Future<void> _handleTranslate(NewsArticle article) async {
    // Traduz sob demanda quando usuário clica
    final keyTitle = '${article.title.hashCode}_pt';
    if (!_translationCache.containsKey(keyTitle)) {
      final t = await _translateText(article.title, target: 'pt');
      if (t != null && mounted) setState(() {});
    }
    
    if (article.description != null && article.description!.isNotEmpty) {
      final keyDesc = '${article.description!.hashCode}_pt';
      if (!_translationCache.containsKey(keyDesc)) {
        final td = await _translateText(article.description!, target: 'pt');
        if (td != null && mounted) setState(() {});
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      color: widget.bgColor,
      child: Column(
        children: [
          TabBarWidget(
            selectedTab: _selectedTab,
            onTabSelected: (index) => setState(() => _selectedTab = index),
            bgColor: widget.bgColor,
            textColor: widget.textColor,
            subTextColor: widget.subTextColor,
          ),
          Expanded(child: _buildFeedContent()),
        ],
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(
            surfaceColor: widget.surfaceColor,
            borderColor: widget.borderColor,
          ),
        ),
      );
    }

    final filteredArticles = _filteredArticles;

    if (filteredArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.newspaper_outline, size: 64, color: widget.borderColor),
            const SizedBox(height: 16),
            Text(
              'Nenhuma notícia disponível',
              style: TextStyle(fontSize: 15, color: widget.subTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2374E1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Ionicons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Separa artigos por qualidade de imagem
    final highQualityArticles = filteredArticles
        .where((a) => a.hasHighQualityImage)
        .toList();
    final mediumQualityArticles = filteredArticles
        .where((a) => a.hasImage && !a.hasHighQualityImage)
        .toList();
    final noImageArticles = filteredArticles
        .where((a) => !a.hasImage)
        .toList();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF2374E1),
      child: ListView.builder(
        controller: _scrollController,
        key: ValueKey('feed-$_selectedTab'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _calculateItemCount(
          highQualityArticles.length,
          mediumQualityArticles.length,
          noImageArticles.length,
        ),
        itemBuilder: (context, index) {
          // Card de partidas sempre primeiro
          if (index == 0) {
            return Column(
              children: [
                MatchesCard(
                  surfaceColor: widget.surfaceColor,
                  textColor: widget.textColor,
                  subTextColor: widget.subTextColor,
                  borderColor: widget.borderColor,
                ),
                const SizedBox(height: 16),
              ],
            );
          }

          final adjustedIndex = index - 1;

          // Grid de artigos médios após 3 artigos principais
          if (adjustedIndex == 3 && mediumQualityArticles.length >= 4) {
            return Column(
              children: [
                _cardWidgets.buildLowQualityNewsGrid(
                  mediumQualityArticles.take(4).toList()
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          // Lista horizontal de artigos sem imagem após 6 artigos
          if (adjustedIndex == 7 && noImageArticles.length >= 5) {
            return Column(
              children: [
                _cardWidgets.buildHorizontalNewsList(
                  noImageArticles.take(10).toList()
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          // Ajusta índice considerando cards especiais
          int articleIndex = adjustedIndex;
          if (adjustedIndex > 3 && mediumQualityArticles.length >= 4) {
            articleIndex--;
          }
          if (adjustedIndex > 7 && noImageArticles.length >= 5) {
            articleIndex--;
          }

          // Cards principais de alta qualidade
          if (articleIndex < highQualityArticles.length) {
            return Column(
              children: [
                _cardWidgets.buildNewsCard(highQualityArticles[articleIndex]),
                const SizedBox(height: 12),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  int _calculateItemCount(int high, int medium, int noImage) {
    int count = 1; // Matches card
    count += high;
    if (medium >= 4) count++; // Grid
    if (noImage >= 5) count++; // Horizontal list
    return count;
  }
}