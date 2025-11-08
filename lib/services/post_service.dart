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

  // SUA CHAVE API
  static const _newsApiKey = 'b2e4d59068e545abbdffaf947c371bcd';

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
    print('🔑 Usando chave: ${_newsApiKey.substring(0, 8)}...');

    _listenPosts();
    _fetchNewsOnce();

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
      print('📝 Posts: ${_posts.length}');
      _emitCombined();
    }, onError: (e) {
      print('❌ Erro posts: $e');
      _controller.addError(e);
    });
  }

  Future<void> _fetchNewsOnce() async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📰 BUSCANDO NOTÍCIAS...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final List<Post> results = [];
      final Set<String> seenUrls = {};

      // ENDPOINT 1: Top Headlines US Business
      print('');
      print('🔍 Tentando: Top Headlines US Business');
      await _fetchTopHeadlinesUS(results, seenUrls);

      // ENDPOINT 2: TechCrunch
      print('');
      print('🔍 Tentando: TechCrunch');
      await _fetchTechCrunch(results, seenUrls);

      // ENDPOINT 3: Everything - Bitcoin
      print('');
      print('🔍 Tentando: Bitcoin News');
      await _fetchBitcoin(results, seenUrls);

      // ENDPOINT 4: Everything - Technology
      print('');
      print('🔍 Tentando: Technology News');
      await _fetchTechnology(results, seenUrls);

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (results.isEmpty) {
        print('❌ NENHUMA NOTÍCIA CARREGADA!');
        print('   Verifique sua conexão de internet');
        _news = [];
      } else {
        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news = results.take(50).toList();
        print('✅ ${_news.length} NOTÍCIAS CARREGADAS COM SUCESSO!');
        print('');
        print('📋 Primeiras 3 notícias:');
        for (int i = 0; i < _news.length && i < 3; i++) {
          print('   ${i + 1}. ${_news[i].title}');
          print('      Fonte: ${_news[i].userName}');
        }
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      _emitCombined();
    } catch (e) {
      print('❌ ERRO GERAL: $e');
      _news = [];
      _emitCombined();
    }
  }

  // ENDPOINT 1: Top Headlines US Business
  Future<void> _fetchTopHeadlinesUS(List<Post> results, Set<String> seenUrls) async {
    try {
      final url = 'https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=$_newsApiKey';
      print('   URL: $url');

      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      print('   Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List articles = json['articles'] ?? [];
        
        print('   ✓ ${articles.length} artigos encontrados');

        int added = 0;
        for (var article in articles) {
          if (_addArticle(article, results, seenUrls, 'US Business')) {
            added++;
          }
          if (results.length >= 50) break;
        }
        print('   ✓ $added notícias adicionadas');
      } else if (resp.statusCode == 426) {
        print('   ⚠️ ERRO 426: Upgrade Required');
        print('   Sua chave API precisa de upgrade ou está limitada');
      } else if (resp.statusCode == 429) {
        print('   ⚠️ ERRO 429: Limite de requisições atingido');
      } else if (resp.statusCode == 401) {
        print('   ⚠️ ERRO 401: Chave API inválida');
      } else {
        print('   ⚠️ Erro ${resp.statusCode}');
        print('   Resposta: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  // ENDPOINT 2: TechCrunch
  Future<void> _fetchTechCrunch(List<Post> results, Set<String> seenUrls) async {
    try {
      final url = 'https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=$_newsApiKey';
      print('   URL: $url');

      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      print('   Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List articles = json['articles'] ?? [];
        
        print('   ✓ ${articles.length} artigos encontrados');

        int added = 0;
        for (var article in articles) {
          if (_addArticle(article, results, seenUrls, 'TechCrunch')) {
            added++;
          }
          if (results.length >= 50) break;
        }
        print('   ✓ $added notícias adicionadas');
      } else {
        print('   ⚠️ Erro ${resp.statusCode}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  // ENDPOINT 3: Bitcoin
  Future<void> _fetchBitcoin(List<Post> results, Set<String> seenUrls) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];
      
      final url = 'https://newsapi.org/v2/everything?q=bitcoin&from=$dateStr&sortBy=publishedAt&apiKey=$_newsApiKey';
      print('   URL: $url');

      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      print('   Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List articles = json['articles'] ?? [];
        
        print('   ✓ ${articles.length} artigos encontrados');

        int added = 0;
        for (var article in articles) {
          if (_addArticle(article, results, seenUrls, 'Bitcoin News')) {
            added++;
          }
          if (results.length >= 50) break;
        }
        print('   ✓ $added notícias adicionadas');
      } else {
        print('   ⚠️ Erro ${resp.statusCode}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  // ENDPOINT 4: Technology
  Future<void> _fetchTechnology(List<Post> results, Set<String> seenUrls) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];
      
      final url = 'https://newsapi.org/v2/everything?q=technology&from=$dateStr&sortBy=publishedAt&apiKey=$_newsApiKey';
      print('   URL: $url');

      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      print('   Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List articles = json['articles'] ?? [];
        
        print('   ✓ ${articles.length} artigos encontrados');

        int added = 0;
        for (var article in articles) {
          if (_addArticle(article, results, seenUrls, 'Tech News')) {
            added++;
          }
          if (results.length >= 50) break;
        }
        print('   ✓ $added notícias adicionadas');
      } else {
        print('   ⚠️ Erro ${resp.statusCode}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  bool _addArticle(Map<String, dynamic> article, List<Post> results, Set<String> seenUrls, String category) {
    try {
      final url = article['url'];
      final title = article['title'];

      if (url == null || seenUrls.contains(url)) return false;
      if (title == null || title.toString().contains('[Removed]')) return false;

      seenUrls.add(url);

      final imageUrl = article['urlToImage'];
      
      results.add(Post(
        id: 'news_${results.length}_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'newsapi_$category',
        userName: article['source']?['name'] ?? category,
        userAvatar: null,
        content: article['description']?.toString() ?? title.toString(),
        imageBase64: null,
        imageUrls: imageUrl != null && imageUrl.toString() != 'null' ? [imageUrl.toString()] : [],
        videoUrl: null,
        isNews: true,
        newsUrl: url,
        title: title.toString(),
        summary: article['description']?.toString() ?? title.toString(),
        timestamp: article['publishedAt'] != null ? DateTime.tryParse(article['publishedAt']) ?? DateTime.now() : DateTime.now(),
      ));

      return true;
    } catch (e) {
      print('   ⚠️ Erro ao processar artigo: $e');
      return false;
    }
  }

  void _emitCombined() {
    List<Post> combined = [];

    switch (_currentFilter) {
      case FeedFilter.mixed:
        int postIdx = 0;
        int newsIdx = 0;
        while (postIdx < _posts.length || newsIdx < _news.length) {
          for (int i = 0; i < 2 && postIdx < _posts.length; i++) {
            combined.add(_posts[postIdx++]);
          }
          if (newsIdx < _news.length) {
            combined.add(_news[newsIdx++]);
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

    print('📊 Feed: ${combined.length} itens (${combined.where((p) => p.isNews).length} notícias)');
    _controller.add(combined);
  }

  void openImageViewer(BuildContext context, List<String> imageUrls, String initialUrl) {
    if (imageUrls.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ImageViewerScreen(imageUrls: imageUrls, initialUrl: initialUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOutCubic));
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