// PARTE 1: Main, Models e RSS Service
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

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

// models.dart
class NewsSource {
  final String name;
  final String rss;
  final String? logo;
  final String? country;

  NewsSource({
    required this.name,
    required this.rss,
    this.logo,
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
}

// rss_sources.dart
class RssSources {
  static final List<NewsSource> sources = [
    // Principais fontes internacionais
    NewsSource(name: "BBC Sport", rss: "https://feeds.bbci.co.uk/sport/football/rss.xml", country: "UK"),
    NewsSource(name: "Sky Sports", rss: "https://www.skysports.com/rss/12040", country: "UK"),
    NewsSource(name: "The Guardian", rss: "https://www.theguardian.com/football/rss", country: "UK"),
    NewsSource(name: "ESPN", rss: "https://www.espn.com/espn/rss/soccer/news", country: "USA"),
    NewsSource(name: "Goal", rss: "https://www.goal.com/feeds/en/news", country: "INT"),
    NewsSource(name: "90min", rss: "https://90min.com/posts.rss", country: "INT"),
    NewsSource(name: "FourFourTwo", rss: "https://www.fourfourtwo.com/rss", country: "UK"),
    NewsSource(name: "Football365", rss: "https://www.football365.com/rss", country: "UK"),
    NewsSource(name: "Mirror Football", rss: "https://www.mirror.co.uk/sport/football/rss.xml", country: "UK"),
    NewsSource(name: "Daily Mail", rss: "https://www.dailymail.co.uk/sport/football/index.rss", country: "UK"),
    NewsSource(name: "The Sun", rss: "https://www.thesun.co.uk/sport/football/feed/", country: "UK"),
    NewsSource(name: "Bleacher Report", rss: "https://bleacherreport.com/articles/feed", country: "USA"),
    NewsSource(name: "CBS Sports", rss: "https://www.cbssports.com/rss/headlines/soccer/", country: "USA"),
    NewsSource(name: "TeamTalk", rss: "https://www.teamtalk.com/feed/", country: "UK"),
    
    // Fontes portuguesas
    NewsSource(name: "ZeroZero", rss: "https://www.zerozero.pt/rss/noticias.php", country: "PT"),
    NewsSource(name: "MaisFutebol", rss: "https://www.maisfutebol.iol.pt/rss", country: "PT"),
    NewsSource(name: "O Jogo", rss: "https://www.ojogo.pt/rss", country: "PT"),
    NewsSource(name: "Record", rss: "https://www.record.pt/rss", country: "PT"),
    NewsSource(name: "A Bola", rss: "https://www.abola.pt/rss", country: "PT"),
    NewsSource(name: "Sporting CP", rss: "https://www.sporting.pt/en/news/rss", country: "PT"),
    NewsSource(name: "FC Porto", rss: "https://www.fcporto.pt/pt/rss", country: "PT"),
    
    // Fontes brasileiras
    NewsSource(name: "GloboEsporte", rss: "https://ge.globo.com/rss/ge/futebol/", country: "BR"),
    NewsSource(name: "UOL Esporte", rss: "https://rss.uol.com.br/feed/esporte.xml", country: "BR"),
    NewsSource(name: "Lance!", rss: "https://www.lance.com.br/rss", country: "BR"),
    NewsSource(name: "ESPN Brasil", rss: "https://www.espn.com.br/feeds/rss/news", country: "BR"),
    NewsSource(name: "Trivela", rss: "https://trivela.com.br/feed/", country: "BR"),
    
    // Fontes espanholas
    NewsSource(name: "Marca", rss: "https://e00-marca.uecdn.es/rss/en/international.xml", country: "ES"),
    NewsSource(name: "AS", rss: "https://as.com/rss/futbol/portada.xml", country: "ES"),
    NewsSource(name: "Mundo Deportivo", rss: "https://www.mundodeportivo.com/rss/futbol/", country: "ES"),
    NewsSource(name: "Sport", rss: "https://www.sport.es/es/rss/", country: "ES"),
    NewsSource(name: "El País Deportes", rss: "https://elpais.com/deportes/rss/", country: "ES"),
    
    // Fontes italianas
    NewsSource(name: "Football Italia", rss: "https://football-italia.net/feed", country: "IT"),
    NewsSource(name: "La Gazzetta", rss: "https://www.gazzetta.it/rss/", country: "IT"),
    NewsSource(name: "Corriere dello Sport", rss: "https://www.corrieredellosport.it/rss", country: "IT"),
    NewsSource(name: "Tuttosport", rss: "https://www.tuttosport.com/rss", country: "IT"),
    
    // Fontes francesas
    NewsSource(name: "L'Équipe", rss: "https://www.lequipe.fr/rss/actu_rss_Football.xml", country: "FR"),
    NewsSource(name: "RMC Sport", rss: "https://rmcsport.bfmtv.com/rss/football/", country: "FR"),
    
    // Fontes alemãs
    NewsSource(name: "Kicker", rss: "https://www.kicker.de/news/fussball/rss.xml", country: "DE"),
    NewsSource(name: "Sport1", rss: "https://www.sport1.de/fussball/rss", country: "DE"),
    
    // Sites especializados
    NewsSource(name: "Transfermarkt", rss: "https://www.transfermarkt.com/rss/news/", country: "INT"),
    NewsSource(name: "Who Scored", rss: "https://www.whoscored.com/rss", country: "INT"),
    NewsSource(name: "Football Transfers", rss: "https://www.footballtransfers.com/en/rss", country: "INT"),
    NewsSource(name: "Inside World Football", rss: "https://www.insideworldfootball.com/feed/", country: "INT"),
    
    // Fan blogs Premier League
    NewsSource(name: "This Is Anfield", rss: "https://www.thisisanfield.com/feed/", country: "UK"),
    NewsSource(name: "The Empire of The Kop", rss: "https://www.empireofthekop.com/feed/", country: "UK"),
    NewsSource(name: "Arseblog", rss: "https://arseblog.com/feed", country: "UK"),
    NewsSource(name: "Just Arsenal", rss: "https://www.justarsenal.com/feed", country: "UK"),
    NewsSource(name: "Talk Chelsea", rss: "https://www.talkchelsea.net/feed/", country: "UK"),
    NewsSource(name: "The Peoples Person", rss: "https://thepeoplesperson.com/feed/", country: "UK"),
    NewsSource(name: "Stretty News", rss: "https://strettynews.com/feed", country: "UK"),
    NewsSource(name: "The Mag (Newcastle)", rss: "https://www.themag.co.uk/feed/", country: "UK"),
    
    // Fan blogs La Liga
    NewsSource(name: "Managing Madrid", rss: "https://www.managingmadrid.com/rss/current", country: "ES"),
    NewsSource(name: "Barca Blaugranes", rss: "https://www.barcablaugranes.com/rss/current", country: "ES"),
    NewsSource(name: "Barca Universal", rss: "https://barcauniversal.com/feed/", country: "ES"),
    
    // Fan blogs Serie A
    NewsSource(name: "RomaPress", rss: "https://romapress.net/feed/", country: "IT"),
    NewsSource(name: "SempreMilan", rss: "https://sempremilan.com/feed", country: "IT"),
    NewsSource(name: "JuveFC", rss: "https://www.juvefc.com/feed/", country: "IT"),
    
    // MLS
    NewsSource(name: "MLS Soccer", rss: "https://www.mlssoccer.com/rss", country: "USA"),
    NewsSource(name: "SBI Soccer", rss: "https://sbisoccer.com/feed", country: "USA"),
    
    // Clubes oficiais
    NewsSource(name: "Manchester United", rss: "https://www.manutd.com/en/feeds/first-team", country: "UK"),
    NewsSource(name: "PSG Official", rss: "https://en.psg.fr/teams/first-team/content.rss", country: "FR"),
    NewsSource(name: "Bayern Munich", rss: "https://fcbayern.com/en/news/rss", country: "DE"),
    NewsSource(name: "Borussia Dortmund", rss: "https://www.bvb.de/eng/News.rss", country: "DE"),
    NewsSource(name: "Juventus", rss: "https://www.juventus.com/en/feed", country: "IT"),
    
    // Outros
    NewsSource(name: "101 Great Goals", rss: "https://www.101greatgoals.com/feed", country: "INT"),
    NewsSource(name: "Caught Offside", rss: "https://caughtoffside.com/feed", country: "UK"),
    NewsSource(name: "Football Fan Cast", rss: "https://footballfancast.com/feed", country: "UK"),
    NewsSource(name: "World Soccer", rss: "https://www.worldsoccer.com/feed", country: "INT"),
    NewsSource(name: "Squawka", rss: "https://www.squawka.com/feed/", country: "UK"),
    NewsSource(name: "OneFootball", rss: "https://onefootball.com/en/rss", country: "INT"),
  ];
}

// rss_service.dart
class RssService {
  Future<List<NewsArticle>> fetchArticles(NewsSource source) async {
    try {
      final response = await http.get(
        Uri.parse(source.rss),
        headers: {'User-Agent': 'FootballFeedApp/1.0'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        return items.map((item) {
          final title = item.findElements('title').first.innerText;
          final link = item.findElements('link').first.innerText;
          final description = item.findElements('description').isNotEmpty
              ? item.findElements('description').first.innerText
              : null;

          String? imageUrl;
          // Tenta encontrar imagem em diferentes tags
          if (item.findElements('media:content').isNotEmpty) {
            imageUrl = item.findElements('media:content').first.getAttribute('url');
          } else if (item.findElements('enclosure').isNotEmpty) {
            imageUrl = item.findElements('enclosure').first.getAttribute('url');
          } else if (item.findElements('media:thumbnail').isNotEmpty) {
            imageUrl = item.findElements('media:thumbnail').first.getAttribute('url');
          }

          DateTime? pubDate;
          if (item.findElements('pubDate').isNotEmpty) {
            try {
              pubDate = DateTime.parse(item.findElements('pubDate').first.innerText);
            } catch (e) {
              // Ignora erro de parse de data
            }
          }

          return NewsArticle(
            title: title,
            description: description,
            imageUrl: imageUrl,
            link: link,
            pubDate: pubDate,
            source: source,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching ${source.name}: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> fetchAllArticles() async {
    List<NewsArticle> allArticles = [];
    
    // Busca de 20 fontes por vez para não sobrecarregar
    final batches = _createBatches(RssSources.sources, 20);
    
    for (var batch in batches) {
      final results = await Future.wait(
        batch.map((source) => fetchArticles(source)),
      );
      
      for (var articles in results) {
        allArticles.addAll(articles);
      }
    }

    // Ordena por data
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
      batches.add(sources.sublist(
        i,
        i + batchSize > sources.length ? sources.length : i + batchSize,
      ));
    }
    return batches;
  }
}

// PARTE 2: UI Components e Screen Principal
// football_feed_screen.dart
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
                            Expanded(child: _buildCurrentTab()),
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
                child: Container(color: Colors.black.withOpacity(0.5)),
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
                  Icon(
                    _isDarkTheme ? Ionicons.moon : Ionicons.sunny,
                    color: _textColor,
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isDarkTheme ? 'Modo Escuro' : 'Modo Claro',
                      style: TextStyle(fontSize: 16, color: _textColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isDarkTheme = !_isDarkTheme),
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
      return _selectedTab == 0 ? _buildParaVoceTab() : _buildSeguindoTab();
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
        color: _surfaceColor,
        border: Border(bottom: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF2374E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Ionicons.football, color: Colors.white, size: 20),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopTabButton('Para você', 0),
                const SizedBox(width: 24),
                _buildTopTabButton('Seguindo', 1),
              ],
            ),
            GestureDetector(
              onTap: () {},
              child: Icon(Ionicons.search, color: _textColor, size: 24),
            ),
          ],
        ),
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

  Widget _buildParaVoceTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonPost(),
      );
    }

    final articlesWithImages = _articles.where((a) => a.hasImage).toList();
    final articlesWithoutImages = _articles.where((a) => !a.hasImage).toList();

    return ListView.builder(
      key: const ValueKey('para-voce'),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: articlesWithImages.length + (articlesWithoutImages.length > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        // Insere scroll horizontal a cada 3 posts com imagem
        if (index > 0 && index % 3 == 0 && articlesWithoutImages.isNotEmpty) {
          return Column(
            children: [
              _buildHorizontalNewsList(articlesWithoutImages.take(10).toList()),
              SizedBox(height: 12),
              _buildNewsCard(articlesWithImages[index]),
            ],
          );
        }
        
        if (index < articlesWithImages.length) {
          return Column(
            children: [
              _buildNewsCard(articlesWithImages[index]),
              SizedBox(height: 12),
            ],
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildHorizontalNewsList(List<NewsArticle> articles) {
    return Container(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
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
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Ionicons.newspaper_outline, size: 14, color: Color(0xFF2374E1)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    article.source.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2374E1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: Text(
                article.title,
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
              SizedBox(height: 4),
              Text(
                _formatTime(article.pubDate!),
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

  Widget _buildNewsCard(NewsArticle article) {
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
              offset: Offset(0, 2),
            ),
          ],
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
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: _borderColor,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: _borderColor,
                    child: Icon(Ionicons.image_outline, size: 48, color: _subTextColor),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Ionicons.newspaper_outline, size: 14, color: Color(0xFF2374E1)),
                      SizedBox(width: 6),
                      Text(
                        article.source.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2374E1),
                        ),
                      ),
                      if (article.pubDate != null) ...[
                        Text(' · ', style: TextStyle(color: _subTextColor)),
                        Text(
                          _formatTime(article.pubDate!),
                          style: TextStyle(fontSize: 12, color: _subTextColor),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: _textColor,
                    ),
                  ),
                  if (article.description != null) ...[
                    SizedBox(height: 8),
                    Text(
                      article.description!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _subTextColor,
                      ),
                      maxLines: 2,
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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSeguindoTab() {
    return Center(
      key: const ValueKey('seguindo'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Ionicons.people_outline, size: 64, color: _borderColor),
          const SizedBox(height: 16),
          Text(
            'Comece a seguir fontes para ver\no conteúdo delas aqui',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
              _buildBottomNavItem(Ionicons.home_outline, Ionicons.home, 'Início', 0),
              _buildBottomNavItem(Ionicons.football_outline, Ionicons.football, 'Partidas', 1),
              _buildBottomNavItem(Ionicons.person_outline, Ionicons.person, 'Perfil', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData outlineIcon, IconData filledIcon, String label, int index) {
    final isSelected = _selectedBottomTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedBottomTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? filledIcon : outlineIcon,
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
}