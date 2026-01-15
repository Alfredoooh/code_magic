// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:translator/translator.dart';
import 'svg_icons.dart';

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
      ),
      home: const FootballFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NewsSource {
  final String name;
  final String rss;
  final String favicon;
  final String? country;

  NewsSource({
    required this.name,
    required this.rss,
    required this.favicon,
    this.country,
  });
}

class NewsArticle {
  final String title;
  final String? description;
  final String? imageUrl;
  final String link;
  final DateTime? pubDate;
  final NewsSource source;

  NewsArticle({
    required this.title,
    this.description,
    this.imageUrl,
    required this.link,
    this.pubDate,
    required this.source,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasHighQualityImage {
    if (!hasImage) return false;
    final url = imageUrl!.toLowerCase();
    return !url.contains('thumbnail') &&
        !url.contains('small') &&
        !url.contains('tiny') &&
        !url.contains('icon');
  }
}

class Match {
  final String homeTeam;
  final String awayTeam;
  final String homeScore;
  final String awayScore;
  final String competition;
  final String time;
  final bool isLive;
  final bool isFinished;

  Match({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.competition,
    required this.time,
    this.isLive = false,
    this.isFinished = false,
  });
}

class RssSources {
  static final List<NewsSource> sources = [
    NewsSource(
        name: "ZeroZero",
        rss: "https://www.zerozero.pt/rss/noticias.php",
        favicon: "https://www.zerozero.pt/favicon.ico",
        country: "PT"),
    NewsSource(
        name: "90min",
        rss: "https://90min.com/posts.rss",
        favicon: "https://90min.com/favicon.ico",
        country: "INT"),
    NewsSource(
        name: "Goal",
        rss: "https://www.goal.com/feeds/en/news",
        favicon: "https://www.goal.com/favicon.ico",
        country: "INT"),
    NewsSource(
        name: "ESPN",
        rss: "https://www.espn.com/espn/rss/news",
        favicon: "https://www.espn.com/favicon.ico",
        country: "USA"),
    NewsSource(
        name: "BBC Sport",
        rss: "https://feeds.bbci.co.uk/sport/football/rss.xml",
        favicon: "https://www.bbc.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "Sky Sports",
        rss: "https://www.skysports.com/rss/12040",
        favicon: "https://www.skysports.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "The Guardian",
        rss: "https://www.theguardian.com/football/rss",
        favicon: "https://www.theguardian.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "FourFourTwo",
        rss: "https://www.fourfourtwo.com/rss",
        favicon: "https://www.fourfourtwo.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "Marca",
        rss: "https://e00-marca.uecdn.es/rss/en/international.xml",
        favicon: "https://www.marca.com/favicon.ico",
        country: "ES"),
    NewsSource(
        name: "AS",
        rss: "https://as.com/rss",
        favicon: "https://as.com/favicon.ico",
        country: "ES"),
    NewsSource(
        name: "Mundo Deportivo",
        rss: "https://www.mundodeportivo.com/rss",
        favicon: "https://www.mundodeportivo.com/favicon.ico",
        country: "ES"),
    NewsSource(
        name: "Sport",
        rss: "https://www.sport.es/es/rss/",
        favicon: "https://www.sport.es/favicon.ico",
        country: "ES"),
    NewsSource(
        name: "L'Equipe",
        rss: "https://www.lequipe.fr/rss.xml",
        favicon: "https://www.lequipe.fr/favicon.ico",
        country: "FR"),
    NewsSource(
        name: "Gazzetta",
        rss: "https://www.gazzetta.it/rss/",
        favicon: "https://www.gazzetta.it/favicon.ico",
        country: "IT"),
    NewsSource(
        name: "Corriere Sport",
        rss: "https://www.corrieredellosport.it/rss",
        favicon: "https://www.corrieredellosport.it/favicon.ico",
        country: "IT"),
    NewsSource(
        name: "Tuttosport",
        rss: "https://www.tuttosport.com/rss",
        favicon: "https://www.tuttosport.com/favicon.ico",
        country: "IT"),
    NewsSource(
        name: "Record",
        rss: "https://www.record.pt/rss/futebol.xml",
        favicon: "https://www.record.pt/favicon.ico",
        country: "PT"),
    NewsSource(
        name: "A Bola",
        rss: "https://www.abola.pt/rss/noticias.aspx",
        favicon: "https://www.abola.pt/favicon.ico",
        country: "PT"),
    NewsSource(
        name: "O Jogo",
        rss: "https://www.ojogo.pt/rss/futebol.xml",
        favicon: "https://www.ojogo.pt/favicon.ico",
        country: "PT"),
    NewsSource(
        name: "Bleacher Report",
        rss: "https://bleacherreport.com/articles/feed",
        favicon: "https://bleacherreport.com/favicon.ico",
        country: "USA"),
    NewsSource(
        name: "CBS Sports",
        rss: "https://www.cbssports.com/rss/headlines/soccer/",
        favicon: "https://www.cbssports.com/favicon.ico",
        country: "USA"),
    NewsSource(
        name: "Yahoo Sports",
        rss: "https://sports.yahoo.com/soccer/rss/",
        favicon: "https://sports.yahoo.com/favicon.ico",
        country: "USA"),
    NewsSource(
        name: "Mirror Football",
        rss: "https://www.mirror.co.uk/sport/football/rss.xml",
        favicon: "https://www.mirror.co.uk/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "Daily Mail",
        rss: "https://www.dailymail.co.uk/sport/football/index.rss",
        favicon: "https://www.dailymail.co.uk/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "Football Italia",
        rss: "https://football-italia.net/feed",
        favicon: "https://football-italia.net/favicon.ico",
        country: "IT"),
    NewsSource(
        name: "TeamTalk",
        rss: "https://www.teamtalk.com/feed/",
        favicon: "https://www.teamtalk.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "Football365",
        rss: "https://www.football365.com/rss",
        favicon: "https://www.football365.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "101GreatGoals",
        rss: "https://www.101greatgoals.com/feed",
        favicon: "https://www.101greatgoals.com/favicon.ico",
        country: "INT"),
    NewsSource(
        name: "CaughtOffside",
        rss: "https://caughtoffside.com/feed",
        favicon: "https://caughtoffside.com/favicon.ico",
        country: "UK"),
    NewsSource(
        name: "SoccerNews",
        rss: "https://www.soccernews.com/feed",
        favicon: "https://www.soccernews.com/favicon.ico",
        country: "INT"),
  ];

  static final List<Match> todayMatches = [
    Match(
        homeTeam: "Manchester City",
        awayTeam: "Liverpool",
        homeScore: "2",
        awayScore: "1",
        competition: "Premier League",
        time: "20:00",
        isLive: true),
    Match(
        homeTeam: "Real Madrid",
        awayTeam: "Barcelona",
        homeScore: "0",
        awayScore: "0",
        competition: "La Liga",
        time: "21:00"),
    Match(
        homeTeam: "Bayern Munich",
        awayTeam: "Borussia Dortmund",
        homeScore: "3",
        awayScore: "2",
        competition: "Bundesliga",
        time: "18:30",
        isFinished: true),
    Match(
        homeTeam: "PSG",
        awayTeam: "Marseille",
        homeScore: "-",
        awayScore: "-",
        competition: "Ligue 1",
        time: "22:00"),
    Match(
        homeTeam: "Juventus",
        awayTeam: "Inter Milan",
        homeScore: "1",
        awayScore: "1",
        competition: "Serie A",
        time: "19:45",
        isLive: true),
    Match(
        homeTeam: "Arsenal",
        awayTeam: "Chelsea",
        homeScore: "-",
        awayScore: "-",
        competition: "Premier League",
        time: "17:30"),
    Match(
        homeTeam: "Atletico Madrid",
        awayTeam: "Sevilla",
        homeScore: "2",
        awayScore: "0",
        competition: "La Liga",
        time: "16:00",
        isFinished: true),
    Match(
        homeTeam: "AC Milan",
        awayTeam: "Napoli",
        homeScore: "-",
        awayScore: "-",
        competition: "Serie A",
        time: "20:45"),
    Match(
        homeTeam: "Benfica",
        awayTeam: "Porto",
        homeScore: "1",
        awayScore: "0",
        competition: "Primeira Liga",
        time: "21:15",
        isLive: true),
    Match(
        homeTeam: "Ajax",
        awayTeam: "PSV",
        homeScore: "-",
        awayScore: "-",
        competition: "Eredivisie",
        time: "19:00"),
  ];
}

class RssService {
  final GoogleTranslator _translator = GoogleTranslator();

  Future<List<NewsArticle>> fetchArticles(NewsSource source) async {
    try {
      final response = await http
          .get(
            Uri.parse(source.rss),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        List<NewsArticle> articles = [];

        for (var item in items) {
          try {
            final title =
                item.findElements('title').first.innerText.trim();
            final link =
                item.findElements('link').first.innerText.trim();
            var description = item.findElements('description').isNotEmpty
                ? item.findElements('description').first.innerText.trim()
                : null;

            if (description != null) {
              description = _cleanHtml(description);
            }

            String? imageUrl;
            if (item.findElements('media:content').isNotEmpty) {
              imageUrl =
                  item.findElements('media:content').first.getAttribute('url');
            } else if (item.findElements('enclosure').isNotEmpty) {
              final enclosure = item.findElements('enclosure').first;
              final type = enclosure.getAttribute('type');
              if (type != null && type.startsWith('image/')) {
                imageUrl = enclosure.getAttribute('url');
              }
            } else if (item.findElements('media:thumbnail').isNotEmpty) {
              imageUrl =
                  item.findElements('media:thumbnail').first.getAttribute('url');
            }

            if (imageUrl != null) {
              imageUrl = imageUrl.trim();
              if (!imageUrl.startsWith('http')) {
                imageUrl = null;
              }
            }

            DateTime? pubDate;
            if (item.findElements('pubDate').isNotEmpty) {
              try {
                final dateStr = item.findElements('pubDate').first.innerText;
                pubDate = _parseRssDate(dateStr);
              } catch (e) {
                pubDate = DateTime.now();
              }
            } else {
              pubDate = DateTime.now();
            }

            final article = NewsArticle(
              title: title,
              description: description,
              imageUrl: imageUrl,
              link: link,
              pubDate: pubDate,
              source: source,
            );

            articles.add(article);
          } catch (e) {
            // ignore single item parse errors
            continue;
          }
        }

        return articles;
      }
    } catch (e) {
      // ignore fetch errors per-source
    }
    return [];
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime _parseRssDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // fallback common RFC format
        return HttpDate.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  Future<List<NewsArticle>> fetchAllArticles() async {
    List<NewsArticle> allArticles = [];

    final batches = _createBatches(RssSources.sources, 3);

    for (var batch in batches) {
      final results = await Future.wait(
        batch.map((source) => fetchArticles(source)),
      );

      for (var articles in results) {
        allArticles.addAll(articles);
      }

      // small throttle to avoid hammering sources
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    allArticles = allArticles.where((article) {
      if (article.pubDate == null) return false;
      return article.pubDate!.isAfter(sevenDaysAgo);
    }).toList();

    // sort newest first
    allArticles.sort((a, b) {
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allArticles;
  }

  List<List<NewsSource>> _createBatches(
      List<NewsSource> sources, int batchSize) {
    List<List<NewsSource>> batches = [];
    for (var i = 0; i < sources.length; i += batchSize) {
      batches.add(sources.sublist(
        i,
        i + batchSize > sources.length ? sources.length : i + batchSize,
      ));
    }
    return batches;
  }
}

class FootballFeedScreen extends StatefulWidget {
  const FootballFeedScreen({Key? key}) : super(key: key);

  @override
  State<FootballFeedScreen> createState() => _FootballFeedScreenState();
}

class _FootballFeedScreenState extends State<FootballFeedScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  int _selectedBottomTab = 0;
  bool _isLoading = true;
  bool _isDrawerOpen = false;
  bool _isDarkTheme = true;
  List<NewsArticle> _articles = [];
  final RssService _rssService = RssService();
  final PageController _matchesPageController = PageController();
  int _currentMatchPage = 0;

  // caches and helpers
  final Map<String, Color> _dominantColorCache = {};
  final Map<String, String> _titleTranslationCache = {};
  final Map<String, String> _descTranslationCache = {};
  final GoogleTranslator _translator = GoogleTranslator();

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
    _drawerSlideAnimation =
        Tween<double>(begin: -1.0, end: 0.0).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));
    _contentSlideAnimation =
        Tween<double>(begin: 0.0, end: 0.2).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));
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
    if (mounted) {
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
      // fast background tasks: translate and palette (concurrent batches)
      _fastTranslateTitlesAndDescriptions(_articles);
      _warmupDominantColors(_articles.take(25).toList());
    }
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
    if (_isDrawerOpen) {
      _drawerAnimationController.forward();
    } else {
      _drawerAnimationController.reverse();
    }
  }

