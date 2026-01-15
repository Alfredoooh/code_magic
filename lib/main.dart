// main.dart - UI e lógica principal
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:palette_generator/palette_generator.dart';
import 'svg_icons.dart';
import 'models.dart';
import 'rss_service.dart';
import 'news_card_widgets.dart';

void main() {
  runApp(const FootballFeedApp());
}

class FootballFeedApp extends StatelessWidget {
  const FootballFeedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Feed',
      theme: ThemeData(
        fontFamily: '-apple-system',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2374E1)),
        scaffoldBackgroundColor: Color(0xFF0A0A0A),
      ),
      home: const FootballFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
  final PageController _matchesPageController = PageController();
  int _currentMatchPage = 0;

  final Map<String, Color> _imageColorCache = {};
  final Map<String, String> _translationCache = {};
  
  late NewsCardWidgets _cardWidgets;

  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _contentSlideAnimation;

  final String _tvOutlineSvg = '''<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" id="Outline" viewBox="0 0 24 24" width="512" height="512"><path d="M19,3H5A5.006,5.006,0,0,0,0,8v6a5.006,5.006,0,0,0,5,5h6v1H8a1,1,0,0,0,0,2h8a1,1,0,0,0,0-2H13V19h6a5.006,5.006,0,0,0,5-5V8A5.006,5.006,0,0,0,19,3Zm3,11a3,3,0,0,1-3,3H5a3,3,0,0,1-3-3V8A3,3,0,0,1,5,5H19a3,3,0,0,1,3,3Z"/></svg>''';

  final String _tvFilledSvg = '''<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" id="Filled" viewBox="0 0 24 24" width="512" height="512"><path d="M19,3H5A5.006,5.006,0,0,0,0,8v6a5.006,5.006,0,0,0,5,5h6v1H8a1,1,0,0,0,0,2h8a1,1,0,0,0,0-2H13V19h6a5.006,5.006,0,0,0,5-5V8A5.006,5.006,0,0,0,19,3Z"/></svg>''';

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
      colorCache: _imageColorCache,
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    _matchesPageController.dispose();
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

    _prefetchImageColors(_articles);
    _prefetchTranslations(_articles);
  }
  
  // OTIMIZADO: Prefetch mais leve - apenas primeiras imagens
  void _prefetchImageColors(List<NewsArticle> articles) {
    final highQuality = articles.where((a) => a.hasHighQualityImage).take(10).toList();
    for (var article in highQuality) {
      if (article.imageUrl != null && !_imageColorCache.containsKey(article.imageUrl)) {
        _extractColorInBackground(article.imageUrl!);
      }
    }
  }
  
  // Extração em background sem bloquear UI
  Future<void> _extractColorInBackground(String imageUrl) async {
    if (_imageColorCache.containsKey(imageUrl)) return;
    
    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 8, // Reduzido de 20 para 8
        timeout: const Duration(seconds: 3),
      );
      
      final color = palette.dominantColor?.color ?? 
                    palette.vibrantColor?.color ?? 
                    const Color(0xFF2374E1);
      
      if (mounted) {
        setState(() {
          _imageColorCache[imageUrl] = color;
        });
      }
    } catch (e) {
      _imageColorCache[imageUrl] = const Color(0xFF2374E1);
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _initCardWidgets(); // Atualizar widgets quando tema mudar
    });
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
    if (_selectedTab == 0) {
      return _articles;
    } else if (_selectedTab == 1) {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      return _articles.where((a) {
        if (a.pubDate == null) return false;
        return a.pubDate!.isAfter(yesterday);
      }).toList();
    } else {
      return _articles.where((a) {
        final title = a.title.toLowerCase();
        final desc = (a.description ?? '').toLowerCase();
        return title.contains('transfer') ||
            title.contains('mercado') ||
            title.contains('signing') ||
            desc.contains('transfer') ||
            desc.contains('mercado');
      }).toList();
    }
  }

  // REMOVIDO: _getImagePrimaryColor - agora está no NewsCardWidgets
  
  // REMOVIDO: _prefetchImageColors - substituído pela versão otimizada acima

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
          'format': 'text',
        }),
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
    final keyDesc = article.description != null ? '${article.description!.hashCode}_pt' : null;
    if (keyDesc != null && !_translationCache.containsKey(keyDesc)) {
      final td = await _translateText(article.description!, target: 'pt');
      if (td != null) setState(() {});
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return '1 dia';
    if (diff.inDays < 7) return '${diff.inDays} dias';
    return '${date.day}/${date.month}';
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
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _contentSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * _contentSlideAnimation.value,
                  0,
                ),
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
                            _buildHeader(),
                            if (_selectedBottomTab == 0) _buildTabBar(),
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
            child: _buildBottomNavBar(),
          ),

          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withOpacity(0.45),
              ),
            ),

          if (_isDrawerOpen)
            AnimatedBuilder(
              animation: _drawerSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    MediaQuery.of(context).size.width * _drawerSlideAnimation.value,
                    0,
                  ),
                  child: _buildDrawer(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(color: _surfaceColor),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _borderColor,
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        SvgIcons.profileFilled,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(_textColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Usuario',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textColor),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _borderColor),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    _isDarkTheme ? Ionicons.moon : Ionicons.sunny,
                    color: _textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isDarkTheme ? 'Modo Escuro' : 'Modo Claro',
                      style: TextStyle(fontSize: 16, color: _textColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isDarkTheme = !_isDarkTheme;
                      _initCardWidgets(); // Atualizar tema dos cards
                    }),
                    child: Container(
                      width: 51,
                      height: 31,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _isDarkTheme ? const Color(0xFF2374E1) : const Color(0xFFE4E6EB),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: _isDarkTheme ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 27,
                          height: 27,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(Ionicons.refresh_outline, 'Atualizar Feed', () {
                    _toggleDrawer();
                    _loadContent();
                  }),
                  _buildDrawerItem(Ionicons.globe_outline, 'Todas as Fontes', () {}),
                  _buildDrawerItem(Ionicons.star_outline, 'Favoritos', () {}),
                  _buildDrawerItem(Ionicons.settings_outline, 'Configuracoes', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _textColor),
      title: Text(title, style: TextStyle(color: _textColor)),
      onTap: onTap,
    );
  }

  Widget _buildCurrentTab() {
    if (_selectedBottomTab == 0) {
      return _buildFeedTab();
    } else if (_selectedBottomTab == 1) {
      return _buildEmptyTab('Partidas');
    } else {
      return _buildEmptyTab('TV');
    }
  }

  Widget _buildEmptyTab(String title) {
    return Container(
      key: ValueKey(title),
      color: _bgColor,
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 18, color: _subTextColor),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _borderColor,
                ),
                child: Center(
                  child: SvgPicture.string(
                    SvgIcons.profileFilled,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(_textColor, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2374E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Ionicons.football, color: Colors.white, size: 20),
                );
              },
            ),
            GestureDetector(
              onTap: () {},
              child: SvgPicture.string(
                SvgIcons.search,
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTopTabButton('Para voce', 0),
          const SizedBox(width: 24),
          _buildTopTabButton('Hoje', 1),
          const SizedBox(width: 24),
          _buildTopTabButton('Mercado', 2),
        ],
      ),
    );
  }

  Widget _buildTopTabButton(String text, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? _textColor : _subTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2374E1) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonPost(),
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
            Text(
              'Nenhuma noticia disponivel',
              style: TextStyle(fontSize: 15, color: _subTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2374E1),
              ),
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
              _buildMatchesCard(),
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

  Widget _buildMatchesCard() {
    final matches = RssSources.todayMatches;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Ionicons.football_outline, size: 18, color: _textColor),
                const SizedBox(width: 8),
                Text(
                  'Jogos de Hoje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _matchesPageController,
              onPageChanged: (index) {
                setState(() => _currentMatchPage = index);
              },
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return _buildMatchItem(matches[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              matches.length > 10 ? 10 : matches.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentMatchPage == index ? const Color(0xFF2374E1) : _borderColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMatchItem(Match match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: match.isLive ? Colors.red.withOpacity(0.1) : _borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              match.isLive ? 'AO VIVO' : match.competition,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: match.isLive ? Colors.red : _subTextColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  match.homeTeam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${match.homeScore} - ${match.awayScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  match.awayTeam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            match.isFinished ? 'FT' : match.time,
            style: TextStyle(
              fontSize: 12,
              color: _subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowQualityNewsGrid(List<NewsArticle> articles) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: articles.length > 4 ? 4 : articles.length,
      itemBuilder: (context, index) {
        return _buildSmallNewsCard(articles[index]);
      },
    );
  }

  Widget _buildSmallNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.hasImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                      placeholder: (context, url) => Container(
                        height: 100,
                        color: _borderColor,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 100,
                        color: _borderColor,
                        child: Icon(Ionicons.image_outline, color: _subTextColor),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(_isDarkTheme ? 0.35 : 0.08),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _borderColor,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: article.source.favicon,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                              errorWidget: (context, url, error) => Icon(
                                Ionicons.globe_outline,
                                size: 12,
                                color: _subTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.source.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _subTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        _getTranslatedTitle(article) ?? article.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _textColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalNewsList(List<NewsArticle> articles) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return _buildCompactNewsCard(articles[index]);
        },
      ),
    );
  }

  Widget _buildCompactNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _borderColor,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: article.source.favicon,
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                      httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                      errorWidget: (context, url, error) => Icon(
                        Ionicons.globe_outline,
                        size: 10,
                        color: _subTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    article.source.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _subTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                _getTranslatedTitle(article) ?? article.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: _textColor,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (article.pubDate != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(article.pubDate!),
                style: TextStyle(fontSize: 11, color: _subTextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    final imageUrl = article.imageUrl;
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: FutureBuilder<Color>(
        future: _getImagePrimaryColor(imageUrl),
        builder: (context, snap) {
          final primaryColor = snap.data ?? const Color(0xFF2374E1);
          return Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: primaryColor.withOpacity(0.12), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                if (article.hasImage)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                          placeholder: (context, url) => Container(
                            height: 220,
                            color: _borderColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2374E1)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              height: 220,
                              color: _borderColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Ionicons.image_outline, size: 48, color: _subTextColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Imagem indisponivel',
                                    style: TextStyle(fontSize: 12, color: _subTextColor),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(_isDarkTheme ? 0.02 : 0.0),
                                Colors.black.withOpacity(_isDarkTheme ? 0.55 : 0.10),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _borderColor.withOpacity(0.5),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: article.source.favicon,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                                errorWidget: (context, url, error) => Icon(
                                  Ionicons.globe_outline,
                                  size: 12,
                                  color: _subTextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.source.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _subTextColor,
                            ),
                          ),
                          if (article.pubDate != null) ...[
                            Text(' · ', style: TextStyle(color: _subTextColor)),
                            Text(
                              _formatTime(article.pubDate!),
                              style: TextStyle(fontSize: 12, color: _subTextColor),
                            ),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              final keyTitle = '${article.title.hashCode}_pt';
                              if (!_translationCache.containsKey(keyTitle)) {
                                final t = await _translateText(article.title, target: 'pt');
                                if (t != null) setState(() {});
                              }
                              final keyDesc = article.description != null ? '${article.description!.hashCode}_pt' : null;
                              if (keyDesc != null && !_translationCache.containsKey(keyDesc)) {
                                final td = await _translateText(article.description!, target: 'pt');
                                if (td != null) setState(() {});
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Ionicons.language_outline, size: 18, color: _subTextColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTranslatedTitle(article) ?? article.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _textColor,
                        ),
                      ),
                      if ((article.description != null && article.description!.isNotEmpty) || _getTranslatedDescription(article) != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getTranslatedDescription(article) ?? (article.description ?? ''),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: _subTextColor,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(
            child: Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildShimmer(
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      onEnd: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });
      },
      child: child,
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                SvgIcons.homeOutline,
                SvgIcons.homeFilled,
                'Inicio',
                0,
              ),
              _buildBottomNavItem(
                SvgIcons.matchesOutline,
                SvgIcons.matchesFilled,
                'Partidas',
                1,
              ),
              _buildBottomNavItem(
                _tvOutlineSvg,
                _tvFilledSvg,
                'TV',
                2,
                inactiveColor: const Color(0xFF9AA0A6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    String outlinedSvg,
    String filledSvg,
    String label,
    int index, {
    Color? inactiveColor,
  }) {
    final isSelected = _selectedBottomTab == index;
    final Color colorInactive = inactiveColor ?? _subTextColor;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomTab = index;
          if (index == 0 && _articles.isEmpty) {
            _loadContent();
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            isSelected ? filledSvg : outlinedSvg,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? const Color(0xFF2374E1) : colorInactive,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF2374E1) : colorInactive,
            ),
          ),
        ],
      ),
    );
  }
}