import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'svg_icons.dart'; // Seus SVGs originais

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

// Models
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

// RSS Sources
class RssSources {
  static final List<NewsSource> sources = [
    NewsSource(name: "BBC Sport", rss: "https://feeds.bbci.co.uk/sport/football/rss.xml", country: "UK"),
    NewsSource(name: "Sky Sports", rss: "https://www.skysports.com/rss/12040", country: "UK"),
    NewsSource(name: "The Guardian", rss: "https://www.theguardian.com/football/rss", country: "UK"),
    NewsSource(name: "ESPN", rss: "https://www.espn.com/espn/rss/soccer/news", country: "USA"),
    NewsSource(name: "Goal", rss: "https://www.goal.com/feeds/en/news", country: "INT"),
    NewsSource(name: "90min", rss: "https://90min.com/posts.rss", country: "INT"),
    NewsSource(name: "FourFourTwo", rss: "https://www.fourfourtwo.com/rss", country: "UK"),
    NewsSource(name: "GloboEsporte", rss: "https://ge.globo.com/rss/ge/futebol/", country: "BR"),
    NewsSource(name: "Marca", rss: "https://e00-marca.uecdn.es/rss/en/international.xml", country: "ES"),
    NewsSource(name: "AS", rss: "https://as.com/rss/futbol/portada.xml", country: "ES"),
  ];
}

// RSS Service
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
          if (item.findElements('media:content').isNotEmpty) {
            imageUrl = item.findElements('media:content').first.getAttribute('url');
          } else if (item.findElements('enclosure').isNotEmpty) {
            final enclosure = item.findElements('enclosure').first;
            final type = enclosure.getAttribute('type');
            if (type != null && type.startsWith('image/')) {
              imageUrl = enclosure.getAttribute('url');
            }
          } else if (item.findElements('media:thumbnail').isNotEmpty) {
            imageUrl = item.findElements('media:thumbnail').first.getAttribute('url');
          }

          // Limpa URL da imagem
          if (imageUrl != null) {
            imageUrl = imageUrl.trim();
            if (!imageUrl.startsWith('http')) {
              imageUrl = null;
            }
          }

          DateTime? pubDate;
          if (item.findElements('pubDate').isNotEmpty) {
            try {
              pubDate = DateTime.parse(item.findElements('pubDate').first.innerText);
            } catch (e) {
              // Ignora erro de parse
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
    
    final batches = _createBatches(RssSources.sources, 10);
    
    for (var batch in batches) {
      final results = await Future.wait(
        batch.map((source) => fetchArticles(source)),
      );
      
      for (var articles in results) {
        allArticles.addAll(articles);
      }
    }

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

// Main Screen
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
          // Main content - PRIMEIRO
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
          // Drawer - POR CIMA
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
          // Overlay - POR CIMA DE TUDO
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black.withOpacity(0.5),
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
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFF2374E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Ionicons.football, color: Colors.white, size: 20),
                  );
                },
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

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.newspaper_outline, size: 64, color: _borderColor),
            SizedBox(height: 16),
            Text(
              'Nenhuma notícia disponível',
              style: TextStyle(fontSize: 15, color: _subTextColor),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final articlesWithImages = _articles.where((a) => a.hasImage).toList();
    final articlesWithoutImages = _articles.where((a) => !a.hasImage).toList();

    return ListView.builder(
      key: const ValueKey('para-voce'),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: articlesWithImages.length + (articlesWithoutImages.length > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index > 0 && index % 3 == 0 && articlesWithoutImages.isNotEmpty) {
          return Column(
            children: [
              _buildHorizontalNewsList(articlesWithoutImages.take(10).toList()),
              SizedBox(height: 12),
              if (index < articlesWithImages.length)
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
                  httpHeaders: {'User-Agent': 'FootballFeedApp/1.0'},
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: _borderColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2374E1)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print('Image error: $error for URL: $url');
                    return Container(
                      height: 200,
                      color: _borderColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Ionicons.image_outline, size: 48, color: _subTextColor),
                          SizedBox(height: 8),
                          Text(
                            'Imagem indisponível',
                            style: TextStyle(fontSize: 12, color: _subTextColor),
                          ),
                        ],
                      ),
                    );
                  },
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
                  if (article.description != null && article.description!.isNotEmpty) ...[
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
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL: $e');
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
              _buildBottomNavItem(
                SvgIcons.homeOutline,
                SvgIcons.homeFilled,
                'Início',
                0,
              ),
              _buildBottomNavItem(
                SvgIcons.matchesOutline,
                SvgIcons.matchesFilled,
                'Partidas',
                1,
              ),
              _buildBottomNavItem(
                SvgIcons.profileOutline,
                SvgIcons.profileFilled,
                'Perfil',
                2,
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
    int index,
  ) {
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
          SvgPicture.string(
            isSelected ? filledSvg : outlinedSvg,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? Color(0xFF2374E1) : _subTextColor,
              BlendMode.srcIn,
            ),
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