  Color get _bgColor => _isDarkTheme ? const Color(0xFF0A0A0A) : const Color(0xFFF7F8FA);
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

  // fast batch translation with caching & concurrency control
  Future<void> _fastTranslateTitlesAndDescriptions(List<NewsArticle> articles) async {
    final toTranslate = articles.where((a) => !_titleTranslationCache.containsKey(a.link)).toList();
    const int concurrency = 6; // parallelism for speed
    for (var i = 0; i < toTranslate.length; i += concurrency) {
      final chunk = toTranslate.skip(i).take(concurrency).toList();
      final futures = <Future<void>>[];
      for (var art in chunk) {
        futures.add(_translateAndStore(art));
      }
      await Future.wait(futures);
      if (mounted) setState(() {}); // update progressively
    }
  }

  Future<void> _translateAndStore(NewsArticle art) async {
    try {
      // title
      final t = await _translator.translate(art.title, to: 'pt');
      _titleTranslationCache[art.link] = t.text;
      // description (short)
      if ((art.description ?? '').isNotEmpty) {
        final d = await _translator.translate(art.description!, to: 'pt');
        _descTranslationCache[art.link] = d.text;
      }
    } catch (e) {
      // ignore translate errors silently
    }
  }

  // palette warmup (compute dominant color for top N images)
  Future<void> _warmupDominantColors(List<NewsArticle> articles) async {
    for (var art in articles) {
      if (art.imageUrl != null && !_dominantColorCache.containsKey(art.link)) {
        _computeDominantColor(art);
      }
    }
  }

