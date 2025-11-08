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
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<List<Post>> _controller = StreamController.broadcast();

  Stream<List<Post>> get stream => _controller.stream;

  // API Key
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
      print('📝 Posts do Firebase: ${_posts.length}');
      _emitCombined();
    }, onError: (e) {
      print('❌ Erro ao buscar posts: $e');
      _controller.addError(e);
    });
  }

  Future<void> _fetchNewsOnce() async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📰 INICIANDO BUSCA DE NOTÍCIAS...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final List<Post> results = [];
      final Set<String> seenUrls = {};

      print('');
      print('🔍 ENDPOINT 1: Top Headlines US Business');
      await _fetchTopHeadlinesUS(results, seenUrls);

      print('');
      print('🔍 ENDPOINT 2: TechCrunch');
      await _fetchTechCrunch(results, seenUrls);

      print('');
      print('🔍 ENDPOINT 3: Bitcoin News');
      await _fetchBitcoin(results, seenUrls);

      print('');
      print('🔍 ENDPOINT 4: Technology News');
      await _fetchTechnology(results, seenUrls);

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (results.isEmpty) {
        print('❌ NENHUMA NOTÍCIA CARREGADA!');
        print('   Verifique:');
        print('   1. Conexão com internet');
        print('   2. Validade da API Key');
        print('   3. Limites da API');
        _news = [];
      } else {
        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news = results.take(50).toList();
        print('✅ ${_news.length} NOTÍCIAS CARREGADAS COM SUCESSO!');
        print('');
        print('📋 Primeiras 5 notícias:');
        for (int i = 0; i < _news.length && i < 5; i++) {
          final post = _news[i];
          print('   ${i + 1}. ${post.title}');
          print('      Fonte: ${post.userName}');
          print('      URL: ${post.newsUrl}');
          print('');
        }
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      _emitCombined();
    } catch (e) {
      print('❌ ERRO GERAL ao buscar notícias: $e');
      _news = [];
      _emitCombined();
    }
  }

  Future<void> _fetchTopHeadlinesUS(List<Post> results, Set<String> seenUrls) async {
    try {
      final url = 'https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=$_newsApiKey';
      print('   URL: ${url.replaceAll(_newsApiKey, "***")}');

      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final String? status = json['status'];
        final List? articles = json['articles'];

        print('   Status: $status');
        print('   Total de artigos: ${articles?.length ?? 0}');

        if (articles != null && articles.isNotEmpty) {
          int added = 0;
          for (var article in articles) {
            if (_addArticle(article, results, seenUrls, 'US Business')) {
              added++;
            }
            if (results.length >= 50) break;
          }
          print('   ✅ $added notícias adicionadas ao feed');
        }
      } else {
        final json = jsonDecode(resp.body);
        print('   ❌ Erro ${resp.statusCode}');
        print('   Mensagem: ${json['message'] ?? 'Sem mensagem'}');
        print('   Code: ${json['code'] ?? 'Sem código'}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  Future<void> _fetchTechCrunch(List<Post> results, Set<String> seenUrls) async {
    try {
      final url = 'https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=$_newsApiKey';
      print('   URL: ${url.replaceAll(_newsApiKey, "***")}');

      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List? articles = json['articles'];

        print('   Total de artigos: ${articles?.length ?? 0}');

        if (articles != null && articles.isNotEmpty) {
          int added = 0;
          for (var article in articles) {
            if (_addArticle(article, results, seenUrls, 'TechCrunch')) {
              added++;
            }
            if (results.length >= 50) break;
          }
          print('   ✅ $added notícias adicionadas ao feed');
        }
      } else {
        final json = jsonDecode(resp.body);
        print('   ❌ Erro ${resp.statusCode}');
        print('   Mensagem: ${json['message'] ?? 'Sem mensagem'}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  Future<void> _fetchBitcoin(List<Post> results, Set<String> seenUrls) async {
    try {
      // CORREÇÃO: Data correta (ontem)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];

      final url = 'https://newsapi.org/v2/everything?q=bitcoin&from=$dateStr&sortBy=publishedAt&apiKey=$_newsApiKey';
      print('   URL: ${url.replaceAll(_newsApiKey, "***")}');
      print('   Data de busca: $dateStr');

      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List? articles = json['articles'];

        print('   Total de artigos: ${articles?.length ?? 0}');

        if (articles != null && articles.isNotEmpty) {
          int added = 0;
          for (var article in articles) {
            if (_addArticle(article, results, seenUrls, 'Bitcoin News')) {
              added++;
            }
            if (results.length >= 50) break;
          }
          print('   ✅ $added notícias adicionadas ao feed');
        }
      } else {
        final json = jsonDecode(resp.body);
        print('   ❌ Erro ${resp.statusCode}');
        print('   Mensagem: ${json['message'] ?? 'Sem mensagem'}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  Future<void> _fetchTechnology(List<Post> results, Set<String> seenUrls) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];

      final url = 'https://newsapi.org/v2/everything?q=technology&from=$dateStr&sortBy=publishedAt&language=en&apiKey=$_newsApiKey';
      print('   URL: ${url.replaceAll(_newsApiKey, "***")}');
      print('   Data de busca: $dateStr');

      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      print('   Status Code: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List? articles = json['articles'];

        print('   Total de artigos: ${articles?.length ?? 0}');

        if (articles != null && articles.isNotEmpty) {
          int added = 0;
          for (var article in articles) {
            if (_addArticle(article, results, seenUrls, 'Tech News')) {
              added++;
            }
            if (results.length >= 50) break;
          }
          print('   ✅ $added notícias adicionadas ao feed');
        }
      } else {
        final json = jsonDecode(resp.body);
        print('   ❌ Erro ${resp.statusCode}');
        print('   Mensagem: ${json['message'] ?? 'Sem mensagem'}');
      }
    } catch (e) {
      print('   ❌ Exceção: $e');
    }
  }

  bool _addArticle(Map<String, dynamic> article, List<Post> results, Set<String> seenUrls, String category) {
    try {
      final url = article['url'];
      final title = article['title'];

      // Validações
      if (url == null || url.toString().isEmpty) {
        print('      ⚠️ Artigo sem URL');
        return false;
      }

      if (seenUrls.contains(url)) {
        print('      ⚠️ Artigo duplicado');
        return false;
      }

      if (title == null || 
          title.toString().isEmpty || 
          title.toString().contains('[Removed]') ||
          title.toString().toLowerCase().contains('removed')) {
        print('      ⚠️ Artigo removido ou sem título');
        return false;
      }

      seenUrls.add(url);

      final imageUrl = article['urlToImage'];
      final description = article['description'];
      final sourceName = article['source']?['name'];
      final publishedAt = article['publishedAt'];

      // Log do artigo adicionado
      print('      ✓ Adicionando: ${title.toString().substring(0, title.toString().length > 50 ? 50 : title.toString().length)}...');

      results.add(Post(
        id: 'news_${results.length}_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'newsapi_${category.replaceAll(' ', '_').toLowerCase()}',
        userName: sourceName?.toString() ?? category,
        userAvatar: null,
        content: description?.toString() ?? title.toString(),
        imageBase64: null,
        imageUrls: (imageUrl != null && imageUrl.toString() != 'null' && imageUrl.toString().isNotEmpty) 
            ? [imageUrl.toString()] 
            : [],
        videoUrl: null,
        isNews: true,
        newsUrl: url.toString(),
        title: title.toString(),
        summary: description?.toString() ?? title.toString(),
        timestamp: publishedAt != null 
            ? DateTime.tryParse(publishedAt.toString()) ?? DateTime.now() 
            : DateTime.now(),
      ));

      return true;
    } catch (e) {
      print('      ❌ Erro ao processar artigo: $e');
      return false;
    }
  }

  void _emitCombined() {
    List<Post> combined = [];

    switch (_currentFilter) {
      case FeedFilter.mixed:
        // Intercala: 2 posts, 1 notícia
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

    final newsCount = combined.where((p) => p.isNews).length;
    final postsCount = combined.where((p) => !p.isNews).length;
    
    print('📊 Feed emitido: $postsCount posts + $newsCount notícias = ${combined.length} total');
    _controller.add(combined);
  }

  void openImageViewer(BuildContext context, List<String> imageUrls, String initialUrl) {
    if (imageUrls.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ImageViewerScreen(imageUrls: imageUrls, initialUrl: initialUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic));
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
      print('✅ Post criado com sucesso');
    } catch (e) {
      print('❌ Erro ao criar post: $e');
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
    await _firestore.collection('posts').doc(postId);
    print('✅ Post deletado');
  }

  void dispose() {
    _postsSub?.cancel();
    _newsTimer?.cancel();
    _controller.close();
    _started = false;
  }
}