import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ionicons/ionicons.dart';

// ==== PARTE 1: main.dart ====
// Este arquivo contém o app principal e a configuração

void main() {
  runApp(const SocialFeedApp());
}

class SocialFeedApp extends StatelessWidget {
  const SocialFeedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feed Futebol',
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
      home: const SocialFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==== MODELOS ====

class NewsItem {
  final String title;
  final String link;
  final String? description;
  final String? thumbnail;
  final String source;
  final DateTime? pubDate;
  final String sourceLogo;

  NewsItem({
    required this.title,
    required this.link,
    this.description,
    this.thumbnail,
    required this.source,
    this.pubDate,
    required this.sourceLogo,
  });

  bool get hasImage => thumbnail != null && thumbnail!.isNotEmpty;
}

class RssFeed {
  final String name;
  final String url;
  final String logo;

  RssFeed({required this.name, required this.url, required this.logo});
}

// ==== LISTA DE FEEDS (60+ fontes) ====

final List<RssFeed> RSS_FEEDS = [
  // Portugueses
  RssFeed(name: "ZeroZero", url: "https://www.zerozero.pt/rss/noticias.php", logo: "⚽"),
  RssFeed(name: "O Jogo", url: "https://www.ojogo.pt/rss", logo: "📰"),
  RssFeed(name: "Bola na Rede", url: "https://www.bolanarede.pt/feed/", logo: "⚽"),
  RssFeed(name: "MaisFutebol", url: "https://www.maisfutebol.iol.pt/rss", logo: "⚽"),
  RssFeed(name: "Record", url: "https://www.record.pt/rss.aspx", logo: "📰"),
  RssFeed(name: "A Bola", url: "https://www.abola.pt/rss", logo: "⚽"),
  RssFeed(name: "Tribuna Expresso", url: "https://expresso.pt/rss", logo: "📰"),
  
  // Brasileiros
  RssFeed(name: "GE Globo", url: "https://ge.globo.com/rss/ge/futebol/", logo: "🇧🇷"),
  RssFeed(name: "UOL Esporte", url: "https://rss.uol.com.br/feed/esporte.xml", logo: "📰"),
  RssFeed(name: "Lance", url: "https://www.lance.com.br/rss.xml", logo: "⚽"),
  RssFeed(name: "ESPN Brasil", url: "https://www.espn.com.br/feeds/rss/news", logo: "📺"),
  RssFeed(name: "Trivela", url: "https://trivela.com.br/feed/", logo: "⚽"),
  RssFeed(name: "TNT Sports", url: "https://www.tntsports.com.br/rss", logo: "📺"),
  
  // Internacionais - Inglês
  RssFeed(name: "BBC Sport", url: "https://feeds.bbci.co.uk/sport/football/rss.xml", logo: "🇬🇧"),
  RssFeed(name: "Sky Sports", url: "https://www.skysports.com/rss/12040", logo: "📺"),
  RssFeed(name: "The Guardian", url: "https://www.theguardian.com/football/rss", logo: "📰"),
  RssFeed(name: "Goal.com", url: "https://www.goal.com/feeds/en/news", logo: "⚽"),
  RssFeed(name: "90min", url: "https://90min.com/posts.rss", logo: "⚽"),
  RssFeed(name: "ESPN FC", url: "https://www.espn.com/espn/rss/soccer/news", logo: "📺"),
  RssFeed(name: "FourFourTwo", url: "https://www.fourfourtwo.com/rss", logo: "📰"),
  RssFeed(name: "Football365", url: "https://www.football365.com/rss", logo: "⚽"),
  RssFeed(name: "TeamTalk", url: "https://www.teamtalk.com/feed/", logo: "⚽"),
  RssFeed(name: "Mirror Football", url: "https://www.mirror.co.uk/sport/football/rss.xml", logo: "📰"),
  RssFeed(name: "The Sun Football", url: "https://www.thesun.co.uk/sport/football/feed/", logo: "📰"),
  RssFeed(name: "Daily Mail Sport", url: "https://www.dailymail.co.uk/sport/football/index.rss", logo: "📰"),
  RssFeed(name: "CaughtOffside", url: "https://caughtoffside.com/feed", logo: "⚽"),
  RssFeed(name: "101GreatGoals", url: "https://www.101greatgoals.com/feed", logo: "⚽"),
  RssFeed(name: "Bleacher Report", url: "https://bleacherreport.com/articles/feed", logo: "📰"),
  RssFeed(name: "CBS Sports", url: "https://www.cbssports.com/rss/headlines/soccer/", logo: "📺"),
  
  // Italianos
  RssFeed(name: "Gazzetta dello Sport", url: "https://www.gazzetta.it/rss/", logo: "🇮🇹"),
  RssFeed(name: "Corriere dello Sport", url: "https://www.corrieredellosport.it/rss", logo: "📰"),
  RssFeed(name: "Tuttosport", url: "https://www.tuttosport.com/rss", logo: "📰"),
  RssFeed(name: "Football Italia", url: "https://football-italia.net/feed", logo: "🇮🇹"),
  
  // Espanhóis
  RssFeed(name: "Marca", url: "https://www.marca.com/rss", logo: "🇪🇸"),
  RssFeed(name: "AS", url: "https://as.com/rss", logo: "🇪🇸"),
  RssFeed(name: "Mundo Deportivo", url: "https://www.mundodeportivo.com/rss", logo: "📰"),
  RssFeed(name: "Sport", url: "https://www.sport.es/es/rss/", logo: "📰"),
  
  // Francês
  RssFeed(name: "L'Equipe", url: "https://www.lequipe.fr/rss.xml", logo: "🇫🇷"),
  
  // Alemão
  RssFeed(name: "Kicker", url: "https://www.kicker.de/news/rss", logo: "🇩🇪"),
  RssFeed(name: "Sport1", url: "https://www.sport1.de/fussball/rss", logo: "📰"),
  
  // Clubes Oficiais
  RssFeed(name: "Man United", url: "https://www.manutd.com/Feeds/News?format=xml", logo: "🔴"),
  RssFeed(name: "Liverpool FC", url: "https://www.liverpoolfc.com/news/rss", logo: "🔴"),
  RssFeed(name: "Chelsea FC", url: "https://www.chelseafc.com/en/news/rss", logo: "🔵"),
  RssFeed(name: "Arsenal", url: "https://www.arsenal.com/rss.xml", logo: "🔴"),
  RssFeed(name: "Man City", url: "https://www.mancity.com/feeds/news", logo: "🔵"),
  RssFeed(name: "Tottenham", url: "https://www.tottenhamhotspur.com/rss/", logo: "⚪"),
  RssFeed(name: "Real Madrid (fan)", url: "https://www.managingmadrid.com/feed/", logo: "⚪"),
  RssFeed(name: "Barcelona (fan)", url: "https://www.barcablaugranes.com/feed/", logo: "🔴"),
  
  // Outras fontes
  RssFeed(name: "Transfermarkt", url: "https://www.transfermarkt.com/rss/news/", logo: "💰"),
  RssFeed(name: "MLS Soccer", url: "https://www.mlssoccer.com/rss", logo: "🇺🇸"),
  RssFeed(name: "OneFootball", url: "https://onefootball.com/en/rss", logo: "⚽"),
  RssFeed(name: "World Soccer", url: "https://www.worldsoccer.com/feed", logo: "🌍"),
  RssFeed(name: "Squawka", url: "https://www.squawka.com/feed/", logo: "📊"),
  RssFeed(name: "SportsLens", url: "https://sportslens.com/feed", logo: "📰"),
  RssFeed(name: "Football.co.uk", url: "https://www.football.co.uk/rss/", logo: "⚽"),
  RssFeed(name: "SoccerWire", url: "https://www.soccerwire.com/feed", logo: "⚽"),
  RssFeed(name: "Yahoo Sports", url: "https://sports.yahoo.com/soccer/rss/", logo: "📰"),
];

// ==== SERVIÇO DE FETCH RSS ====

class RssService {
  static final List<String> proxies = [
    'https://api.allorigins.win/raw?url=',
    'https://api.rss2json.com/v1/api.json?rss_url=',
    'https://thingproxy.freeboard.io/fetch/',
  ];

