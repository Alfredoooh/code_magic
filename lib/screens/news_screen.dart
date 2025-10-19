// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'news_detail_screen.dart';
import 'sheets_viewer_screen.dart';
import '../models/news_article.dart';
import '../models/sheet_story.dart';
import '../services/news_service.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
import '../widgets/post_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  int _selectedTab = 0;
  
  List<NewsArticle> _tradingNews = [];
  List<SheetStory> _sheets = [];
  List<QueryDocumentSnapshot> _allSheets = [];
  bool _loadingNews = true;
  bool _loadingSheets = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loadingNews = true;
      _loadingSheets = true;
    });

    await Future.wait([
      _loadTradingNews(),
      _loadSheets(),
      _loadAllSheets(),
    ]);

    setState(() {
      _loadingNews = false;
      _loadingSheets = false;
    });
  }

  Future<void> _loadTradingNews() async {
    try {
      final news = await Future.wait([
        _newsService.fetchFromCryptoCompare(),
        _newsService.fetchFromCoinDesk(),
        _newsService.fetchFromBloomberg(),
        _newsService.fetchFromCNBC(),
      ]);

      final allNews = news.expand((list) => list).toList();
      
      final uniqueNews = <String, NewsArticle>{};
      for (var article in allNews) {
        if (!uniqueNews.containsKey(article.title)) {
          uniqueNews[article.title] = article;
        }
      }

      setState(() {
        _tradingNews = uniqueNews.values.toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      });
    } catch (e) {
      print('Erro ao carregar notícias: $e');
    }
  }

  Future<void> _loadSheets() async {
    try {
      final response = await http
          .get(Uri.parse('https://alfredoooh.github.io/database/data/SHEETS/sheets.json'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sheets'] != null) {
          setState(() {
            _sheets = (data['sheets'] as List)
                .map((s) => SheetStory.fromJson(s))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar sheets: $e');
    }
  }

  Future<void> _loadAllSheets() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('publicacoes')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _allSheets = snapshot.docs;
      });
    } catch (e) {
      print('Erro ao carregar sheets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppPrimaryAppBar(title: 'Atualidade'),
      body: Column(
        children: [
          _buildCustomTabBar(isDark),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildSheetsTab(isDark),
                _buildNewsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 0
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _selectedTab == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Sheets',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 0
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontSize: 15,
                    fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 1
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _selectedTab == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Trading News',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 1
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontSize: 15,
                    fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetsTab(bool isDark) {
    if (_loadingSheets) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_allSheets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'Nenhum sheet disponível',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _allSheets.length,
        itemBuilder: (context, index) {
          final post = _allSheets[index].data() as Map<String, dynamic>;
          final postId = _allSheets[index].id;
          
          return PostCard(
            post: post,
            postId: postId,
            isDark: isDark,
            currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),
    );
  }

  Widget _buildNewsTab(bool isDark) {
    if (_loadingNews) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_tradingNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.newspaper, size: 80, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'Nenhuma notícia disponível',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _tradingNews.length,
        itemBuilder: (context, index) {
          return _buildNewsCard(_tradingNews[index], isDark);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openNewsDetail(article),
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl.isNotEmpty && !article.imageUrl.contains('no_image'))
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppDesignConfig.cardRadius),
                  ),
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 200,
                      color: isDark ? AppColors.darkCard : Color(0xFFF2F2F7),
                      child: Icon(Icons.photo, color: Colors.grey, size: 60),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.source,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          article.timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (article.description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
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
      ),
    );
  }

  void _openNewsDetail(NewsArticle article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(
          article: article,
          allArticles: _tradingNews,
          currentIndex: _tradingNews.indexOf(article),
          isDark: isDark,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}