import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:io' show HttpDate;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../../models/news_stories_models.dart';
import 'stories_tab/story_viewer_screen.dart';
import 'stories_tab/news_detail_screen.dart';
import 'stories_tab/channels_screen.dart';
import 'stories_tab/new_screen.dart';

class StoriesTab extends StatefulWidget {
  const StoriesTab({Key? key}) : super(key: key);

  @override
  State<StoriesTab> createState() => _StoriesTabState();
}

class _StoriesTabState extends State<StoriesTab> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'Todos';
  final Set<String> _viewedStories = {};
  final Set<String> _likedNews = {};
  List<Story> _stories = [];
  List<NewsStory> _news = [];
  bool _isLoading = true;
  bool _isFabExpanded = true;
  
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<String> _categories = [
    'Todos',
    'Tecnologia',
    'Esportes',
    'Mundo',
    'Entretenimento',
    'Ciência',
    'Negócios',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupFabAnimation();
    _scrollController.addListener(_onScroll);
  }

  void _setupFabAnimation() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _isFabExpanded) {
      setState(() => _isFabExpanded = false);
      _fabAnimationController.reverse();
    } else if (_scrollController.offset <= 50 && !_isFabExpanded) {
      setState(() => _isFabExpanded = true);
      _fabAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadStories(),
        _loadNews(),
      ]);
    } catch (e) {
      print('Erro ao carregar dados: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadStories() async {
    try {
      // Load stories from original source
      try {
        final response = await http.get(
          Uri.parse('https://alfredoooh.github.io/database/data/stories/stories.json'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          List<Story> stories = data.map((json) => Story.fromJson(json)).toList();
          setState(() {
            _stories = stories;
          });
        }
      } catch (e) {
        print('Erro ao carregar stories originais: $e');
      }

      // Load additional stories APIs
      try {
        final apiListResponse = await http.get(
          Uri.parse('https://alfredoooh.github.io/database/services/api_services/stories_api_list.json'),
        );

        if (apiListResponse.statusCode == 200) {
          final List<dynamic> apiList = json.decode(apiListResponse.body);
          
          for (var api in apiList) {
            try {
              final apiResponse = await http.get(
                Uri.parse(api['url']),
                headers: {'User-Agent': 'Mozilla/5.0'},
              ).timeout(const Duration(seconds: 10));
              
              if (apiResponse.statusCode == 200) {
                List<Story> newStories = [];
                
                if (api['type'] == 'rss') {
                  newStories = await _parseStoriesFromRss(apiResponse.body, api['name']);
                } else {
                  final apiData = json.decode(apiResponse.body);
                  newStories = _parseStoriesFromApi(apiData, api['type']);
                }
                
                setState(() {
                  _stories.addAll(newStories);
                });
              }
            } catch (e) {
              print('Erro ao carregar API ${api['name']}: $e');
            }
          }
        }
      } catch (e) {
        print('Erro ao carregar lista de APIs de stories: $e');
      }
    } catch (e) {
      print('Erro geral ao carregar stories: $e');
    }
  }

  Future<List<Story>> _parseStoriesFromRss(String xmlString, String sourceName) async {
    List<Story> stories = [];
    
    try {
      final document = XmlDocument.parse(xmlString);
      final items = document.findAllElements('item').take(5);
      
      for (var item in items) {
        String? imageUrl;
        
        // Try to find image in enclosure
        final enclosure = item.findElements('enclosure').firstOrNull;
        if (enclosure != null) {
          imageUrl = enclosure.getAttribute('url');
        }
        
        // Try to find image in content/description
        if (imageUrl == null || imageUrl.isEmpty) {
          final content = item.findElements('content:encoded').firstOrNull?.innerText ?? 
                         item.findElements('description').firstOrNull?.innerText ?? '';
          imageUrl = _extractImageFromContent(content);
        }
        
        // Use placeholder if no image found
        imageUrl ??= 'https://via.placeholder.com/300';
        
        final link = item.findElements('link').firstOrNull?.innerText ?? 
                     DateTime.now().millisecondsSinceEpoch.toString();
        
        stories.add(Story(
          id: link,
          category: _extractCategoryFromSource(sourceName),
          imageUrl: imageUrl,
          videoUrl: null,
          duration: 15,
        ));
      }
    } catch (e) {
      print('Erro ao parsear RSS de $sourceName: $e');
    }
    
    return stories;
  }

  String? _extractImageFromContent(String content) {
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegex.firstMatch(content);
    return match?.group(1);
  }

  String _extractCategoryFromSource(String source) {
    final lowerSource = source.toLowerCase();
    if (lowerSource.contains('tech') || lowerSource.contains('wired') || 
        lowerSource.contains('verge') || lowerSource.contains('ars')) {
      return 'Tecnologia';
    }
    if (lowerSource.contains('sport') || lowerSource.contains('espn') || 
        lowerSource.contains('sky')) {
      return 'Esportes';
    }
    if (lowerSource.contains('business') || lowerSource.contains('forbes') || 
        lowerSource.contains('bloomberg') || lowerSource.contains('financial')) {
      return 'Negócios';
    }
    if (lowerSource.contains('entertainment') || lowerSource.contains('variety') || 
        lowerSource.contains('hollywood') || lowerSource.contains('rolling')) {
      return 'Entretenimento';
    }
    if (lowerSource.contains('science') || lowerSource.contains('nature') || 
        lowerSource.contains('space') || lowerSource.contains('nasa')) {
      return 'Ciência';
    }
    if (lowerSource.contains('ign') || lowerSource.contains('polygon')) {
      return 'Entretenimento';
    }
    return 'Mundo';
  }

  List<Story> _parseStoriesFromApi(dynamic data, String apiType) {
    List<Story> stories = [];
    
    try {
      if (apiType == 'newsdata') {
        final results = data['results'] as List;
        for (var item in results.take(5)) {
          stories.add(Story(
            id: item['article_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            category: _mapCategory(item['category']?[0] ?? 'Notícias'),
            imageUrl: item['image_url'] ?? 'https://via.placeholder.com/300',
            videoUrl: item['video_url'],
            duration: 15,
          ));
        }
      } else if (apiType == 'newsapi') {
        final articles = data['articles'] as List;
        for (var item in articles.take(5)) {
          stories.add(Story(
            id: item['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            category: _mapCategoryFromSource(item['source']['name'] ?? 'Notícias'),
            imageUrl: item['urlToImage'] ?? 'https://via.placeholder.com/300',
            videoUrl: null,
            duration: 15,
          ));
        }
      } else if (apiType == 'gnews') {
        final articles = data['articles'] as List;
        for (var item in articles.take(5)) {
          stories.add(Story(
            id: item['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            category: _mapCategoryFromSource(item['source']['name'] ?? 'Notícias'),
            imageUrl: item['image'] ?? 'https://via.placeholder.com/300',
            videoUrl: null,
            duration: 15,
          ));
        }
      } else if (apiType == 'newsmonitor') {
        if (data is List) {
          for (var item in data.take(5)) {
            stories.add(Story(
              id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              category: _mapCategory(item['category'] ?? 'Notícias'),
              imageUrl: item['image'] ?? item['imageUrl'] ?? 'https://via.placeholder.com/300',
              videoUrl: item['video'],
              duration: 15,
            ));
          }
        }
      }
    } catch (e) {
      print('Erro ao parsear stories do tipo $apiType: $e');
    }
    
    return stories;
  }

  Future<void> _loadNews() async {
    try {
      // Load news from original source
      try {
        final response = await http.get(
          Uri.parse('https://alfredoooh.github.io/database/data/stories/news.json'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          List<NewsStory> news = data.map((json) => NewsStory.fromJson(json)).toList();
          setState(() {
            _news = news;
          });
        }
      } catch (e) {
        print('Erro ao carregar news originais: $e');
      }

      // Load additional news APIs
      try {
        final apiListResponse = await http.get(
          Uri.parse('https://alfredoooh.github.io/database/services/api_services/news_api_list.json'),
        );

        if (apiListResponse.statusCode == 200) {
          final List<dynamic> apiList = json.decode(apiListResponse.body);
          
          for (var api in apiList) {
            try {
              final apiResponse = await http.get(
                Uri.parse(api['url']),
                headers: {'User-Agent': 'Mozilla/5.0'},
              ).timeout(const Duration(seconds: 10));
              
              if (apiResponse.statusCode == 200) {
                List<NewsStory> newNews = [];
                
                if (api['type'] == 'rss') {
                  newNews = await _parseNewsFromRss(apiResponse.body, api['name']);
                } else {
                  final apiData = json.decode(apiResponse.body);
                  newNews = _parseNewsFromApi(apiData, api['type']);
                }
                
                setState(() {
                  _news.addAll(newNews);
                });
              }
            } catch (e) {
              print('Erro ao carregar API ${api['name']}: $e');
            }
          }
        }
      } catch (e) {
        print('Erro ao carregar lista de APIs de news: $e');
      }
    } catch (e) {
      print('Erro geral ao carregar notícias: $e');
    }
  }

  Future<List<NewsStory>> _parseNewsFromRss(String xmlString, String sourceName) async {
    List<NewsStory> news = [];
    
    try {
      final document = XmlDocument.parse(xmlString);
      final items = document.findAllElements('item');
      
      for (var item in items) {
        String? imageUrl;
        
        // Try to find image in enclosure
        final enclosure = item.findElements('enclosure').firstOrNull;
        if (enclosure != null) {
          imageUrl = enclosure.getAttribute('url');
        }
        
        // Try to find image in content/description
        if (imageUrl == null || imageUrl.isEmpty) {
          final content = item.findElements('content:encoded').firstOrNull?.innerText ?? 
                         item.findElements('description').firstOrNull?.innerText ?? '';
          imageUrl = _extractImageFromContent(content);
        }
        
        imageUrl ??= 'https://via.placeholder.com/600x400';
        
        final title = item.findElements('title').firstOrNull?.innerText ?? 'Sem título';
        final link = item.findElements('link').firstOrNull?.innerText ?? 
                     DateTime.now().millisecondsSinceEpoch.toString();
        final description = item.findElements('description').firstOrNull?.innerText ?? '';
        final author = item.findElements('author').firstOrNull?.innerText ?? 
                      item.findElements('dc:creator').firstOrNull?.innerText ?? 
                      sourceName;
        
        // Parse publication date
        final pubDateStr = item.findElements('pubDate').firstOrNull?.innerText;
        DateTime publishedAt = DateTime.now();
        if (pubDateStr != null) {
          try {
            publishedAt = DateTime.parse(pubDateStr);
          } catch (e) {
            // If parsing fails, try HTTP date format
            try {
              publishedAt = HttpDate.parse(pubDateStr);
            } catch (_) {
              // Keep current DateTime if all parsing fails
            }
          }
        }
        
        news.add(NewsStory(
          id: link,
          title: title,
          category: _extractCategoryFromSource(sourceName),
          imageUrl: imageUrl,
          author: author,
          publishedAt: publishedAt,
          content: _cleanHtmlTags(description),
          source: sourceName,
        ));
      }
    } catch (e) {
      print('Erro ao parsear RSS news de $sourceName: $e');
    }
    
    return news;
  }

  String _cleanHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  List<NewsStory> _parseNewsFromApi(dynamic data, String apiType) {
    List<NewsStory> news = [];
    
    try {
      if (apiType == 'newsdata') {
        final results = data['results'] as List;
        for (var item in results) {
          news.add(NewsStory(
            id: item['article_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: item['title'] ?? 'Sem título',
            category: _mapCategory(item['category']?[0] ?? 'Notícias'),
            imageUrl: item['image_url'] ?? 'https://via.placeholder.com/600x400',
            author: item['creator']?[0] ?? item['source_id'] ?? 'Desconhecido',
            publishedAt: DateTime.parse(item['pubDate'] ?? DateTime.now().toIso8601String()),
            content: item['description'] ?? item['content'] ?? '',
            source: item['source_id'] ?? 'Unknown',
          ));
        }
      } else if (apiType == 'newsapi') {
        final articles = data['articles'] as List;
        for (var item in articles) {
          news.add(NewsStory(
            id: item['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: item['title'] ?? 'Sem título',
            category: _mapCategoryFromSource(item['source']['name']),
            imageUrl: item['urlToImage'] ?? 'https://via.placeholder.com/600x400',
            author: item['author'] ?? item['source']['name'] ?? 'Desconhecido',
            publishedAt: DateTime.parse(item['publishedAt'] ?? DateTime.now().toIso8601String()),
            content: item['description'] ?? item['content'] ?? '',
            source: item['source']['name'] ?? 'Unknown',
          ));
        }
      } else if (apiType == 'gnews') {
        final articles = data['articles'] as List;
        for (var item in articles) {
          news.add(NewsStory(
            id: item['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: item['title'] ?? 'Sem título',
            category: _mapCategoryFromSource(item['source']['name']),
            imageUrl: item['image'] ?? 'https://via.placeholder.com/600x400',
            author: item['source']['name'] ?? 'Desconhecido',
            publishedAt: DateTime.parse(item['publishedAt'] ?? DateTime.now().toIso8601String()),
            content: item['description'] ?? item['content'] ?? '',
            source: item['source']['name'] ?? 'Unknown',
          ));
        }
      } else if (apiType == 'newsmonitor') {
        if (data is List) {
          for (var item in data) {
            news.add(NewsStory(
              id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: item['title'] ?? 'Sem título',
              category: _mapCategory(item['category'] ?? 'Notícias'),
              imageUrl: item['image'] ?? item['imageUrl'] ?? 'https://via.placeholder.com/600x400',
              author: item['author'] ?? item['source'] ?? 'Desconhecido',
              publishedAt: DateTime.parse(item['publishedAt'] ?? item['date'] ?? DateTime.now().toIso8601String()),
              content: item['content'] ?? item['description'] ?? '',
              source: item['source'] ?? 'NewsMonitor',
            ));
          }
        }
      }
    } catch (e) {
      print('Erro ao parsear news do tipo $apiType: $e');
    }
    
    return news;
  }

  String _mapCategory(String category) {
    final categoryMap = {
      'technology': 'Tecnologia',
      'tech': 'Tecnologia',
      'sports': 'Esportes',
      'sport': 'Esportes',
      'business': 'Negócios',
      'entertainment': 'Entretenimento',
      'science': 'Ciência',
      'world': 'Mundo',
      'politics': 'Mundo',
      'health': 'Ciência',
    };
    
    return categoryMap[category.toLowerCase()] ?? 'Mundo';
  }

  String _mapCategoryFromSource(String source) {
    final lowerSource = source.toLowerCase();
    if (lowerSource.contains('tech') || lowerSource.contains('wired') || 
        lowerSource.contains('verge') || lowerSource.contains('canaltech') ||
        lowerSource.contains('olhar digital') || lowerSource.contains('tecmundo')) {
      return 'Tecnologia';
    }
    if (lowerSource.contains('sport') || lowerSource.contains('espn') || 
        lowerSource.contains('lance') || lowerSource.contains('ge.globo')) {
      return 'Esportes';
    }
    if (lowerSource.contains('business') || lowerSource.contains('forbes') || 
        lowerSource.contains('bloomberg') || lowerSource.contains('infomoney') ||
        lowerSource.contains('exame') || lowerSource.contains('valor')) {
      return 'Negócios';
    }
    if (lowerSource.contains('entertainment') || lowerSource.contains('variety') ||
        lowerSource.contains('hollywood')) {
      return 'Entretenimento';
    }
    if (lowerSource.contains('science') || lowerSource.contains('nature') ||
        lowerSource.contains('nasa') || lowerSource.contains('space')) {
      return 'Ciência';
    }
    return 'Mundo';
  }

  List<NewsStory> get _filteredNews {
    if (_selectedCategory == 'Todos') {
      return _news;
    }
    return _news.where((news) => news.category == _selectedCategory).toList();
  }

  void _viewStory(Story story, int index) {
    setState(() {
      _viewedStories.add(story.id);
    });

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => StoryViewerScreen(
          stories: _stories,
          initialIndex: index,
        ),
      ),
    );
  }

  void _toggleLike(String newsId) {
    setState(() {
      if (_likedNews.contains(newsId)) {
        _likedNews.remove(newsId);
      } else {
        _likedNews.add(newsId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: Color(0xFF000000),
        child: Center(
          child: CupertinoActivityIndicator(
            color: Color(0xFF007AFF),
            radius: 20,
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _loadData,
              ),
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildStoriesRow()),
              SliverToBoxAdapter(child: _buildChannelsButton()),
              SliverToBoxAdapter(child: _buildCategoryFilter()),
              SliverToBoxAdapter(child: _buildNewsList()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _buildFab(),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const NewScreen(),
                ),
              );
            },
            child: Container(
              height: 56,
              width: _isFabExpanded ? 160 : 56,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (_isFabExpanded) ...[
                    SizedBox(width: 8 * _fabAnimation.value),
                    Opacity(
                      opacity: _fabAnimation.value,
                      child: const Text(
                        'Nova Screen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Atualidade',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fique por dentro das novidades',
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_stories.length} stories • ${_news.length} notícias',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow() {
    if (_stories.isEmpty) {
      return const SizedBox(height: 120);
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          final isViewed = _viewedStories.contains(story.id);

          return GestureDetector(
            onTap: () => _viewStory(story, index),
            child: Container(
              width: 85,
              margin: EdgeInsets.only(right: index == _stories.length - 1 ? 0 : 12),
              child: Column(
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isViewed
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      border: isViewed
                          ? Border.all(color: const Color(0xFF3A3A3C), width: 2)
                          : null,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF000000), width: 3),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          story.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1C1C1E),
                            child: const Icon(
                              CupertinoIcons.photo,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story.category,
                    style: TextStyle(
                      color: isViewed ? const Color(0xFF8E8E93) : const Color(0xFFFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelsButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const ChannelsScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF007AFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.layers_alt_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canais',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Explore canais de trading e educação',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: index == _categories.length - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    if (_filteredNews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.news,
                size: 64,
                color: const Color(0xFF8E8E93),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma notícia encontrada',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: _filteredNews.map((news) {
          return _buildNewsCard(news);
        }).toList(),
      ),
    );
  }

  Widget _buildNewsCard(NewsStory news) {
    final isLiked = _likedNews.contains(news.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => NewsDetailScreen(
              news: news,
              isLiked: isLiked,
              onLikeToggle: () => _toggleLike(news.id),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    news.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFF2C2C2E),
                      child: const Icon(
                        CupertinoIcons.photo,
                        color: Color(0xFF8E8E93),
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news.category,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_circle,
                        color: Color(0xFF8E8E93),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          news.author,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        CupertinoIcons.time,
                        color: Color(0xFF8E8E93),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(news.publishedAt),
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
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
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}