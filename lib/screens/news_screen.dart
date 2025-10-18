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
import '../widgets/app_colors.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/post_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NewsService _newsService = NewsService();

  List<NewsArticle> _tradingNews = [];
  List<SheetStory> _sheets = [];
  List<QueryDocumentSnapshot> _allSheets = [];
  bool _loadingNews = true;
  bool _loadingSheets = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      // Remove duplicatas baseado em título e URL
      final uniqueNews = <String, NewsArticle>{};
      for (var article in allNews) {
        final key = '${article.title}_${article.url}';
        if (!uniqueNews.containsKey(key)) {
          uniqueNews[key] = article;
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
      appBar: AppPrimaryAppBar(
        title: 'Atualidade',
      ),
      body: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
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

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        tabs: [
          Tab(text: 'Sheets'),
          Tab(text: 'Trading News'),
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
      return _buildEmptyState(
        icon: Icons.article_outlined,
        message: 'Nenhum sheet disponível',
        isDark: isDark,
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
      return _buildEmptyState(
        icon: Icons.newspaper_outlined,
        message: 'Nenhuma notícia disponível',
        isDark: isDark,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.withOpacity(0.4),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openNewsDetail(article),
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
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
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(isDark),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImagePlaceholder(isDark);
                    },
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.source,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4),
                        Text(
                          article.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (article.description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
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

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: 200,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade400,
          size: 48,
        ),
      ),
    );
  }

  void _openNewsDetail(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(
          article: article,
          allArticles: _tradingNews,
          currentIndex: _tradingNews.indexOf(article),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}