  Future<void> _computeDominantColor(NewsArticle art) async {
    try {
      final provider = CachedNetworkImageProvider(art.imageUrl!);
      final palette = await PaletteGenerator.fromImageProvider(provider, maximumColorCount: 6);
      final color = palette.dominantColor?.color ?? Colors.grey.shade800;
      _dominantColorCache[art.link] = color;
      if (mounted) setState(() {});
    } catch (e) {
      // ignore
    }
  }

  String _translatedTitle(NewsArticle a) {
    return _titleTranslationCache[a.link] ?? a.title;
  }

  String _translatedDesc(NewsArticle a) {
    return _descTranslationCache[a.link] ?? (a.description ?? '');
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
                            const SizedBox(height: 72), // leave space for bottom nav (drawer will overlay)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // bottom nav positioned so drawer overlays it (drawer will be above this in stack)
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
                color: Colors.black.withOpacity(0.5),
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
            // header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _borderColor),
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
                  Icon(_isDarkTheme ? Ionicons.moon : Ionicons.sunny, color: _textColor, size: 24),
                  const SizedBox(width: 16),
                  Expanded(child: Text(_isDarkTheme ? 'Modo Escuro' : 'Modo Claro', style: TextStyle(fontSize: 16, color: _textColor))),
                  GestureDetector(
                    onTap: () => setState(() => _isDarkTheme = !_isDarkTheme),
                    child: Container(
                      width: 51,
                      height: 31,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _isDarkTheme ? const Color(0xFF2374E1) : const Color(0xFFE4E6EB)),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: _isDarkTheme ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(width: 27, height: 27, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
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
                  _buildDrawerItem(Ionicons.translate_outline, 'Traduzir (rápido)', () async {
                    await _fastTranslateTitlesAndDescriptions(_articles.take(30).toList());
                  }),
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
      child: Center(child: Text(title, style: TextStyle(fontSize: 18, color: _subTextColor))),
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: _borderColor),
                child: Center(
                  child: SvgPicture.string(SvgIcons.profileFilled, width: 18, height: 18, colorFilter: ColorFilter.mode(_textColor, BlendMode.srcIn)),
                ),
              ),
            ),
            Image.asset('assets/logo.png', width: 32, height: 32, errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFF2374E1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Ionicons.football, color: Colors.white, size: 20),
              );
            }),
            GestureDetector(onTap: () {}, child: SvgPicture.string(SvgIcons.search, width: 24, height: 24)),
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
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? _textColor : _subTextColor)),
          const SizedBox(height: 10),
          Container(height: 3, width: 40, decoration: BoxDecoration(color: isActive ? const Color(0xFF2374E1) : Colors.transparent, borderRadius: BorderRadius.circular(1.5))),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoading) {
      return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), itemCount: 5, itemBuilder: (context, index) => _buildSkeletonPost());
    }

    final filteredArticles = _filteredArticles;

    if (filteredArticles.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Ionicons.newspaper_outline, size: 64, color: _borderColor),
          const SizedBox(height: 16),
          Text('Nenhuma noticia disponivel', style: TextStyle(fontSize: 15, color: _subTextColor)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadContent, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2374E1)), child: const Text('Tentar novamente')),
        ]),
      );
    }

    final highQualityArticles = filteredArticles.where((a) => a.hasHighQualityImage).toList();
    final lowQualityArticles = filteredArticles.where((a) => a.hasImage && !a.hasHighQualityImage).toList();
    final noImageArticles = filteredArticles.where((a) => !a.hasImage).toList();

    return ListView.builder(
      key: ValueKey('feed-$_selectedTab'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 1 + highQualityArticles.length + ((lowQualityArticles.isNotEmpty && highQualityArticles.length > 3) ? 1 : 0) + ((noImageArticles.isNotEmpty && highQualityArticles.length > 6) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(children: [ _buildMatchesCard(), const SizedBox(height: 16) ]);
        }

        final adjustedIndex = index - 1;

        if (adjustedIndex == 3 && lowQualityArticles.isNotEmpty) {
          return Column(children: [ _buildLowQualityNewsGrid(lowQualityArticles.take(4).toList()), const SizedBox(height: 12) ]);
        }

        if (adjustedIndex == 6 && noImageArticles.isNotEmpty) {
          return Column(children: [ _buildHorizontalNewsList(noImageArticles.take(10).toList()), const SizedBox(height: 12) ]);
        }

        int articleIndex = adjustedIndex;
        if (adjustedIndex > 3 && lowQualityArticles.isNotEmpty) articleIndex--;
        if (adjustedIndex > 6 && noImageArticles.isNotEmpty) articleIndex--;

        if (articleIndex < highQualityArticles.length) {
          return Column(children: [ _buildNewsCard(highQualityArticles[articleIndex]), const SizedBox(height: 12) ]);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMatchesCard() {
    final matches = RssSources.todayMatches;

    return Container(
      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,2)) ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [ Icon(Ionicons.football_outline, size: 18, color: _textColor), const SizedBox(width: 8), Text('Jogos de Hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor)) ])),
        SizedBox(height: 140, child: PageView.builder(controller: _matchesPageController, onPageChanged: (i) => setState(() => _currentMatchPage = i), itemCount: matches.length, itemBuilder: (c, i) => _buildMatchItem(matches[i]))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(matches.length > 10 ? 10 : matches.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentMatchPage == i ? const Color(0xFF2374E1) : _borderColor)))),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildMatchItem(Match match) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: match.isLive ? Colors.red.withOpacity(0.1) : _borderColor.withOpacity(0.3), borderRadius: BorderRadius.circular(4)), child: Text(match.isLive ? 'AO VIVO' : match.competition, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: match.isLive ? Colors.red : _subTextColor))),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(child: Text(match.homeTeam, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor), textAlign: TextAlign.center, maxLines: 2)),
        const SizedBox(width: 20),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: _borderColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)), child: Text('${match.homeScore} - ${match.awayScore}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColor))),
        const SizedBox(width: 20),
        Expanded(child: Text(match.awayTeam, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor), textAlign: TextAlign.center, maxLines: 2)),
      ]),
      const SizedBox(height: 8),
      Text(match.isFinished ? 'FT' : match.time, style: TextStyle(fontSize: 12, color: _subTextColor)),
    ]));
  }

  Widget _buildLowQualityNewsGrid(List<NewsArticle> articles) {
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85), itemCount: articles.length > 4 ? 4 : articles.length, itemBuilder: (context, index) => _buildSmallNewsCard(articles[index]));
  }

  Widget _buildSmallNewsCard(NewsArticle article) {
    final cardColor = _dominantColorCache[article.link] ?? (_isDarkTheme ? const Color(0xFF222225) : const Color(0xFFF1F5F9));
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(
        decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,2)) ], border: Border.all(color: _borderColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (article.hasImage)
            Stack(children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: CachedNetworkImage(imageUrl: article.imageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover, httpHeaders: {'User-Agent': 'Mozilla/5.0'}, placeholder: (c,u) => Container(height: 100, color: _borderColor), errorWidget: (c,u,e) => Container(height: 100, color: _borderColor, child: Icon(Ionicons.image_outline, color: _subTextColor)))),
              Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cardColor.withOpacity(0.10), cardColor.withOpacity(0.28)])))),
            ]),
          Expanded(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _borderColor.withOpacity(0.5)), child: ClipOval(child: CachedNetworkImage(imageUrl: article.source.favicon, width: 20, height: 20, fit: BoxFit.cover, httpHeaders: {'User-Agent': 'Mozilla/5.0'}, errorWidget: (c,u,e) => Icon(Ionicons.globe_outline, size: 12, color: _subTextColor)))),
              const SizedBox(width: 8),
              Expanded(child: Text(article.source.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _subTextColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Expanded(child: Text(_translatedTitle(article), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, color: _textColor), maxLines: 3, overflow: TextOverflow.ellipsis)),
          ]))),
        ]),
      ),
    );
  }

  Widget _buildHorizontalNewsList(List<NewsArticle> articles) {
    return Container(height: 140, child: ListView.builder(scrollDirection: Axis.horizontal, padding: EdgeInsets.zero, itemCount: articles.length, itemBuilder: (context, index) => _buildCompactNewsCard(articles[index])));
  }

  Widget _buildCompactNewsCard(NewsArticle article) {
    final cardColor = _dominantColorCache[article.link] ?? (_isDarkTheme ? const Color(0xFF222225) : const Color(0xFFF1F5F9));
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(width: 200, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,2)) ]), padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: _borderColor), child: ClipOval(child: CachedNetworkImage(imageUrl: article.source.favicon, width: 16, height: 16, fit: BoxFit.cover, httpHeaders: {'User-Agent': 'Mozilla/5.0'}, errorWidget: (c,u,e) => Icon(Ionicons.globe_outline, size: 10, color: _subTextColor)))),
          const SizedBox(width: 6),
          Expanded(child: Text(article.source.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _subTextColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Expanded(child: Text(_translatedTitle(article), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: _textColor), maxLines: 4, overflow: TextOverflow.ellipsis)),
        if (article.pubDate != null) ...[ const SizedBox(height: 4), Text(_formatTime(article.pubDate!), style: TextStyle(fontSize: 11, color: _subTextColor)) ],
      ])),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    final primaryColor = _dominantColorCache[article.link] ?? (_isDarkTheme ? const Color(0xFF222225) : const Color(0xFFF1F5F9));
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,2)) ], border: Border.all(color: _borderColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (article.hasImage)
          Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: CachedNetworkImage(imageUrl: article.imageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover, httpHeaders: {'User-Agent': 'Mozilla/5.0'}, placeholder: (c,u) => Container(height: 220, color: _borderColor, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2374E1)) ))), errorWidget: (c,u,e) => Container(height: 220, color: _borderColor, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Ionicons.image_outline, size: 48, color: _subTextColor), const SizedBox(height: 8), Text('Imagem indisponivel', style: TextStyle(fontSize: 12, color: _subTextColor)) ])))),
            // separation gradient: top more transparent, bottom stronger
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 10, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ primaryColor.withOpacity(0.06), primaryColor.withOpacity(0.32) ])))),
          ]),
        // separator line (stronger at bottom)
        Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ primaryColor.withOpacity(0.08), primaryColor.withOpacity(0.28) ]))),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _borderColor.withOpacity(0.5)), child: ClipOval(child: CachedNetworkImage(imageUrl: article.source.favicon, width: 20, height: 20, fit: BoxFit.cover, httpHeaders: {'User-Agent': 'Mozilla/5.0'}, errorWidget: (c,u,e) => Icon(Ionicons.globe_outline, size: 12, color: _subTextColor)))),
            const SizedBox(width: 8),
            Text(article.source.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subTextColor)),
            if (article.pubDate != null) ...[ const SizedBox(width: 6), Text('·', style: TextStyle(color: _subTextColor)), const SizedBox(width: 6), Text(_formatTime(article.pubDate!), style: TextStyle(fontSize: 12, color: _subTextColor)) ],
          ]),
          const SizedBox(height: 8),
          Text(_translatedTitle(article), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: _textColor)),
          if (article.description != null && article.description!.isNotEmpty) ...[ const SizedBox(height: 8), Text(_translatedDesc(article), style: TextStyle(fontSize: 14, height: 1.4, color: _subTextColor), maxLines: 2, overflow: TextOverflow.ellipsis) ],
        ])),
      ])),
    );
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
      // ignore
    }
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildShimmer(child: Container(width: 150, height: 12, decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(6)))),
        const SizedBox(height: 12),
        _buildShimmer(child: Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(12)))),
      ]),
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return TweenAnimationBuilder<double>(tween: Tween(begin: 0.3, end: 1.0), duration: const Duration(milliseconds: 1000), builder: (context, value, child) => Opacity(opacity: value, child: child), onEnd: () { Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() {}); }); }, child: child);
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(color: _surfaceColor, border: Border(top: BorderSide(color: _borderColor, width: 0.5))),
      child: SafeArea(
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildBottomNavItem(SvgIcons.homeOutline, SvgIcons.homeFilled, 'Inicio', 0),
          _buildBottomNavItem(SvgIcons.matchesOutline, SvgIcons.matchesFilled, 'Partidas', 1),
          _buildBottomNavItem('<svg .../>', '<svg .../>', 'TV', 2),
        ])),
      ),
    );
  }

  Widget _buildBottomNavItem(String outlinedSvg, String filledSvg, String label, int index) {
    final isSelected = _selectedBottomTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomTab = index;
          if (index == 0 && _articles.isEmpty) {
            _loadContent();
          }
        });
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.string(isSelected ? filledSvg : outlinedSvg, width: 22, height: 22, colorFilter: ColorFilter.mode(isSelected ? const Color(0xFF2374E1) : _subTextColor, BlendMode.srcIn)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFF2374E1) : _subTextColor)),
      ]),
    );
  }
}