  static Future<List<NewsItem>> fetchFeed(RssFeed feed) async {
    for (String proxy in proxies) {
      try {
        final url = proxy + Uri.encodeComponent(feed.url);
        final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          if (proxy.contains('rss2json')) {
            return _parseRss2Json(response.body, feed);
          } else {
            return _parseXmlFeed(response.body, feed);
          }
        }
      } catch (e) {
        continue;
      }
    }
    return [];
  }

  static List<NewsItem> _parseRss2Json(String body, RssFeed feed) {
    try {
      final json = jsonDecode(body);
      final items = json['items'] as List;
      return items.map((item) {
        return NewsItem(
          title: item['title'] ?? '',
          link: item['link'] ?? item['guid'] ?? '',
          description: item['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
          thumbnail: item['thumbnail'] ?? item['enclosure']?['link'],
          source: feed.name,
          sourceLogo: feed.logo,
          pubDate: item['pubDate'] != null ? DateTime.tryParse(item['pubDate']) : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static List<NewsItem> _parseXmlFeed(String body, RssFeed feed) {
    try {
      final document = xml.XmlDocument.parse(body);
      final items = document.findAllElements('item');
      
      return items.map((item) {
        final title = item.findElements('title').first.text;
        final link = item.findElements('link').isNotEmpty 
            ? item.findElements('link').first.text 
            : item.findElements('guid').first.text;
        
        final desc = item.findElements('description').isNotEmpty
            ? item.findElements('description').first.text.replaceAll(RegExp(r'<[^>]*>'), '')
            : '';
        
        String? thumb;
        final media = item.findElements('media:content');
        if (media.isNotEmpty) {
          thumb = media.first.getAttribute('url');
        }
        if (thumb == null) {
          final enclosure = item.findElements('enclosure');
          if (enclosure.isNotEmpty) {
            thumb = enclosure.first.getAttribute('url');
          }
        }
        
        final pubDateStr = item.findElements('pubDate').isNotEmpty
            ? item.findElements('pubDate').first.text
            : null;
        
        return NewsItem(
          title: title,
          link: link,
          description: desc,
          thumbnail: thumb,
          source: feed.name,
          sourceLogo: feed.logo,
          pubDate: pubDateStr != null ? DateTime.tryParse(pubDateStr) : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

// ==== PARTE 2: Interface e Screen ====
// Cole este código no mesmo arquivo após a Parte 1

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({Key? key}) : super(key: key);

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  int _selectedBottomTab = 0;
  bool _isLoading = true;
  bool _isDrawerOpen = false;
  bool _isDarkTheme = true;
  List<NewsItem> _allNews = [];
  List<NewsItem> _filteredNews = [];
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _contentSlideAnimation;

  bool get _isWeb => kIsWeb;

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
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    
    List<NewsItem> allNews = [];
    
    for (final feed in RSS_FEEDS) {
      try {
        final items = await RssService.fetchFeed(feed);
        allNews.addAll(items);
      } catch (e) {
        print('Erro ao carregar ${feed.name}: $e');
      }
    }
    
    allNews.sort((a, b) {
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });
    
    if (mounted) {
      setState(() {
        _allNews = allNews;
        _filteredNews = _selectedTab == 0 ? allNews : allNews.where((n) => n.hasImage).toList();
        _isLoading = false;
      });
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
    if (!_isWeb) {
      if (_isDrawerOpen) {
        _drawerAnimationController.forward();
      } else {
        _drawerAnimationController.reverse();
      }
    }
  }

  Color get _bgColor => _isDarkTheme ? Color(0xFF0A0A0A) : Color(0xFFF0F2F5);
  Color get _surfaceColor => _isDarkTheme ? Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _isDarkTheme ? Color(0xFFE4E6EB) : Color(0xFF050505);
  Color get _subTextColor => _isDarkTheme ? Color(0xFFB0B3B8) : Color(0xFF65676B);
  Color get _borderColor => _isDarkTheme ? Color(0xFF3A3B3C) : Color(0xFFDDDFE2);

  @override
  Widget build(BuildContext context) {
    if (_isWeb) {
      return _buildWebLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildCurrentTab(),
                ),
              ],
            ),
          ),
          if (_isDrawerOpen) _buildDrawerContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _drawerSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * _drawerSlideAnimation.value,
                  0,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                  ),
                  child: _buildDrawerContent(),
                ),
              );
            },
          ),
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
                    child: AbsorbPointer(
                      absorbing: _isDrawerOpen,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: _buildCurrentTab(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: AnimatedOpacity(
                opacity: _isDrawerOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _contentSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width * _contentSlideAnimation.value,
              0,
            ),
            child: _buildBottomNavBar(),
          );
        },
      ),
    );
  }

  Widget _buildDrawerContent() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                if (_isWeb)
                  IconButton(
                    onPressed: _toggleDrawer,
                    icon: Icon(Icons.close, color: _textColor, size: 28),
                  ),
              ],
            ),
          ),
          Divider(color: _borderColor, height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  _isDarkTheme ? Ionicons.moon : Ionicons.sunny,
                  color: _textColor,
                  size: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isDarkTheme ? 'Modo Escuro' : 'Modo Claro',
                    style: TextStyle(
                      fontSize: 16,
                      color: _textColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDarkTheme = !_isDarkTheme;
                    });
                  },
                  child: Container(
                    width: 51,
                    height: 31,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _isDarkTheme ? Color(0xFF2374E1) : Color(0xFFE4E6EB),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: _isDarkTheme ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 27,
                        height: 27,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
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
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_selectedBottomTab == 0) {
      return _buildNewsTab();
    } else if (_selectedBottomTab == 1) {
      return _buildEmptyTab('Partidas');
    } else {
      return _buildEmptyTab('Perfil');
    }
  }

  Widget _buildEmptyTab(String title) {
    return Container(
      key: ValueKey(title),
      color: _bgColor,
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 24, color: _subTextColor),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIOSButton(
              onTap: _toggleDrawer,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF2374E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '⚽',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopTabButton('Todas', 0),
                const SizedBox(width: 24),
                _buildTopTabButton('Com Imagem', 1),
              ],
            ),
            _buildIOSButton(
              onTap: _loadContent,
              child: Icon(Ionicons.refresh, color: _textColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabButton(String text, int index) {
    final isActive = _selectedTab == index;
    return _buildIOSButton(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _filteredNews = index == 0 ? _allNews : _allNews.where((n) => n.hasImage).toList();
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? _textColor : _subTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF2374E1) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFF2374E1)),
      );
    }

    if (_filteredNews.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma notícia disponível',
          style: TextStyle(color: _subTextColor),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _filteredNews.length,
      itemBuilder: (context, index) {
        final news = _filteredNews[index];
        
        if (!news.hasImage && index < _filteredNews.length - 1 && !_filteredNews[index + 1].hasImage) {
          final noImageNews = <NewsItem>[];
          int j = index;
          while (j < _filteredNews.length && !_filteredNews[j].hasImage) {
            noImageNews.add(_filteredNews[j]);
            j++;
          }
          
          if (noImageNews.length > 1) {
            return Column(
              children: [
                _buildHorizontalNewsList(noImageNews),
                SizedBox(height: 8),
              ],
            );
          }
        }
        
        if (news.hasImage) {
          return Column(
            children: [
              _buildNewsCard(news),
              SizedBox(height: 8),
            ],
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildHorizontalNewsList(List<NewsItem> newsList) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          return _buildCompactNewsCard(newsList[index]);
        },
      ),
    );
  }

  Widget _buildCompactNewsCard(NewsItem news) {
    return _buildIOSButton(
      onTap: () => _openLink(news.link),
      child: Container(
        width: 280,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  news.sourceLogo,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    news.source,
                    style: TextStyle(
                      fontSize: 12,
                      color: _subTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: Text(
                news.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (news.pubDate != null) ...[
              SizedBox(height: 4),
              Text(
                _formatDate(news.pubDate!),
                style: TextStyle(
                  fontSize: 11,
                  color: _subTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    return _buildIOSButton(
      onTap: () => _openLink(news.link),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: news.thumbnail!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: _borderColor,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: _borderColor,
                    child: Icon(Icons.image_not_supported, color: _subTextColor),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        news.sourceLogo,
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          news.source,
                          style: TextStyle(
                            fontSize: 13,
                            color: _subTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (news.pubDate != null)
                        Text(
                          _formatDate(news.pubDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _subTextColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                      height: 1.3,
                    ),
                  ),
                  if (news.description != null && news.description!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      news.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _subTextColor,
                        height: 1.4,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          top: BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Ionicons.newspaper, 'Notícias', 0),
              _buildBottomNavItem(Ionicons.football, 'Partidas', 1),
              _buildBottomNavItem(Ionicons.person, 'Perfil', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomTab == index;
    return _buildIOSButton(
      onTap: () {
        setState(() {
          _selectedBottomTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? Color(0xFF2374E1) : _subTextColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? Color(0xFF2374E1) : _subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}