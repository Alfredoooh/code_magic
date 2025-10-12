import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'news_detail_screen.dart';
import 'sheets_viewer_screen.dart';
import '../models/news_article.dart';
import '../models/sheet_story.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> allNews = [];
  List<NewsArticle> filteredNews = [];
  List<SheetStory> sheets = [];
  bool isLoading = true;
  bool hasSheets = false;
  String selectedCategory = 'all';

  final List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'Todas'},
    {'id': 'business', 'name': 'Negócios'},
    {'id': 'technology', 'name': 'Tecnologia'},
    {'id': 'sports', 'name': 'Esportes'},
    {'id': 'entertainment', 'name': 'Entretenimento'},
    {'id': 'health', 'name': 'Saúde'},
    {'id': 'science', 'name': 'Ciência'},
  ];

  @override
  void initState() {
    super.initState();
    loadAllContent();
  }

  Future<void> loadAllContent() async {
    setState(() => isLoading = true);

    await Future.wait([
      loadAllNews(),
      loadSheets(),
    ]);

    setState(() => isLoading = false);
  }

  Future<void> loadSheets() async {
    try {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/data/SHEETS/sheets.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sheetsList = (data['sheets'] as List)
            .map((sheet) => SheetStory.fromJson(sheet))
            .toList();

        setState(() {
          sheets = sheetsList;
          hasSheets = sheets.isNotEmpty;
        });
      }
    } catch (e) {
      print('Erro ao carregar sheets: $e');
      setState(() => hasSheets = false);
    }
  }

  Future<void> loadAllNews() async {
    List<NewsArticle> newsFromSources = [];

    newsFromSources.addAll(await loadCustomNews());
    newsFromSources.addAll(await fetchNewsFromNewsdata());
    newsFromSources.addAll(await fetchNewsFromNewsApi());
    newsFromSources.addAll(await fetchNewsFromGNews());

    final uniqueNews = <String, NewsArticle>{};
    for (var article in newsFromSources) {
      if (!uniqueNews.containsKey(article.title)) {
        uniqueNews[article.title] = article;
      }
    }

    final sortedNews = uniqueNews.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    setState(() {
      allNews = sortedNews;
      filterNewsByCategory();
    });
  }

  Future<List<NewsArticle>> loadCustomNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/data/News/news.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['articles'] as List)
            .map((article) => NewsArticle.fromCustomJson(article))
            .toList();
      }
    } catch (e) {
      print('Erro ao carregar notícias personalizadas: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> fetchNewsFromNewsdata() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsdata.io/api/1/news?apikey=pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c&language=pt&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results.map((article) => NewsArticle.fromNewsdata(article)).toList();
      }
    } catch (e) {
      print('Erro Newsdata: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> fetchNewsFromNewsApi() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?apiKey=b2e4d59068e545abbdffaf947c371bcd&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) => NewsArticle.fromNewsApi(article)).toList();
      }
    } catch (e) {
      print('Erro NewsAPI: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> fetchNewsFromGNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://gnews.io/api/v4/top-headlines?token=5a3e9cdd12d67717cfb6643d25ebaeb5&lang=pt&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) => NewsArticle.fromGNews(article)).toList();
      }
    } catch (e) {
      print('Erro GNews: $e');
    }
    return [];
  }

  void filterNewsByCategory() {
    if (selectedCategory == 'all') {
      filteredNews = allNews;
    } else {
      filteredNews = allNews.where((news) => 
        news.category.toLowerCase() == selectedCategory.toLowerCase()
      ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        middle: Text(
          'Notícias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (hasSheets)
              Container(
                height: 110,
                color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: sheets.length,
                  itemBuilder: (context, index) {
                    final sheet = sheets[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => SheetsViewerScreen(
                              sheets: sheets,
                              initialIndex: index,
                            ),
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
                                border: Border.all(
                                  color: CupertinoColors.white,
                                  width: 3,
                                ),
                              ),
                              child: sheet.imageUrl.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        sheet.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) => Container(
                                          color: Color(0xFFFF444F),
                                          child: Icon(
                                            CupertinoIcons.photo,
                                            color: CupertinoColors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      CupertinoIcons.photo,
                                      color: CupertinoColors.white,
                                      size: 30,
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
                                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Container(
              height: 50,
              color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Color(0xFFFF444F) 
                              : (isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            category['name']!,
                            style: TextStyle(
                              color: isSelected 
                                  ? CupertinoColors.white 
                                  : (isDark ? CupertinoColors.white : CupertinoColors.black),
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        radius: 15,
                        color: Color(0xFFFF444F),
                      ),
                    )
                  : filteredNews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.news,
                                size: 80,
                                color: CupertinoColors.systemGrey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma notícia encontrada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            CupertinoSliverRefreshControl(
                              onRefresh: loadAllContent,
                            ),
                            SliverPadding(
                              padding: EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index == 0 && filteredNews.isNotEmpty) {
                                      return _buildFeaturedCard(filteredNews[0], isDark);
                                    }
                                    return _buildNewsCard(filteredNews[index], isDark);
                                  },
                                  childCount: filteredNews.length,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.systemGrey5,
                        child: Icon(CupertinoIcons.photo, size: 50, color: CupertinoColors.systemGrey),
                      ),
                    )
                  : Container(
                      color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.systemGrey5,
                      child: Icon(CupertinoIcons.news, size: 50, color: CupertinoColors.systemGrey),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CupertinoColors.black.withOpacity(0),
                      CupertinoColors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, color: CupertinoColors.white.withOpacity(0.7), size: 14),
                        SizedBox(width: 4),
                        Text(
                          article.timeAgo,
                          style: TextStyle(color: CupertinoColors.white.withOpacity(0.7), fontSize: 12),
                        ),
                        SizedBox(width: 12),
                        Icon(CupertinoIcons.doc_text, color: CupertinoColors.white.withOpacity(0.7), size: 14),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            article.source,
                            style: TextStyle(color: CupertinoColors.white.withOpacity(0.7), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildNewsCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
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
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 120,
                        height: 120,
                        color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                        child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                      child: Icon(CupertinoIcons.news, color: CupertinoColors.systemGrey),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF444F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFFFF444F),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, size: 12, color: CupertinoColors.systemGrey),
                        SizedBox(width: 4),
                        Text(
                          article.timeAgo,
                          style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
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
    );
  }

  void _openArticleDetail(NewsArticle article) {
    final articleIndex = filteredNews.indexOf(article);
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (context) => NewsDetailScreen(
          article: article,
          allArticles: filteredNews,
          currentIndex: articleIndex,
        ),
      ),
    );
  }
}