// lib/services/post_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../screens/image_viewer_screen.dart';

enum FeedFilter { mixed, postsOnly, newsOnly }

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

  StreamSubscription<QuerySnapshot>? _postsSub;
  Timer? _newsTimer;
  bool _started = false;
  List<Post> _posts = [];
  List<Post> _news = [];
  FeedFilter _currentFilter = FeedFilter.mixed;

  FeedFilter get currentFilter => _currentFilter;

  void setFilter(FeedFilter filter) {
    _currentFilter = filter;
    print('🔄 Filtro alterado para: $filter');
    _emitCombined();
  }

  void ensureStarted() {
    if (_started) return;
    _started = true;

    print('🚀 PostService iniciado');

    _listenPosts();
    _fetchNewsOnce();

    // Atualiza notícias a cada 5 minutos
    _newsTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      print('🔄 Atualizando notícias...');
      _fetchNewsOnce();
    });
  }

  void _listenPosts() {
    _postsSub = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      _posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      print('📝 Posts do Firestore: ${_posts.length}');
      _emitCombined();
    }, onError: (e) {
      print('❌ Erro ao escutar posts: $e');
      _controller.addError(e);
    });
  }

  Future<void> _fetchNewsOnce() async {
    print('📰 Iniciando busca de notícias...');

    try {
      final List<Post> results = [];
      final Set<String> seenUrls = {};

      // Tenta todas as APIs em paralelo
      await Future.wait([
        _fetchNewsAPI(results, seenUrls).catchError((e) {
          print('⚠️ NewsAPI falhou: $e');
        }),
        _fetchNewsAPITopHeadlines(results, seenUrls).catchError((e) {
          print('⚠️ NewsAPI Headlines falhou: $e');
        }),
        _fetchGNews(results, seenUrls).catchError((e) {
          print('⚠️ GNews falhou: $e');
        }),
        _fetchNewsData(results, seenUrls).catchError((e) {
          print('⚠️ NewsData falhou: $e');
        }),
      ]);

      if (results.isEmpty) {
        print('⚠️ Nenhuma notícia foi carregada das APIs');
        _news = [];
      } else {
        // Ordena por data
        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news = results.take(50).toList();
        print('✅ NOTÍCIAS CARREGADAS: ${_news.length}');
        for (int i = 0; i < _news.length && i < 3; i++) {
          print('   ➜ [${i + 1}] ${_news[i].title ?? _news[i].content.substring(0, 30)}');
        }
      }

      print('📊 Posts: ${_posts.length} | Notícias: ${_news.length}');
      _emitCombined();

    } catch (e) {
      print('❌ ERRO ao buscar notícias: $e');
      _news = [];
      _emitCombined();
    }
  }

  // NewsAPI - Everything
  Future<void> _fetchNewsAPI(List<Post> results, Set<String> seenUrls) async {
    final queries = ['technology', 'business', 'ai', 'science'];

    for (final query in queries) {
      if (results.length >= 40) break;

      for (final key in _newsApiKeys) {
        try {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final dateStr = yesterday.toIso8601String().split('T')[0];

          final uri = Uri.parse(
            'https://newsapi.org/v2/everything?q=$query&from=$dateStr&sortBy=publishedAt&pageSize=20&language=en&apiKey=$key',
          );

          print('🌐 Requisição NewsAPI ($query)...');
          final resp = await http.get(uri).timeout(const Duration(seconds: 12));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            print('✓ NewsAPI ($query): ${items.length} artigos encontrados');

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;
              if (it['title'] == null || it['title'].toString().contains('[Removed]')) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['urlToImage'];
              results.add(Post(
                id: 'news_${results.length}_${DateTime.now().millisecondsSinceEpoch}',
                userId: 'newsapi_$query',
                userName: it['source']?['name'] ?? 'News Source',
                userAvatar: null,
                content: it['description'] ?? it['title'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'] ?? it['title'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 40) break;
            }

            if (results.isNotEmpty) break;

          } else {
            print('⚠️ NewsAPI retornou status ${resp.statusCode}');
          }
        } catch (e) {
          print('❌ NewsAPI error ($query): $e');
          continue;
        }
      }
    }
  }

  // NewsAPI - Top Headlines
  Future<void> _fetchNewsAPITopHeadlines(List<Post> results, Set<String> seenUrls) async {
    final categories = ['business', 'technology', 'science'];

    for (final category in categories) {
      if (results.length >= 40) break;

      for (final key in _newsApiKeys) {
        try {
          final uri = Uri.parse(
            'https://newsapi.org/v2/top-headlines?category=$category&language=en&pageSize=20&apiKey=$key',
          );

          print('🌐 Requisição NewsAPI Headlines ($category)...');
          final resp = await http.get(uri).timeout(const Duration(seconds: 12));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            print('✓ NewsAPI Headlines ($category): ${items.length} artigos');

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;
              if (it['title'] == null || it['title'].toString().contains('[Removed]')) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['urlToImage'];
              results.add(Post(
                id: 'news_${results.length}_${DateTime.now().millisecondsSinceEpoch}',
                userId: 'newsapi_headlines_$category',
                userName: it['source']?['name'] ?? 'Top Headlines',
                userAvatar: null,
                content: it['description'] ?? it['title'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'] ?? it['title'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 40) break;
            }

            if (results.isNotEmpty) break;

          }
        } catch (e) {
          print('❌ NewsAPI Headlines error: $e');
          continue;
        }
      }
    }
  }

  // GNews
  Future<void> _fetchGNews(List<Post> results, Set<String> seenUrls) async {
    final topics = ['technology', 'business', 'world'];

    for (final topic in topics) {
      if (results.length >= 40) break;

      for (final key in _gnewsKeys) {
        try {
          final uri = Uri.parse(
            'https://gnews.io/api/v4/top-headlines?category=$topic&lang=en&max=20&apikey=$key',
          );

          print('🌐 Requisição GNews ($topic)...');
          final resp = await http.get(uri).timeout(const Duration(seconds: 12));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];

            print('✓ GNews ($topic): ${items.length} artigos');

            for (var it in items) {
              final newsUrl = it['url'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['image'];
              results.add(Post(
                id: 'news_${results.length}_${DateTime.now().millisecondsSinceEpoch}',
                userId: 'gnews_$topic',
                userName: it['source']?['name'] ?? 'GNews',
                userAvatar: null,
                content: it['description'] ?? it['title'] ?? '',
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null'
                    ? [imageUrl.toString()]
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'] ?? it['title'],
                timestamp: it['publishedAt'] != null
                    ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 40) break;
            }

            if (results.isNotEmpty) break;

          }
        } catch (e) {
          print('❌ GNews error: $e');
          continue;
        }
      }
    }
  }

  // NewsData.io
  Future<void> _fetchNewsData(List<Post> results, Set<String> seenUrls) async {
    final categories = ['technology', 'business', 'top'];

    for (final category in categories) {
      if (results.length >= 40) break;

      for (final key in _newsdataKeys) {
        try {
          final url = Uri.parse(
            'https://newsdata.io/api/1/news?apikey=$key&language=en&category=$category&size=20',
          );

          print('🌐 Requisição NewsData ($category)...');
          final resp = await http.get(url).timeout(const Duration(seconds: 12));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['results'] ?? [];

            print('✓ NewsData ($category): ${items.length} artigos');

            for (var it in items) {
              final newsUrl = it['link'];
              if (newsUrl == null || seenUrls.contains(newsUrl)) continue;

              seenUrls.add(newsUrl);

              final imageUrl = it['image_url'];
              results.add(Post(
                id: 'news_${results.length}_${DateTime.now().millisecondsSinceEpoch}',
                userId: 'newsdata_$category',
                userName: it['source_id'] ?? 'NewsData',
                userAvatar: null,
                content: (it['description'] ?? it['title'] ?? '').toString(),
                imageBase64: null,
                imageUrls: imageUrl != null && imageUrl.toString() != 'null' 
                    ? [imageUrl.toString()] 
                    : [],
                videoUrl: null,
                isNews: true,
                newsUrl: newsUrl,
                title: it['title'],
                summary: it['description'] ?? it['title'],
                timestamp: (it['pubDate'] != null)
                    ? DateTime.tryParse(it['pubDate']) ?? DateTime.now()
                    : DateTime.now(),
              ));

              if (results.length >= 40) break;
            }

            if (results.isNotEmpty) break;

          }
        } catch (e) {
          print('❌ NewsData error: $e');
          continue;
        }
      }
    }
  }

  void _emitCombined() {
    List<Post> combined = [];

    switch (_currentFilter) {
      case FeedFilter.mixed:
        // Intercala posts e notícias (2 posts, 1 notícia)
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
        break;

      case FeedFilter.postsOnly:
        combined = List.from(_posts);
        break;

      case FeedFilter.newsOnly:
        combined = List.from(_news);
        break;
    }

    print('✅ Feed combinado (${_currentFilter.name}): ${combined.length} itens');

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