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
import '../widgets/app_ui_components.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

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
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
          final sheetsList =
              (data['sheets'] as List).map((s) => SheetStory.fromJson(s)).toList();
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
            imageUrl:
                'https://alfredoooh.github.io/database/gallery/no_image.png',
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
      'trump',
      'elon musk',
      'apple',
      'bitcoin',
      'tesla',
      'microsoft',
      'google',
      'amazon',
      'meta',
      'nvidia',
      'fed',
      'wall street',
      'stock market',
      'economy',
      'trade',
      'inflation',
      'cryptocurrency',
      'ai',
      'artificial intelligence',
      'china',
      'russia',
      'ukraine',
      'europe',
      'japan',
      'india',
      'uk',
      'france',
      'germany',
      'nasdaq',
      'dow jones',
      's&p 500'
    ];

    featuredNews = allNews.where((article) {
      final titleLower = article.title.toLowerCase();
      final descLower = article.description.toLowerCase();
      return featuredKeywords.any(
          (keyword) => titleLower.contains(keyword) || descLower.contains(keyword));
    }).take(5).toList();

    final remaining =
        allNews.where((article) => !featuredNews.contains(article)).toList();
    noImageNews =
        remaining.where((article) => article.imageUrl.contains('no_image.png')).toList();
    final withImages = remaining.where((article) => !article.imageUrl.contains('no_image.png')).toList();
    mediumNews = withImages.take((withImages.length * 0.4).round()).toList();
    lowNews = withImages.skip(mediumNews.length).toList();
  }

  void filterNewsByCategory() {
    List<NewsArticle> filtered;
    if (selectedCategory == 'all') {
      filtered = allNews;
    } else {
      filtered = allNews
          .where((news) =>
              news.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
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
      'trump',
      'elon musk',
      'apple',
      'bitcoin',
      'tesla',
      'microsoft',
      'google',
      'amazon',
      'meta',
      'nvidia',
      'fed',
      'wall street',
      'stock market',
      'economy',
      'trade',
      'inflation',
      'cryptocurrency',
      'ai',
      'artificial intelligence',
      'china',
      'russia',
      'ukraine',
      'europe',
      'japan',
      'india',
      'uk',
      'france',
      'germany',
      'nasdaq',
      'dow jones',
      's&p 500'
    ];

    featuredNews = filteredNews.where((article) {
      final titleLower = article.title.toLowerCase();
      final descLower = article.description.toLowerCase();
      return featuredKeywords.any(
          (keyword) => titleLower.contains(keyword) || descLower.contains(keyword));
    }).take(5).toList();

    final remaining =
        filteredNews.where((article) => !featuredNews.contains(article)).toList();
    noImageNews =
        remaining.where((article) => article.imageUrl.contains('no_image.png')).toList();
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

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppPrimaryAppBar(
        title: 'Atualidade',
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPro)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AppSectionTitle(
                    text: 'PRO',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (isLoadingSheets)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else if (hasSheets)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 22),
                ),
            ],
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: loadAllContent,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (hasSheets && sheets.isNotEmpty) _buildSheetsSection(isDark),
                  _buildCategoriesSection(isDark),
                  SizedBox(height: 8),
                  _buildFiltersSection(isDark),
                  SizedBox(height: 12),
                  if (isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    )
                  else
                    _buildNewsContent(isDark),
                  if (isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  SizedBox(height: 100),
                ],
              ),
            ),
            if (!isPro) _buildProOverlay(context, isDark),
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProOverlay(BuildContext context, bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconCircle(
                    icon: Icons.lock_outline,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Conteúdo Não Disponível',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esta seção é exclusiva para\nmembros PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.8),
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 18),
                  AppPrimaryButton(
                    text: 'Atualizar para PRO',
                    onPressed: () {
                      // implementar fluxo PRO
                    },
                    isLoading: false,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetsSection(bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4),
        itemCount: sheets.length,
        itemBuilder: (context, index) {
          final sheet = sheets[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SheetsViewerScreen(sheets: sheets, initialIndex: index),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: sheet.imageUrl.isNotEmpty
                          ? Image.network(
                              sheet.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  Icon(Icons.photo, color: Colors.white, size: 30),
                            )
                          : Icon(Icons.photo, color: Colors.white, size: 30),
                    ),
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
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category['id']!;
                  filterNewsByCategory();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
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
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter['id']!;
                  filterNewsByCategory();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.12) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFilterIcon(filter['icon']!),
                      size: 18,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    SizedBox(width: 8),
                    Text(
                      filter['name']!,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
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
        return Icons.local_fire_department;
      case 'clock':
        return Icons.access_time;
      case 'star':
        return Icons.star;
      default:
        return Icons.public;
    }
  }

  Widget _buildNewsContent(bool isDark) {
    if (filteredNews.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 60),
            Icon(Icons.article, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma notícia encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 40),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featuredNews.isNotEmpty) ...[
          Row(
            children: [
              AppSectionTitle(text: 'Destaques', fontSize: 22, fontWeight: FontWeight.w700),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0084FF), Color(0xFF00A3FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('DESTAQUE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...featuredNews.map((article) => _buildFeaturedCard(article, isDark)),
          SizedBox(height: 20),
        ],
        if (noImageNews.isNotEmpty) ...[
          AppSectionTitle(text: 'Notícias do Google & DuckDuckGo', fontSize: 20, fontWeight: FontWeight.w700),
          SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: noImageNews.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildSmallCard(noImageNews[index], isDark),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
        if (mediumNews.isNotEmpty) ...[
          AppSectionTitle(text: 'Notícias em Destaque', fontSize: 20, fontWeight: FontWeight.w700),
          SizedBox(height: 12),
          ...mediumNews.map((article) => _buildMediumCard(article, isDark)),
          SizedBox(height: 20),
        ],
        if (lowNews.isNotEmpty) ...[
          AppSectionTitle(text: 'Mais Notícias', fontSize: 20, fontWeight: FontWeight.w700),
          SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lowNews.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildLowCard(lowNews[index], isDark),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: AppCard(
        child: Container(
          width: 210,
          padding: EdgeInsets.all(12),
          child: Column(
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
                          Icon(Icons.article, size: 16, color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      article.source,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                article.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              Spacer(),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      article.timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: SizedBox(
        height: 420,
        child: AppCard(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: Icon(Icons.photo, size: 70, color: Colors.grey),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0084FF), Color(0xFF00A3FF)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('DESTAQUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icon(Icons.article, color: Colors.white, size: 24),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          article.source,
                          style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      article.title,
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      article.description,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white70, size: 14),
                        SizedBox(width: 8),
                        Text(article.timeAgo, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediumCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  article.imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: double.infinity,
                    height: 220,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: Icon(Icons.photo, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
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
                                Icon(Icons.article, size: 20, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            article.source,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      article.title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      article.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(article.timeAgo, style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: AppCard(
        child: Container(
          width: 290,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                child: Image.network(
                  article.imageUrl,
                  width: 110,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 110,
                    height: 210,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: Icon(Icons.photo, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
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
                                  Icon(Icons.article, size: 18, color: Colors.grey),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              article.source,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        article.title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 13, color: Colors.grey),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(article.timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openArticleDetail(NewsArticle article) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Navigator.of(context).push(
      MaterialPageRoute(
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