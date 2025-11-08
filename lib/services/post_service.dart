// lib/services/post_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../screens/image_viewer_screen.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<List<Post>> _controller = StreamController.broadcast();

  Stream<List<Post>> get stream => _controller.stream;

  // APIs organizadas por tipo
  static const _newsApiKeys = [
    'b2e4d59068e545abbdffaf947c371bcd',
    '4a8e3b2c9d1f5e7a6b4c8d2f9e1a5b3c',
  ];

  static const _newsdataKeys = [
    'pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c',
    'pub_8101437cf6db27e4bb3a5473976cdc86571fc',
  ];

  static const _gnewsKeys = [
    '5a3e9cdd12d67717cfb6643d25ebaeb5',
    '6faf083df1638391a56bb22c4f91e132',
  ];

  // Alpha Vantage para notícias financeiras
  static const _alphaVantageKeys = [
    'YOUR_ALPHA_VANTAGE_KEY',
  ];

  // Índice para rotação de APIs
  int _currentApiIndex = 0;

  StreamSubscription<QuerySnapshot>? _postsSub;
  Timer? _newsTimer;
  bool _started = false;
  List<Post> _posts = [];
  List<Post> _news = [];

  void ensureStarted() {
    if (_started) return;
    _started = true;
    _listenPosts();
    _fetchNewsOnce();
    // Atualiza notícias a cada 5 minutos
    _newsTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchNewsOnce());
  }

  void _listenPosts() {
    _postsSub = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      _posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      _emitCombined();
    }, onError: (e) {
      _controller.addError(e);
    });
  }

  Future<void> _fetchNewsOnce() async {
    try {
      final List<Post> results = [];
      final Set<String> seenUrls = {};

      // Rotaciona entre as APIs para evitar repetição
      switch (_currentApiIndex % 6) {
        case 0:
          await _fetchNewsAPI(results, seenUrls);
          break;
        case 1:
          await _fetchNewsAPITopHeadlines(results, seenUrls);
          break;
        case 2:
          await _fetchGNews(results, seenUrls);
          break;
        case 3:
          await _fetchNewsData(results, seenUrls);
          break;
        case 4:
          await _fetchFinancialNews(results, seenUrls);
          break;
        case 5:
          await _fetchTechNews(results, seenUrls);
          break;
      }

      _currentApiIndex++;

      // Ordena por data
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Remove duplicatas e limita
      _news = results.take(50).toList();
      _emitCombined();

      print('✅ Notícias carregadas: ${_news.length} (API Index: ${_currentApiIndex - 1})');
    } catch (e) {
      print('❌ Erro ao buscar notícias: $e');
    }
  }

  // NewsAPI - Everything
  Future<void> _fetchNewsAPI(List<Post> results, Set<String> seenUrls) async {
    final queries = ['stocks', 'cryptocurrency', 'trading', 'business'];
    
    for (final query in queries) {
      if (results.length >= 50) break;

      for (final key in _newsApiKeys) {
        try {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final dateStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
          
          final uri = Uri.parse(
            'https://newsapi.org/v2/everything?q=$query&from=$dateStr&sortBy=publishedAt&pageSize=25&apiKey=$key',
          );
          final resp = await http.get(uri).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;
              if (it['title'] == null || it['title'].toString().contains('[Removed]')) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['urlToImage'];
              results.add(Post(
                id: newsUrl,
                userId: 'newsapi_$query',
                userName: it['source']?['name'] ?? 'News',
                userAvatar: null,
                content: it['description'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 50) break;
            }
            break;
          }
        } catch (e) {
          print('NewsAPI error: $e');
          continue;
        }
      }
    }
  }

  // NewsAPI - Top Headlines
  Future<void> _fetchNewsAPITopHeadlines(List<Post> results, Set<String> seenUrls) async {
    final categories = ['business', 'technology', 'science'];
    
    for (final category in categories) {
      if (results.length >= 50) break;

      for (final key in _newsApiKeys) {
        try {
          final uri = Uri.parse(
            'https://newsapi.org/v2/top-headlines?category=$category&language=en&pageSize=20&apiKey=$key',
          );
          final resp = await http.get(uri).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;
              if (it['title'] == null || it['title'].toString().contains('[Removed]')) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['urlToImage'];
              results.add(Post(
                id: newsUrl,
                userId: 'newsapi_headlines_$category',
                userName: it['source']?['name'] ?? 'Top News',
                userAvatar: null,
                content: it['description'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 50) break;
            }
            break;
          }
        } catch (e) {
          print('NewsAPI Headlines error: $e');
          continue;
        }
      }
    }
  }

  // GNews
  Future<void> _fetchGNews(List<Post> results, Set<String> seenUrls) async {
    final topics = ['business', 'technology', 'sports', 'entertainment'];
    
    for (final topic in topics) {
      if (results.length >= 50) break;

      for (final key in _gnewsKeys) {
        try {
          final uri = Uri.parse(
            'https://gnews.io/api/v4/top-headlines?category=$topic&token=$key&lang=en&max=15',
          );
          final resp = await http.get(uri).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['image'];
              results.add(Post(
                id: newsUrl,
                userId: 'gnews_$topic',
                userName: it['source']?['name'] ?? 'GNews',
                userAvatar: null,
                content: it['description'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 50) break;
            }
            break;
          }
        } catch (e) {
          print('GNews error: $e');
          continue;
        }
      }
    }
  }

  // NewsData.io
  Future<void> _fetchNewsData(List<Post> results, Set<String> seenUrls) async {
    final categories = ['business', 'technology', 'sports'];
    
    for (final category in categories) {
      if (results.length >= 50) break;

      for (final key in _newsdataKeys) {
        try {
          final url = Uri.parse(
            'https://newsdata.io/api/1/news?apikey=$key&language=en&category=$category',
          );
          final resp = await http.get(url).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['results'] ?? [];

            for (var it in items) {
              final newsUrl = it['link'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['image_url'];
              results.add(Post(
                id: newsUrl.toString(),
                userId: 'newsdata_$category',
                userName: 'NewsData',
                userAvatar: null,
                content: (it['description'] ?? '').toString(),
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null' 
                    ? [imageUrl.toString()] 
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'],
                timestamp: (it['pubDate'] != null)
                    ? DateTime.tryParse(it['pubDate']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 50) break;
            }
            break;
          }
        } catch (e) {
          print('NewsData error: $e');
          continue;
        }
      }
    }
  }

  // Notícias Financeiras (Alpha Vantage, MarketWatch, etc)
  Future<void> _fetchFinancialNews(List<Post> results, Set<String> seenUrls) async {
    // Usando NewsAPI com queries financeiras específicas
    final queries = ['stock market', 'forex', 'crypto', 'nasdaq', 'dow jones'];
    
    for (final query in queries) {
      if (results.length >= 50) break;

      for (final key in _newsApiKeys) {
        try {
          final uri = Uri.parse(
            'https://newsapi.org/v2/everything?q=$query&domains=bloomberg.com,reuters.com,marketwatch.com&sortBy=publishedAt&pageSize=10&apiKey=$key',
          );
          final resp = await http.get(uri).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;
              if (it['title'] == null || it['title'].toString().contains('[Removed]')) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['urlToImage'];
              results.add(Post(
                id: newsUrl,
                userId: 'financial_$query',
                userName: it['source']?['name'] ?? 'Financial News',
                userAvatar: null,
                content: it['description'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 50) break;
            }
            break;
          }
        } catch (e) {
          print('Financial News error: $e');
          continue;
        }
      }
    }
  }

  // Notícias de Tecnologia (TechCrunch, etc)
  Future<void> _fetchTechNews(List<Post> results, Set<String> seenUrls) async {
    for (final key in _newsApiKeys) {
      try {
        final uri = Uri.parse(
          'https://newsapi.org/v2/top-headlines?sources=techcrunch,the-verge,wired,ars-technica&apiKey=$key',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final List items = json['articles'] ?? [];

          for (var it in items) {
            final newsUrl = it['url'];
            if (newsUrl == null || seenUrls.contains(newsUrl)) continue;
            if (it['title'] == null || it['title'].toString().contains('[Removed]')) continue;

            seenUrls.add(newsUrl);

            final imageUrl = it['urlToImage'];
            results.add(Post(
              id: newsUrl,
              userId: 'tech_news',
              userName: it['source']?['name'] ?? 'Tech News',
              userAvatar: null,
              content: it['description'] ?? '',
              imageBase64: null,
              imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                  ? [imageUrl.toString()]
                  : [],
              videoUrl: null,
              isNews: true,
              newsUrl: newsUrl,
              title: it['title'],
              summary: it['description'],
              timestamp: it['publishedAt'] != null
                  ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                  : DateTime.now(),
            ));

            if (results.length >= 50) break;
          }
          break;
        }
      } catch (e) {
        print('Tech News error: $e');
        continue;
      }
    }
  }

  void _emitCombined() {
    final List<Post> combined = [];

    // Intercala posts e notícias
    int postIndex = 0;
    int newsIndex = 0;

    while (postIndex < _posts.length || newsIndex < _news.length) {
      // Adiciona 2 posts
      for (int i = 0; i < 2 && postIndex < _posts.length; i++) {
        combined.add(_posts[postIndex++]);
      }

      // Adiciona 1 notícia
      if (newsIndex < _news.length) {
        combined.add(_news[newsIndex++]);
      }
    }

    _controller.add(combined);
  }

  void openImageViewer(BuildContext context, List<String> imageUrls, String initialUrl) {
    if (imageUrls.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ImageViewerScreen(
          imageUrls: imageUrls,
          initialUrl: initialUrl,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> createPost({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    String? imageBase64,
    String? videoUrl,
  }) async {
    try {
      await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'imageBase64': imageBase64,
        'imageUrls': imageBase64 != null ? [] : null,
        'videoUrl': videoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'likedBy': [],
        'isNews': false,
      });
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    final docRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likes = (data['likes'] as int?) ?? 0;
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        tx.update(docRef, {'likedBy': likedBy, 'likes': likes - 1});
      } else {
        likedBy.add(uid);
        tx.update(docRef, {'likedBy': likedBy, 'likes': likes + 1});
      }
    });
  }

  Future<void> sharePost(Post post) async {
    final ref = _firestore.collection('posts').doc(post.id);
    await ref.update({'shares': FieldValue.increment(1)});
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  void dispose() {
    _postsSub?.cancel();
    _newsTimer?.cancel();
    _controller.close();
  }
}