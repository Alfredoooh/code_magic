// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_detail_screen.dart';
import 'sheets_viewer_screen.dart';
import '../models/news_article.dart';
import '../models/sheet_story.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> allNews = [];
  List<NewsArticle> filteredNews = [];
  List<NewsArticle> featuredNews = [];
  List<NewsArticle> mediumNews = [];
  List<NewsArticle> lowNews = [];
  List<NewsArticle> noImageNews = [];
  List<SheetStory> sheets = [];
  bool isLoading = true;
  bool isLoadingSheets = true;
  bool isLoadingMore = false;
  bool hasSheets = false;
  bool isPro = false;
  bool showScrollToTop = false;
  String selectedCategory = 'all';
  String selectedFilter = 'all';
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final NewsService _newsService = NewsService();

  final List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'Todas'},
    {'id': 'business', 'name': 'Negócios'},
    {'id': 'technology', 'name': 'Tecnologia'},
    {'id': 'crypto', 'name': 'Cripto'},
    {'id': 'stocks', 'name': 'Ações'},
    {'id': 'sports', 'name': 'Esportes'},
    {'id': 'entertainment', 'name': 'Entretenimento'},
    {'id': 'health', 'name': 'Saúde'},
    {'id': 'science', 'name': 'Ciência'},
  ];

  final List<Map<String, String>> filters = [
    {'id': 'all', 'name': 'Todas', 'icon': 'globe'},
    {'id': 'trending', 'name': 'Tendências', 'icon': 'flame'},
    {'id': 'recent', 'name': 'Recentes', 'icon': 'clock'},
    {'id': 'popular', 'name': 'Populares', 'icon': 'star'},
  ];

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    loadAllContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore) {
        _loadMoreNews();
      }
    }

    setState(() {
      showScrollToTop = _scrollController.position.pixels > 500;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future _checkProStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          isPro = doc.data()?['pro'] == true;
        });
      }
    }
  }

  Future _loadMoreNews() async {
    if (isLoadingMore) return;
    setState(() => isLoadingMore = true);
    currentPage++;
    await Future.delayed(Duration(milliseconds: 500));
    List<NewsArticle> moreNews = await _newsService.loadAdditionalNews();
    if (mounted) {
      setState(() {
        allNews.addAll(moreNews);
        filterNewsByCategory();
        isLoadingMore = false;
      });
    }
  }

  Future loadAllContent() async {
    setState(() {
      isLoading = true;
      isLoadingSheets = true;
      currentPage = 1;
    });

    await Future.wait([
      loadSheets(),
      loadAllNews(),
    ]);

    setState(() {
      isLoading = false;
      isLoadingSheets = false;
    });
  }

  Future loadSheets() async {
    try {
      final response = await http
          .get(Uri.parse('https://alfredoooh.github.io/database/data/SHEETS/sheets.json'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sheets'] != null) {
          final sheetsList = (data['sheets'] as List).map((s) => SheetStory.fromJson(s)).toList();
          setState(() {
            sheets = sheetsList;
            hasSheets = sheets.isNotEmpty;
            isLoadingSheets = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        sheets = [];
        hasSheets = false;
        isLoadingSheets = false;
      });
    }
  }

  Future loadAllNews() async {
    List<NewsArticle> newsFromSources = [];

    await Future.wait([
      _newsService.loadCustomNews().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchNewsFromNewsdata().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchNewsFromNewsApi().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchNewsFromGNews().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromCryptoCompare().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromCoinDesk().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromTechCrunch().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromTheVerge().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromBloomberg().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromCNBC().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromGoogleNews().then((news) => newsFromSources.addAll(news)),
      _newsService.fetchFromDuckDuckGo().then((news) => newsFromSources.addAll(news)),
    ]);

    final uniqueNews = <String, NewsArticle>{};
    for (var article in newsFromSources) {
      if (!uniqueNews.containsKey(article.title)) {
        if (article.imageUrl.isEmpty) {
          article = NewsArticle(
            title: article.title,
            description: article.description,
            imageUrl: 'https://alfredoooh.github.io/database/gallery/no_image.png',
            url: article.url,
            source: article.source,
            publishedAt: article.publishedAt,
            category: article.category,
          );
        }
        uniqueNews[article.title] = article;
      }
    }

    final sortedNews = uniqueNews.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    setState(() {
      allNews = sortedNews;
      _categorizeNews();
      filterNewsByCategory();
    });
  }

  void _categorizeNews() {
    final featuredKeywords = [
      'trump', 'elon musk', 'apple', 'bitcoin', 'tesla', 'microsoft', 'google', 'amazon', 
      'meta', 'nvidia', 'fed', 'wall street', 'stock market', 'economy', 'trade', 'inflation',
      'cryptocurrency', 'ai', 'artificial intelligence', 'china', 'russia', 'ukraine', 'europe',
      'japan', 'india', 'uk', 'france', 'germany', 'nasdaq', 'dow jones', 's&p 500'
    ];

    featuredNews = allNews.where((article) {
      final titleLower = article.title.toLowerCase();
      final descLower = article.description.toLowerCase();
      return featuredKeywords.any((keyword) => titleLower.contains(keyword) || descLower.contains(keyword));
    }).take(5).toList();

    final remaining = allNews.where((article) => !featuredNews.contains(article)).toList();
    noImageNews = remaining.where((article) => article.imageUrl.contains('no_image.png')).toList();
    final withImages = remaining.where((article) => !article.imageUrl.contains('no_image.png')).toList();
    mediumNews = withImages.take((withImages.length * 0.4).round()).toList();
    lowNews = withImages.skip(mediumNews.length).toList();
  }

  void filterNewsByCategory() {
    List<NewsArticle> filtered;
    if (selectedCategory == 'all') {
      filtered = allNews;
    } else {
      filtered = allNews.where((news) => news.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
    }

    if (selectedFilter == 'trending') {
      filtered.sort((a, b) => b.title.length.compareTo(a.title.length));
    } else if (selectedFilter == 'recent') {
      filtered.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    } else if (selectedFilter == 'popular') {
      filtered.shuffle();
    }

    setState(() {
      filteredNews = filtered;
      _categorizeFilteredNews();
    });
  }

  void _categorizeFilteredNews() {
    final featuredKeywords = [
      'trump', 'elon musk', 'apple', 'bitcoin', 'tesla', 'microsoft', 'google', 'amazon',
      'meta', 'nvidia', 'fed', 'wall street', 'stock market', 'economy', 'trade', 'inflation',
      'cryptocurrency', 'ai', 'artificial intelligence', 'china', 'russia', 'ukraine', 'europe',
      'japan', 'india', 'uk', 'france', 'germany', 'nasdaq', 'dow jones', 's&p 500'
    ];

    featuredNews = filteredNews.where((article) {
      final titleLower = article.title.toLowerCase();
      final descLower = article.description.toLowerCase();
      return featuredKeywords.any((keyword) => titleLower.contains(keyword) || descLower.contains(keyword));
    }).take(5).toList();

    final remaining = filteredNews.where((article) => !featuredNews.contains(article)).toList();
    noImageNews = remaining.where((article) => article.imageUrl.contains('no_image.png')).toList();
    final withImages = remaining.where((article) => !article.imageUrl.contains('no_image.png')).toList();
    mediumNews = withImages.take((withImages.length * 0.4).round()).toList();
    lowNews = withImages.skip(mediumNews.length).toList();
  }

  String _getFaviconUrl(String source) {
    final domain = source.toLowerCase().replaceAll(' ', '');
    return 'https://www.google.com/s2/favicons?domain=$domain.com&sz=64';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: isDark ? Color(0xFF000000).withOpacity(0.9) : Color(0xFFF2F2F7).withOpacity(0.9),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF000000).withOpacity(0.75) : Color(0xFFF2F2F7).withOpacity(0.75),
                      ),
                      child: FlexibleSpaceBar(
                        centerTitle: false,
                        titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                        title: Text(
                          'Atualidade',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPro)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (isLoadingSheets)
                        Padding(
                          padding: EdgeInsets.only(left: 12, right: 16),
                          child: CupertinoActivityIndicator(radius: 10),
                        )
                      else if (hasSheets)
                        Padding(
                          padding: EdgeInsets.only(left: 12, right: 16),
                          child: Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.systemGreen, size: 22),
                        ),
                    ],
                  ),
                ],
              ),
              if (hasSheets && sheets.isNotEmpty)
                SliverToBoxAdapter(child: _buildSheetsSection(isDark)),
              SliverToBoxAdapter(child: _buildCategoriesSection(isDark)),
              SliverToBoxAdapter(child: _buildFiltersSection(isDark)),
              if (isPro)
                CupertinoSliverRefreshControl(onRefresh: loadAllContent)
              else
                SliverToBoxAdapter(child: SizedBox.shrink()),
              if (isPro)
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: isLoading
                      ? SliverFillRemaining(
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 15, color: Color(0xFFFF444F)),
                          ),
                        )
                      : _buildNewsList(isDark),
                ),
            ],
          ),
          if (!isPro) _buildBlurOverlay(isDark),
          if (showScrollToTop && isPro)
            Positioned(
              bottom: 90,
              right: 16,
              child: GestureDetector(
                onTap: _scrollToTop,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF444F).withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlurOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.lock_shield_fill, size: 70, color: Color(0xFFFF444F)),
                SizedBox(height: 24),
                Text(
                  'Conteúdo Não Disponível',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Esta seção é exclusiva para',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'membros PRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFF444F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF444F).withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.star_fill, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Atualizar para PRO',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetsSection(bool isDark) {
    return Container(
      height: 110,
      margin: EdgeInsets.only(top: 12, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: sheets.length,
        itemBuilder: (context, index) {
          final sheet = sheets[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => SheetsViewerScreen(sheets: sheets, initialIndex: index),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF444F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: sheet.imageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              sheet.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  Icon(CupertinoIcons.photo, color: Colors.white, size: 30),
                            ),
                          )
                        : Icon(CupertinoIcons.photo, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      sheet.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection(bool isDark) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category['id']!;
                  filterNewsByCategory();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFFF444F) : (isDark ? Color(0xFF1C1C1E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFFFF444F).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    category['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['id'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter['id']!;
                  filterNewsByCategory();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFFF444F).withOpacity(0.15) : (isDark ? Color(0xFF1C1C1E) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Color(0xFFFF444F) : (isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA)),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFilterIcon(filter['icon']!),
                      size: 18,
                      color: isSelected ? Color(0xFFFF444F) : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    SizedBox(width: 6),
                    Text(
                      filter['name']!,
                      style: TextStyle(
                        color: isSelected ? Color(0xFFFF444F) : (isDark ? Colors.white70 : Colors.black54),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getFilterIcon(String icon) {
    switch (icon) {
      case 'flame':
        return CupertinoIcons.flame_fill;
      case 'clock':
        return CupertinoIcons.clock_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      default:
        return CupertinoIcons.globe;
    }
  }

  Widget _buildNewsList(bool isDark) {
    if (filteredNews.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.news, size: 80, color: CupertinoColors.systemGrey),
              SizedBox(height: 16),
              Text(
                'Nenhuma notícia encontrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        if (featuredNews.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Destaques',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0084FF), Color(0xFF00A3FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'DESTAQUE',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...featuredNews.map((article) => _buildFeaturedCard(article, isDark)),
          SizedBox(height: 32),
        ],
        if (noImageNews.isNotEmpty) ...[
          Text(
            'Notícias do Google & DuckDuckGo',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: noImageNews.length,
              itemBuilder: (context, index) => _buildSmallCard(noImageNews[index], isDark),
            ),
          ),
          SizedBox(height: 32),
        ],
        if (mediumNews.isNotEmpty) ...[
          Text(
            'Notícias em Destaque',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16),
          ...mediumNews.map((article) => _buildMediumCard(article, isDark)),
          SizedBox(height: 32),
        ],
        if (lowNews.isNotEmpty) ...[
          Text(
            'Mais Notícias',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lowNews.length,
              itemBuilder: (context, index) => _buildLowCard(lowNews[index], isDark),
            ),
          ),
        ],
        if (isLoadingMore)
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CupertinoActivityIndicator(radius: 15, color: Color(0xFFFF444F))),
          ),
        SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildSmallCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: 210,
            margin: EdgeInsets.only(right: 12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isDark ? Color(0xFF1C1C1E) : Colors.white).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _getFaviconUrl(article.source),
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stack) =>
                                Icon(CupertinoIcons.news, size: 16, color: CupertinoColors.systemGrey),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.source,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF444F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(CupertinoIcons.time, size: 12, color: CupertinoColors.systemGrey),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        article.timeAgo,
                        style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        height: 420,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.systemGrey5,
                  child: Icon(CupertinoIcons.photo, size: 70, color: CupertinoColors.systemGrey),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0084FF), Color(0xFF00A3FF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF0084FF).withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'DESTAQUE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            _getFaviconUrl(article.source),
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stack) =>
                                Icon(CupertinoIcons.news, color: Colors.white, size: 24),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          article.source,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Text(
                      article.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    Text(
                      article.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, color: Colors.white.withOpacity(0.8), size: 16),
                        SizedBox(width: 6),
                        Text(
                          article.timeAgo,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildMediumCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: (isDark ? Color(0xFF1C1C1E) : Colors.white).withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: double.infinity,
                      height: 220,
                      color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                      child: Icon(CupertinoIcons.photo, size: 60, color: CupertinoColors.systemGrey),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              _getFaviconUrl(article.source),
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stack) =>
                                  Icon(CupertinoIcons.news, size: 20, color: CupertinoColors.systemGrey),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              article.source,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF444F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(CupertinoIcons.time, size: 15, color: CupertinoColors.systemGrey),
                          SizedBox(width: 6),
                          Text(
                            article.timeAgo,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildLowCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: 290,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: (isDark ? Color(0xFF1C1C1E) : Colors.white).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    article.imageUrl,
                    width: 110,
                    height: 210,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 110,
                      height: 210,
                      color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                      child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 40),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    _getFaviconUrl(article.source),
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (context, error, stack) =>
                                        Icon(CupertinoIcons.news, size: 18, color: CupertinoColors.systemGrey),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    article.source,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF444F),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              article.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(CupertinoIcons.time, size: 13, color: CupertinoColors.systemGrey),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                article.timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openArticleDetail(NewsArticle article) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => NewsDetailScreen(
          article: article,
          allArticles: filteredNews,
          currentIndex: filteredNews.indexOf(article),
          isDark: isDark,
        ),
      ),
    );
  }
}