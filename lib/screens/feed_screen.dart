import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ionicons/ionicons.dart';
import '../models.dart';
import '../rss_service.dart';
import '../news_card_widgets.dart';
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

class _FeedScreenState extends State<FeedScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;
  List<NewsArticle> _articles = [];
  final RssService _rssService = RssService();
  int _currentMatchPage = 0;

  final Map<String, String> _translationCache = {};

  late NewsCardWidgets _cardWidgets;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _initCardWidgets();
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

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final articles = await _rssService.fetchAllArticles();
    if (!mounted) return;

    setState(() {
      _articles = articles;
      _isLoading = false;
    });

    _prefetchTranslations(_articles);
  }

  List<NewsArticle> get _filteredArticles {
    if (_selectedTab == 0) return _articles;
    if (_selectedTab == 1) {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      return _articles.where((a) => a.pubDate != null && a.pubDate!.isAfter(yesterday)).toList();
    }
    return _articles.where((a) {
      final title = a.title.toLowerCase();
      final desc = (a.description ?? '').toLowerCase();
      return title.contains('transfer') || title.contains('mercado') || 
             title.contains('signing') || desc.contains('transfer') || desc.contains('mercado');
    }).toList();
  }

  Future<String?> _translateText(String text, {String target = 'pt'}) async {
    if (text.trim().isEmpty) return null;
    final key = '${text.hashCode}_$target';
    if (_translationCache.containsKey(key)) return _translationCache[key];

    try {
      final resp = await http.post(
        Uri.parse('https://libretranslate.com/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': text, 'source': 'auto', 'target': target, 'format': 'text'}),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final translated = data['translatedText'] as String?;
        if (translated != null) {
          _translationCache[key] = translated;
          return translated;
        }
      }
    } catch (e) {
      print('Translate request failed: $e');
    }
    return null;
  }

  Future<void> _prefetchTranslations(List<NewsArticle> articles) async {
    const batch = 5;
    for (var i = 0; i < articles.length; i += batch) {
      final sub = articles.sublist(i, (i + batch) > articles.length ? articles.length : i + batch);
      await Future.wait(sub.map((a) async {
        final keyTitle = '${a.title.hashCode}_pt';
        if (!_translationCache.containsKey(keyTitle)) {
          final t = await _translateText(a.title, target: 'pt');
          if (t != null) _translationCache[keyTitle] = t;
        }
        if (a.description != null && a.description!.trim().isNotEmpty) {
          final keyDesc = '${a.description!.hashCode}_pt';
          if (!_translationCache.containsKey(keyDesc)) {
            final td = await _translateText(a.description!, target: 'pt');
            if (td != null) _translationCache[keyDesc] = td;
          }
        }
      }).toList());
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) setState(() {});
  }

  String? _getTranslatedTitle(NewsArticle a) {
    final key = '${a.title.hashCode}_pt';
    return _translationCache.containsKey(key) ? _translationCache[key] : null;
  }

  String? _getTranslatedDescription(NewsArticle a) {
    if (a.description == null || a.description!.trim().isEmpty) return null;
    final key = '${a.description!.hashCode}_pt';
    return _translationCache.containsKey(key) ? _translationCache[key] : null;
  }

  Future<void> _handleTranslate(NewsArticle article) async {
    final keyTitle = '${article.title.hashCode}_pt';
    if (!_translationCache.containsKey(keyTitle)) {
      final t = await _translateText(article.title, target: 'pt');
      if (t != null) setState(() {});
    }
    if (article.description != null) {
      final keyDesc = '${article.description!.hashCode}_pt';
      if (!_translationCache.containsKey(keyDesc)) {
        final td = await _translateText(article.description!, target: 'pt');
        if (td != null) setState(() {});
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

  @override
  Widget build(BuildContext context) {
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
        itemBuilder: (context, index) => SkeletonLoader(
          surfaceColor: widget.surfaceColor,
          borderColor: widget.borderColor,
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
            Text('Nenhuma notícia disponível', style: TextStyle(fontSize: 15, color: widget.subTextColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2374E1)),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final highQualityArticles = filteredArticles.where((a) => a.hasHighQualityImage).toList();
    final lowQualityArticles = filteredArticles.where((a) => a.hasImage && !a.hasHighQualityImage).toList();
    final noImageArticles = filteredArticles.where((a) => !a.hasImage).toList();

    return ListView.builder(
      key: ValueKey('feed-$_selectedTab'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 1 + highQualityArticles.length +
          ((lowQualityArticles.isNotEmpty && highQualityArticles.length > 3) ? 1 : 0) +
          ((noImageArticles.isNotEmpty && highQualityArticles.length > 6) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              MatchesCard(
                matches: RssSources.todayMatches,
                currentPage: _currentMatchPage,
                onPageChanged: (page) => setState(() => _currentMatchPage = page),
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

        if (adjustedIndex == 3 && lowQualityArticles.isNotEmpty) {
          return Column(
            children: [
              _cardWidgets.buildLowQualityNewsGrid(lowQualityArticles.take(4).toList()),
              const SizedBox(height: 12),
            ],
          );
        }

        if (adjustedIndex == 6 && noImageArticles.isNotEmpty) {
          return Column(
            children: [
              _cardWidgets.buildHorizontalNewsList(noImageArticles.take(10).toList()),
              const SizedBox(height: 12),
            ],
          );
        }

        int articleIndex = adjustedIndex;
        if (adjustedIndex > 3 && lowQualityArticles.isNotEmpty) articleIndex--;
        if (adjustedIndex > 6 && noImageArticles.isNotEmpty) articleIndex--;

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
    );
  }
}