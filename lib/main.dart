import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'svg_icons.dart';
import 'dart:convert';

void main() => runApp(const FootballFeedApp());

class FootballFeedApp extends StatelessWidget {
  const FootballFeedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Feed',
      theme: ThemeData(
        fontFamily: '-apple-system',
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF2374E1),
          secondary: Color(0xFF2374E1),
          background: Color(0xFF0A0A0A),
          surface: Color(0xFF1A1A1A),
        ),
        scaffoldBackgroundColor: Color(0xFF0A0A0A),
      ),
      home: const FootballFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NewsSource {
  final String name;
  final String rss;
  final String? logo;
  final String? country;
  final String svgIcon;

  NewsSource({required this.name, required this.rss, this.logo, this.country, required this.svgIcon});
}

class NewsArticle {
  final String title;
  final String? description;
  final String? imageUrl;
  final String link;
  final DateTime? pubDate;
  final NewsSource source;

  NewsArticle({required this.title, this.description, this.imageUrl, required this.link, this.pubDate, required this.source});

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isHighQuality => imageUrl != null && imageUrl!.contains('1200') || imageUrl!.contains('high') || imageUrl!.contains('large');
}

class Match {
  final String homeTeam;
  final String awayTeam;
  final String homeScore;
  final String awayScore;
  final String time;
  final String competition;
  final bool isLive;

  Match({required this.homeTeam, required this.awayTeam, required this.homeScore, required this.awayScore, required this.time, required this.competition, this.isLive = false});
}

