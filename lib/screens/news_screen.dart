import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NewsArticle> allNews = [];
  List<NewsArticle> filteredNews = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  List<ApiConfig> apiConfigs = [];
  
  final List<String> categories = [
    'all',
    'business',
    'technology',
    'sports',
    'entertainment',
    'health',
    'science',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    loadApiConfigs();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        selectedCategory = categories[_tabController.index];
        filterNewsByCategory();
      });
    }
  }

  Future<void> loadApiConfigs() async {
    try {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/data/API/apis.json'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        apiConfigs = (data['apis'] as List)
            .map((api) => ApiConfig.fromJson(api))
            .toList();
      }
    } catch (e) {
      print('Erro ao carregar APIs: $e');
    }
    
    await loadAllNews();
  }

  Future<void> loadAllNews() async {
    setState(() => isLoading = true);
    
    List<NewsArticle> newsFromSources = [];
    
    // Carregar notícias personalizadas
    newsFromSources.addAll(await loadCustomNews());
    
    // Carregar notícias das APIs
    for (var apiConfig in apiConfigs) {
      if (apiConfig.enabled) {
        newsFromSources.addAll(await fetchNewsFromApi(apiConfig));
      }
    }
    
    // Ordenar por data (mais recentes primeiro)
    newsFromSources.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    setState(() {
      allNews = newsFromSources;
      filterNewsByCategory();
      isLoading = false;
    });
  }

  Future<List<NewsArticle>> loadCustomNews() async {
    List<NewsArticle> customNews = [];
    
    for (int i = 1; i <= 5; i++) {
      try {
        final url = i == 1 
            ? 'https://alfredoooh.github.io/database/data/News/news.json'
            : 'https://alfredoooh.github.io/database/data/News/news$i.json';
            
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final articles = (data['articles'] as List)
              .map((article) => NewsArticle.fromCustomJson(article))
              .toList();
          customNews.addAll(articles);
        }
      } catch (e) {
        if (i == 1) print('Erro ao carregar notícias personalizadas: $e');
        break;
      }
    }
    
    return customNews;
  }

  Future<List<NewsArticle>> fetchNewsFromApi(ApiConfig apiConfig) async {
    try {
      String url = '';
      
      if (apiConfig.type == 'newsdata') {
        url = 'https://newsdata.io/api/1/news?apikey=${apiConfig.key}&language=pt&country=br';
      } else if (apiConfig.type == 'newsapi') {
        url = 'https://newsapi.org/v2/top-headlines?apiKey=${apiConfig.key}&country=br';
      } else if (apiConfig.type == 'gnews') {
        url = 'https://gnews.io/api/v4/top-headlines?token=${apiConfig.key}&lang=pt&country=br';
      } else if (apiConfig.type == 'newsmonitor') {
        url = apiConfig.key;
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return parseNewsFromApi(data, apiConfig.type);
      }
    } catch (e) {
      print('Erro ao buscar notícias de ${apiConfig.name}: $e');
    }
    
    return [];
  }

  List<NewsArticle> parseNewsFromApi(Map<String, dynamic> data, String apiType) {
    List<NewsArticle> articles = [];
    
    try {
      if (apiType == 'newsdata') {
        final results = data['results'] as List? ?? [];
        articles = results.map((article) => NewsArticle.fromNewsdata(article)).toList();
      } else if (apiType == 'newsapi') {
        final results = data['articles'] as List? ?? [];
        articles = results.map((article) => NewsArticle.fromNewsApi(article)).toList();
      } else if (apiType == 'gnews') {
        final results = data['articles'] as List? ?? [];
        articles = results.map((article) => NewsArticle.fromGNews(article)).toList();
      }
    } catch (e) {
      print('Erro ao parsear notícias: $e');
    }
    
    return articles;
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
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
              elevation: 0,
              floating: true,
              pinned: true,
              snap: false,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Notícias',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                centerTitle: false,
                titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black87),
                  onPressed: loadAllNews,
                ),
                IconButton(
                  icon: Icon(Icons.search_rounded, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => _showSearchDialog(context, isDark),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: Container(
                  color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Color(0xFFFF444F),
                    indicatorWeight: 3,
                    labelColor: Color(0xFFFF444F),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: [
                      Tab(text: 'Todas'),
                      Tab(text: 'Negócios'),
                      Tab(text: 'Tecnologia'),
                      Tab(text: 'Esportes'),
                      Tab(text: 'Entretenimento'),
                      Tab(text: 'Saúde'),
                      Tab(text: 'Ciência'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFF444F)),
                    SizedBox(height: 16),
                    Text(
                      'Carregando notícias...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : filteredNews.isEmpty
                ? _buildEmptyState(isDark)
                : RefreshIndicator(
                    color: Color(0xFFFF444F),
                    onRefresh: loadAllNews,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredNews.length,
                      itemBuilder: (context, index) {
                        if (index == 0 && filteredNews.isNotEmpty) {
                          return _buildFeaturedCard(filteredNews[0], isDark);
                        }
                        return _buildNewsCard(filteredNews[index], isDark);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () => _showArticleDetail(article, isDark),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                        color: isDark ? Color(0xFF1A1A1A) : Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: isDark ? Color(0xFF1A1A1A) : Colors.grey[300],
                      child: Icon(Icons.article, size: 50, color: Colors.grey),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
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
                      color: Colors.white,
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
                        color: Colors.white,
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
                        Icon(Icons.access_time, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          article.timeAgo,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.source, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            article.source,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
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
      onTap: () => _showArticleDetail(article, isDark),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                        color: isDark ? Color(0xFF0E0E0E) : Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: isDark ? Color(0xFF0E0E0E) : Colors.grey[200],
                      child: Icon(Icons.article, color: Colors.grey),
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
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          article.timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma notícia encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tente outra categoria ou atualize',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        title: Text('Buscar Notícias', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Digite sua busca...',
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.search, color: Color(0xFFFF444F)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFFF444F)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF444F)),
            child: Text('Buscar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showArticleDetail(NewsArticle article, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (article.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    article.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  article.category.toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFFFF444F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.source, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    article.source,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    article.timeAgo,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                article.description,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.open_in_new),
                label: Text('Ler Notícia Completa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF444F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class NewsArticle {
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final String category;
  final DateTime publishedAt;
  final String url;

  NewsArticle({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    required this.category,
    required this.publishedAt,
    required this.url,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(publishedAt);
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}sem atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }

  factory NewsArticle.fromCustomJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['imageUrl'] ?? '',
      source: json['source'] ?? 'Desconhecido',
      category: json['category'] ?? 'all',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      url: json['url'] ?? '',
    );
  }

  factory NewsArticle.fromNewsdata(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['image_url'] ?? '',
      source: json['source_id'] ?? 'Desconhecido',
      category: (json['category'] != null && json['category'].isNotEmpty) 
          ? json['category'][0] 
          : 'all',
      publishedAt: DateTime.parse(json['pubDate'] ?? DateTime.now().toIso8601String()),
      url: json['link'] ?? '',
    );
  }

  factory NewsArticle.fromNewsApi(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['urlToImage'] ?? '',
      source: json['source']['name'] ?? 'Desconhecido',
      category: 'all',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      url: json['url'] ?? '',
    );
  }

  factory NewsArticle.fromGNews(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['image'] ?? '',
      source: json['source']['name'] ?? 'Desconhecido',
      category: 'all',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      url: json['url'] ?? '',
    );
  }
}

class ApiConfig {
  final String name;
  final String type;
  final String key;
  final bool enabled;

  ApiConfig({
    required this.name,
    required this.type,
    required this.key,
    required this.enabled,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      key: json['key'] ?? '',
      enabled: json['enabled'] ?? true,
    );
  }
}