import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ionicons/ionicons.dart';
import '../models.dart';
import '../rss_service.dart';
import '../news_card_widgets.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/matches_card.dart';
import '../widgets/skeleton_loader.dart';

class FootballFeedScreen extends StatefulWidget {
  const FootballFeedScreen({Key? key}) : super(key: key);

  @override
  State<FootballFeedScreen> createState() => _FootballFeedScreenState();
}

class _FootballFeedScreenState extends State<FootballFeedScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  int _selectedBottomTab = 0;
  bool _isLoading = true;
  bool _isDrawerOpen = false;
  bool _isDarkTheme = true;
  List<NewsArticle> _articles = [];
  final RssService _rssService = RssService();
  int _currentMatchPage = 0;

  final Map<String, String> _translationCache = {};

  late NewsCardWidgets _cardWidgets;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _drawerSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut),
    );
    _contentSlideAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut),
    );
    _initCardWidgets();
  }

  void _initCardWidgets() {
    _cardWidgets = NewsCardWidgets(
      isDarkTheme: _isDarkTheme,
      onTapUrl: _launchUrl,
      getTranslatedTitle: _getTranslatedTitle,
      getTranslatedDescription: _getTranslatedDescription,
      onTranslate: _handleTranslate,
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
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

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
    if (_isDrawerOpen) {
      _drawerAnimationController.forward();
    } else {
      _drawerAnimationController.reverse();
    }
  }

  Color get _bgColor => _isDarkTheme ? const Color(0xFF0A0A0A) : const Color(0xFFFAFBFD);
  Color get _surfaceColor => _isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _isDarkTheme ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  Color get _subTextColor => _isDarkTheme ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
  Color get _borderColor => _isDarkTheme ? const Color(0xFF3A3B3C) : const Color(0xFFDDDFE2);

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
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _contentSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width * _contentSlideAnimation.value, 0),
                child: Transform.scale(
                  scale: 1.0 - (_contentSlideAnimation.value * 0.1),
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_contentSlideAnimation.value * 20),
                    child: Container(
                      color: _bgColor,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            AppHeader(
                              onMenuTap: _toggleDrawer,
                              onSearchTap: () {},
                              bgColor: _bgColor,
                              borderColor: _borderColor,
                              textColor: _textColor,
                            ),
                            if (_selectedBottomTab == 0)
                              TabBarWidget(
                                selectedTab: _selectedTab,
                                onTabSelected: (index) => setState(() => _selectedTab = index),
                                bgColor: _bgColor,
                                textColor: _textColor,
                                subTextColor: _subTextColor,
                              ),
                            Expanded(child: _buildCurrentTab()),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              selectedIndex: _selectedBottomTab,
              onItemSelected: (index) {
                setState(() {
                  _selectedBottomTab = index;
                  if (index == 0 && _articles.isEmpty) _loadContent();
                });
              },
              surfaceColor: _surfaceColor,
              borderColor: _borderColor,
              subTextColor: _subTextColor,
            ),
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          if (_isDrawerOpen)
            AnimatedBuilder(
              animation: _drawerSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(MediaQuery.of(context).size.width * _drawerSlideAnimation.value, 0),
                  child: AppDrawer(
                    isDarkTheme: _isDarkTheme,
                    onThemeToggle: () {
                      setState(() {
                        _isDarkTheme = !_isDarkTheme;
                        _initCardWidgets();
                      });
                    },
                    onRefresh: _loadContent,
                    onClose: _toggleDrawer,
                    surfaceColor: _surfaceColor,
                    textColor: _textColor,
                    subTextColor: _subTextColor,
                    borderColor: _borderColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_selectedBottomTab == 0) return _buildFeedTab();
    return _buildEmptyTab(_selectedBottomTab == 1 ? 'Partidas' : 'TV');
  }

  Widget _buildEmptyTab(String title) {
    return Container(
      key: ValueKey(title),
      color: _bgColor,
      child: Center(
        child: Text(title, style: TextStyle(fontSize: 18, color: _subTextColor)),
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => SkeletonLoader(
          surfaceColor: _surfaceColor,
          borderColor: _borderColor,
        ),
      );
    }

    final filteredArticles = _filteredArticles;

    if (filteredArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.newspaper_outline, size: 64, color: _borderColor),
            const SizedBox(height: 16),
            Text('Nenhuma notícia disponível', style: TextStyle(fontSize: 15, color: _subTextColor)),
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
                surfaceColor: _surfaceColor,
                textColor: _textColor,
                subTextColor: _subTextColor,
                borderColor: _borderColor,
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