class RssSources {
  static final List<NewsSource> sources = [
    NewsSource(name: "BBC Sport", rss: "https://feeds.bbci.co.uk/sport/football/rss.xml", country: "UK", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#fff" width="24" height="24"/><text x="12" y="16" font-size="10" text-anchor="middle" fill="#000" font-weight="bold">BBC</text></svg>'),
    NewsSource(name: "Sky Sports", rss: "https://www.skysports.com/rss/12040", country: "UK", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#00AEEF" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">SKY</text></svg>'),
    NewsSource(name: "The Guardian", rss: "https://www.theguardian.com/football/rss", country: "UK", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#052962" width="24" height="24"/><text x="12" y="16" font-size="10" text-anchor="middle" fill="#fff" font-weight="bold">G</text></svg>'),
    NewsSource(name: "ESPN", rss: "https://www.espn.com/espn/rss/soccer/news", country: "USA", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#D2122E" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">ESPN</text></svg>'),
    NewsSource(name: "Goal", rss: "https://www.goal.com/feeds/en/news", country: "INT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#00B2A9" width="24" height="24"/><text x="12" y="16" font-size="10" text-anchor="middle" fill="#fff" font-weight="bold">G</text></svg>'),
    NewsSource(name: "90min", rss: "https://90min.com/posts.rss", country: "INT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#FF6B00" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">90m</text></svg>'),
    NewsSource(name: "FourFourTwo", rss: "https://www.fourfourtwo.com/rss", country: "UK", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#E41B23" width="24" height="24"/><text x="12" y="16" font-size="7" text-anchor="middle" fill="#fff" font-weight="bold">442</text></svg>'),
    NewsSource(name: "GloboEsporte", rss: "https://ge.globo.com/rss/ge/futebol/", country: "BR", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#0080C6" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">GE</text></svg>'),
    NewsSource(name: "Marca", rss: "https://e00-marca.uecdn.es/rss/en/international.xml", country: "ES", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#DA291C" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">M</text></svg>'),
    NewsSource(name: "AS", rss: "https://as.com/rss/futbol/portada.xml", country: "ES", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#FFED00" width="24" height="24"/><text x="12" y="16" font-size="10" text-anchor="middle" fill="#000" font-weight="bold">AS</text></svg>'),
    NewsSource(name: "Transfermarkt", rss: "https://www.transfermarkt.com/rss/news", country: "INT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#1A4D2E" width="24" height="24"/><text x="12" y="16" font-size="7" text-anchor="middle" fill="#fff" font-weight="bold">TM</text></svg>'),
    NewsSource(name: "Sport", rss: "https://www.sport.es/es/rss/futbol/rss.xml", country: "ES", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#0066CC" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">SPT</text></svg>'),
    NewsSource(name: "L'Equipe", rss: "https://www.lequipe.fr/rss/actu_rss_Football.xml", country: "FR", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#00A650" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">LEQ</text></svg>'),
    NewsSource(name: "Gazzetta", rss: "https://www.gazzetta.it/rss/calcio.xml", country: "IT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#FF69B4" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">GZ</text></svg>'),
    NewsSource(name: "Kicker", rss: "https://www.kicker.de/rss/news", country: "DE", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#E2001A" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">KK</text></svg>'),
    NewsSource(name: "O Jogo", rss: "https://www.ojogo.pt/rss.xml", country: "PT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#006FB8" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">OJ</text></svg>'),
    NewsSource(name: "Record", rss: "https://www.record.pt/rss.xml", country: "PT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#D71920" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">REC</text></svg>'),
    NewsSource(name: "A Bola", rss: "https://www.abola.pt/rss.xml", country: "PT", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#FDB913" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#000" font-weight="bold">AB</text></svg>'),
    NewsSource(name: "talkSPORT", rss: "https://talksport.com/football/rss/", country: "UK", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#EB1D36" width="24" height="24"/><text x="12" y="16" font-size="7" text-anchor="middle" fill="#fff" font-weight="bold">tS</text></svg>'),
    NewsSource(name: "The Athletic", rss: "https://theathletic.com/feed/", country: "USA", svgIcon: '<svg viewBox="0 0 24 24"><rect fill="#FF4400" width="24" height="24"/><text x="12" y="16" font-size="8" text-anchor="middle" fill="#fff" font-weight="bold">ATH</text></svg>'),
  ];
}

class MatchData {
  static final String jsonMatches = '''
{
  "matches": [
    {"homeTeam": "Real Madrid", "awayTeam": "Barcelona", "homeScore": "2", "awayScore": "1", "time": "Hoje 21:00", "competition": "La Liga", "isLive": false},
    {"homeTeam": "Man City", "awayTeam": "Liverpool", "homeScore": "1", "awayScore": "1", "time": "AO VIVO", "competition": "Premier League", "isLive": true},
    {"homeTeam": "Bayern", "awayTeam": "Dortmund", "homeScore": "3", "awayScore": "2", "time": "Finalizado", "competition": "Bundesliga", "isLive": false},
    {"homeTeam": "PSG", "awayTeam": "Marseille", "homeScore": "-", "awayScore": "-", "time": "Amanhã 16:00", "competition": "Ligue 1", "isLive": false},
    {"homeTeam": "Juventus", "awayTeam": "Inter", "homeScore": "-", "awayScore": "-", "time": "Sábado 18:30", "competition": "Serie A", "isLive": false},
    {"homeTeam": "Arsenal", "awayTeam": "Chelsea", "homeScore": "0", "awayScore": "0", "time": "AO VIVO", "competition": "Premier League", "isLive": true},
    {"homeTeam": "Atlético", "awayTeam": "Sevilla", "homeScore": "-", "awayScore": "-", "time": "Domingo 20:00", "competition": "La Liga", "isLive": false},
    {"homeTeam": "Benfica", "awayTeam": "Porto", "homeScore": "2", "awayScore": "0", "time": "Finalizado", "competition": "Primeira Liga", "isLive": false},
    {"homeTeam": "Milan", "awayTeam": "Napoli", "homeScore": "-", "awayScore": "-", "time": "Sábado 19:45", "competition": "Serie A", "isLive": false},
    {"homeTeam": "Ajax", "awayTeam": "Feyenoord", "homeScore": "1", "awayScore": "3", "time": "Finalizado", "competition": "Eredivisie", "isLive": false}
  ]
}
''';

  static List<Match> getMatches() {
    final data = json.decode(jsonMatches);
    return (data['matches'] as List).map((m) => Match(
      homeTeam: m['homeTeam'],
      awayTeam: m['awayTeam'],
      homeScore: m['homeScore'],
      awayScore: m['awayScore'],
      time: m['time'],
      competition: m['competition'],
      isLive: m['isLive'],
    )).toList();
  }
}

class RssService {
  Future<List<NewsArticle>> fetchArticles(NewsSource source) async {
    try {
      final response = await http.get(Uri.parse(source.rss), headers: {'User-Agent': 'FootballFeedApp/1.0'}).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        return items.map((item) {
          final title = item.findElements('title').first.innerText;
          final link = item.findElements('link').first.innerText;
          final description = item.findElements('description').isNotEmpty ? item.findElements('description').first.innerText : null;

          String? imageUrl;
          if (item.findElements('media:content').isNotEmpty) {
            imageUrl = item.findElements('media:content').first.getAttribute('url');
          } else if (item.findElements('enclosure').isNotEmpty) {
            final enclosure = item.findElements('enclosure').first;
            final type = enclosure.getAttribute('type');
            if (type != null && type.startsWith('image/')) imageUrl = enclosure.getAttribute('url');
          } else if (item.findElements('media:thumbnail').isNotEmpty) {
            imageUrl = item.findElements('media:thumbnail').first.getAttribute('url');
          }

          if (imageUrl != null) {
            imageUrl = imageUrl.trim();
            if (!imageUrl.startsWith('http')) imageUrl = null;
          }

          DateTime? pubDate;
          if (item.findElements('pubDate').isNotEmpty) {
            try {
              pubDate = DateTime.parse(item.findElements('pubDate').first.innerText);
            } catch (e) {}
          }

          return NewsArticle(title: title, description: description, imageUrl: imageUrl, link: link, pubDate: pubDate, source: source);
        }).toList();
      }
    } catch (e) {
      print('Error fetching ${source.name}: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> fetchAllArticles() async {
    List<NewsArticle> allArticles = [];
    final batches = _createBatches(RssSources.sources, 10);
    for (var batch in batches) {
      final results = await Future.wait(batch.map((source) => fetchArticles(source)));
      for (var articles in results) allArticles.addAll(articles);
    }

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    allArticles = allArticles.where((a) => a.pubDate == null || a.pubDate!.isAfter(sevenDaysAgo)).toList();

    allArticles.sort((a, b) {
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allArticles;
  }

  List<List<NewsSource>> _createBatches(List<NewsSource> sources, int batchSize) {
    List<List<NewsSource>> batches = [];
    for (var i = 0; i < sources.length; i += batchSize) {
      batches.add(sources.sublist(i, i + batchSize > sources.length ? sources.length : i + batchSize));
    }
    return batches;
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
  final List<Match> _matches = MatchData.getMatches();
  int _currentMatchIndex = 0;

  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _drawerAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _drawerSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut));
    _contentSlideAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
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

  Color get _bgColor => _isDarkTheme ? Color(0xFF0A0A0A) : Color(0xFFF0F2F5);
  Color get _surfaceColor => _isDarkTheme ? Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _isDarkTheme ? Color(0xFFE4E6EB) : Color(0xFF050505);
  Color get _subTextColor => _isDarkTheme ? Color(0xFFB0B3B8) : Color(0xFF65676B);
  Color get _borderColor => _isDarkTheme ? Color(0xFF3A3B3C) : Color(0xFFDDDFE2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
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
                    child: AbsorbPointer(
                      absorbing: _isDrawerOpen,
                      child: Container(
                        color: _bgColor,
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              _buildHeader(),
                              Expanded(child: _buildCurrentTab()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _drawerSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width * _drawerSlideAnimation.value, 0),
                child: _buildDrawer(),
              );
            },
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _contentSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(MediaQuery.of(context).size.width * _contentSlideAnimation.value, 0),
            child: _buildBottomNavBar(),
          );
        },
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
                  Icon(_isDarkTheme ? Ionicons.moon : Ionicons.sunny, color: _textColor, size: 24),
                  SizedBox(width: 16),
                  Expanded(child: Text(_isDarkTheme ? 'Modo Escuro' : 'Modo Claro', style: TextStyle(fontSize: 16, color: _textColor))),
                  GestureDetector(
                    onTap: () => setState(() => _isDarkTheme = !_isDarkTheme),
                    child: Container(
                      width: 51,
                      height: 31,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _isDarkTheme ? Color(0xFF2374E1) : Color(0xFFE4E6EB)),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: _isDarkTheme ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(width: 27, height: 27, margin: EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _borderColor),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(Ionicons.refresh_outline, 'Atualizar Feed', () {
                    _toggleDrawer();
                    _loadContent();
                  }),
                  _buildDrawerItem(Ionicons.globe_outline, 'Todas as Fontes', () {}),
                  _buildDrawerItem(Ionicons.star_outline, 'Favoritos', () {}),
                  _buildDrawerItem(Ionicons.settings_outline, 'Configurações', () {}),
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
      return _selectedTab == 0 ? _buildParaVoceTab() : (_selectedTab == 1 ? _buildTopNewsTab() : _buildMercadoTab());
    } else if (_selectedBottomTab == 1) {
      return _buildEmptyTab('Partidas');
    } else {
      return _buildEmptyTab('Perfil');
    }
  }

  Widget _buildEmptyTab(String title) {
    return Container(key: ValueKey(title), color: _bgColor);
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(bottom: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _toggleDrawer,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Color(0xFF2374E1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Ionicons.football, color: Colors.white, size: 20),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopTabButton('Para você', 0),
                    const SizedBox(width: 16),
                    _buildTopTabButton('Top News', 1),
                    const SizedBox(width: 16),
                    _buildTopTabButton('Mercado', 2),
                  ],
                ),
                GestureDetector(
                  onTap: () {},
                  child: Icon(Ionicons.search, color: _textColor, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabButton(String text, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          if (index == 0) {
            _isLoading = true;
            _loadContent();
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? _textColor : _subTextColor)),
          const SizedBox(height: 8),
          Container(height: 3, width: 35, decoration: BoxDecoration(color: isActive ? Color(0xFF2374E1) : Colors.transparent, borderRadius: BorderRadius.circular(1.5))),
        ],
      ),
    );
  }

  Widget _buildParaVoceTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonPost(),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.newspaper_outline, size: 64, color: _borderColor),
            SizedBox(height: 16),
            Text('Nenhuma notícia disponível', style: TextStyle(fontSize: 15, color: _subTextColor)),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadContent, child: Text('Tentar novamente')),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('para-voce'),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _articles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildMatchesCard(),
              SizedBox(height: 12),
            ],
          );
        }

        final articleIndex = index - 1;
        final article = _articles[articleIndex];

        return Column(
          children: [
            article.hasImage && article.isHighQuality
                ? _buildNewsCard(article)
                : _buildCompactNewsCardVertical(article),
            SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildMatchesCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Ionicons.trophy, color: Color(0xFF2374E1), size: 20),
                SizedBox(width: 8),
                Text('Jogos de Hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor)),
              ],
            ),
          ),
          Container(
            height: 160,
            child: PageView.builder(
              itemCount: _matches.length,
              onPageChanged: (index) => setState(() => _currentMatchIndex = index),
              itemBuilder: (context, index) {
                final match = _matches[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: match.isLive ? Colors.red : _borderColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(match.isLive ? 'AO VIVO' : match.competition, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: Text(match.homeTeam, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor))),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(8)),
                            child: Text('${match.homeScore}  -  ${match.awayScore}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                          ),
                          Expanded(child: Text(match.awayTeam, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor))),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(match.time, style: TextStyle(fontSize: 12, color: _subTextColor)),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_matches.length, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: _currentMatchIndex == index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentMatchIndex == index ? Color(0xFF2374E1) : _borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopNewsTab() {
    return Center(child: Text('Top News', style: TextStyle(color: _textColor)));
  }

  Widget _buildMercadoTab() {
    return Center(child: Text('Mercado', style: TextStyle(color: _textColor)));
  }

  Widget _buildCompactNewsCardVertical(NewsArticle article) {
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
        ),
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              child: SvgPicture.string(article.source.svgIcon, fit: BoxFit.contain),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.source.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _subTextColor)),
                  SizedBox(height: 4),
                  Text(article.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: _textColor), maxLines: 3, overflow: TextOverflow.ellipsis),
                  if (article.pubDate != null) ...[
                    SizedBox(height: 4),
                    Text(_formatTime(article.pubDate!), style: TextStyle(fontSize: 10, color: _subTextColor)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => _launchUrl(article.link),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  httpHeaders: {'User-Agent': 'FootballFeedApp/1.0'},
                  placeholder: (context, url) => Container(height: 200, color: _borderColor, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2374E1))))),
                  errorWidget: (context, url, error) => Container(height: 200, color: _borderColor, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Ionicons.image_outline, size: 48, color: _subTextColor), SizedBox(height: 8), Text('Imagem indisponível', style: TextStyle(fontSize: 12, color: _subTextColor))])),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 16, height: 16, child: SvgPicture.string(article.source.svgIcon, fit: BoxFit.contain)),
                      SizedBox(width: 6),
                      Text(article.source.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subTextColor)),
                      if (article.pubDate != null) ...[
                        Text(' · ', style: TextStyle(color: _subTextColor)),
                        Text(_formatTime(article.pubDate!), style: TextStyle(fontSize: 12, color: _subTextColor)),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(article.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: _textColor)),
                  if (article.description != null && article.description!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(article.description!, style: TextStyle(fontSize: 14, height: 1.4, color: _subTextColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(child: Container(width: 150, height: 12, decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(6)))),
          const SizedBox(height: 12),
          _buildShimmer(child: Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(12)))),
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
      decoration: BoxDecoration(color: _surfaceColor, border: Border(top: BorderSide(color: _borderColor, width: 0.5))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(SvgIcons.homeOutline, SvgIcons.homeFilled, 'Início', 0),
              _buildBottomNavItem(SvgIcons.matchesOutline, SvgIcons.matchesFilled, 'Partidas', 1),
              _buildBottomNavItem(SvgIcons.profileOutline, SvgIcons.profileFilled, 'Perfil', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(String outlinedSvg, String filledSvg, String label, int index) {
    final isSelected = _selectedBottomTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomTab = index;
          if (index == 0) {
            _isLoading = true;
            _loadContent();
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(isSelected ? filledSvg : outlinedSvg, width: 22, height: 22, colorFilter: ColorFilter.mode(isSelected ? Color(0xFF2374E1) : _subTextColor, BlendMode.srcIn)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? Color(0xFF2374E1) : _subTextColor)),
        ],
      ),
    );
  }
}