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

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  List<NewsArticle> allNews = [];
  List<NewsArticle> filteredNews = [];
  List<SheetStory> sheets = [];
  bool isLoading = true;
  bool isLoadingSheets = true;
  bool hasSheets = false;
  String selectedCategory = 'all';
  late TabController _tabController;

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
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedCategory = categories[_tabController.index]['id']!;
          filterNewsByCategory();
        });
      }
    });
    loadAllContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadAllContent() async {
    setState(() {
      isLoading = true;
      isLoadingSheets = true;
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

  Future<void> loadSheets() async {
    try {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/data/SHEETS/sheets.json'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['sheets'] != null) {
          final sheetsList = (data['sheets'] as List)
              .map((sheet) => SheetStory.fromJson(sheet))
              .toList();

          setState(() {
            sheets = sheetsList;
            hasSheets = sheets.isNotEmpty;
            isLoadingSheets = false;
          });
        } else {
          setState(() {
            sheets = [];
            hasSheets = false;
            isLoadingSheets = false;
          });
        }
      } else {
        setState(() {
          sheets = [];
          hasSheets = false;
          isLoadingSheets = false;
        });
      }
    } catch (e) {
      setState(() {
        sheets = [];
        hasSheets = false;
        isLoadingSheets = false;
      });
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
    final backgroundColor = isDark ? Color(0xFF000000) : Color(0xFFF2F2F7);
    final cardColor = isDark ? Color(0xFF1C1C1E) : CupertinoColors.white;
    final secondaryBg = isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA);

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: isDark ? Color(0xFF000000).withOpacity(0.9) : CupertinoColors.white.withOpacity(0.9),
            border: Border(bottom: BorderSide(color: isDark ? Color(0xFF38383A) : Color(0xFFD1D1D6), width: 0.5)),
            largeTitle: Text(
              'Notícias',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            trailing: isLoadingSheets
                ? CupertinoActivityIndicator(radius: 10)
                : (hasSheets
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill, 
                        color: CupertinoColors.systemGreen, 
                        size: 22
                      )
                    : null),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: loadAllContent,
          ),
          if (hasSheets && sheets.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: cardColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
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
                              margin: EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFFFF3B30).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(3),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cardColor,
                                      ),
                                      padding: EdgeInsets.all(2),
                                      child: ClipOval(
                                        child: sheet.imageUrl.isNotEmpty
                                            ? Image.network(
                                                sheet.imageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CupertinoActivityIndicator(radius: 8),
                                                  );
                                                },
                                                errorBuilder: (context, error, stack) => Container(
                                                  color: Color(0xFFFF3B30),
                                                  child: Icon(
                                                    CupertinoIcons.photo_fill,
                                                    color: CupertinoColors.white,
                                                    size: 28,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Color(0xFFFF3B30),
                                                child: Icon(
                                                  CupertinoIcons.photo_fill,
                                                  color: CupertinoColors.white,
                                                  size: 28,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  SizedBox(
                                    width: 68,
                                    child: Text(
                                      sheet.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Color(0xFFFF3B30),
                indicatorWeight: 2.5,
                labelColor: isDark ? CupertinoColors.white : CupertinoColors.black,
                unselectedLabelColor: CupertinoColors.systemGrey,
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
                padding: EdgeInsets.zero,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 8),
                labelPadding: EdgeInsets.symmetric(horizontal: 20),
                tabs: categories.map((category) => Tab(text: category['name'])).toList(),
              ),
              isDark: isDark,
              backgroundColor: cardColor,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(
                        radius: 16,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  )
                : filteredNews.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
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
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == 0 && filteredNews.isNotEmpty) {
                              return _buildFeaturedCard(filteredNews[0], isDark, cardColor);
                            }
                            return _buildNewsCard(filteredNews[index], isDark, cardColor);
                          },
                          childCount: filteredNews.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article, bool isDark, Color cardColor) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.12),
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
              article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
                        child: Icon(CupertinoIcons.photo, size: 60, color: CupertinoColors.systemGrey),
                      ),
                    )
                  : Container(
                      color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
                      child: Icon(CupertinoIcons.news, size: 60, color: CupertinoColors.systemGrey),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      CupertinoColors.black.withOpacity(0.3),
                      CupertinoColors.black.withOpacity(0.85),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF3B30).withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
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
                    Text(
                      article.title,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, color: CupertinoColors.white.withOpacity(0.85), size: 15),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            article.timeAgo,
                            style: TextStyle(color: CupertinoColors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(CupertinoIcons.doc_text_fill, color: CupertinoColors.white.withOpacity(0.85), size: 15),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            article.source,
                            style: TextStyle(color: CupertinoColors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
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

  Widget _buildNewsCard(NewsArticle article, bool isDark, Color cardColor) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: article.imageUrl.isNotEmpty
                    ? Image.network(
                        article.imageUrl,
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: 130,
                          height: 130,
                          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
                          child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 36),
                        ),
                      )
                    : Container(
                        width: 130,
                        height: 130,
                        color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
                        child: Icon(CupertinoIcons.news, color: CupertinoColors.systemGrey, size: 36),
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
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF3B30).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              article.category.toUpperCase(),
                              style: TextStyle(
                                color: Color(0xFFFF3B30),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            article.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(CupertinoIcons.time, size: 13, color: CupertinoColors.systemGrey),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              article.timeAgo,
                              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey, fontWeight: FontWeight.w500),
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;
  final Color backgroundColor;

  _TabBarDelegate({
    required this.tabBar,
    required this.isDark,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF38383A) : Color(0xFFD1D1D6),
            width: 0.5,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || isDark != oldDelegate.isDark;
  }
}