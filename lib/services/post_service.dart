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

  // ENDPOINT DA SUA API
  static const _apiBaseUrl = 'https://data-9v20.onrender.com';

  StreamSubscription<QuerySnapshot>? _postsSub;
  Timer? _newsTimer;
  bool _started = false;
  List<Post> _posts = [];
  List<Post> _news = [];
  FeedFilter _currentFilter = FeedFilter.mixed;
  int _currentNewsFile = 1;

  // SEM LIMITE! Continua tentando até encontrar 404
  bool _hasMoreNews = true;

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
    print('🌐 API Base: $_apiBaseUrl');
    print('♾️ Sistema de news infinito ativado');

    _listenPosts();
    _fetchNewsFromAPI();

    _newsTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      print('🔄 Atualizando notícias...');
      _fetchNewsFromAPI();
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

  Future<void> _fetchNewsFromAPI() async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📰 BUSCANDO NOTÍCIAS DA API...');
    print('♾️ Modo infinito: buscando até encontrar 404');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final List<Post> results = [];
      int consecutiveErrors = 0;
      int filesLoaded = 0;

      // Busca notícias até encontrar 3 erros consecutivos
      while (_hasMoreNews && filesLoaded < 10) {
        final url = '$_apiBaseUrl/news/news$_currentNewsFile.json';
        print('🔍 Tentando: news$_currentNewsFile.json');

        try {
          final resp = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body);
            final List? articles = json['articles'];

            if (articles != null && articles.isNotEmpty) {
              print('   ✅ ${articles.length} artigos encontrados');
              filesLoaded++;
              consecutiveErrors = 0; // Reset contador de erros

              for (var article in articles) {
                results.add(Post(
                  id: article['id'] ?? 'news_${_currentNewsFile}_${results.length}',
                  userId: 'news_api',
                  userName: article['source'] ?? 'News API',
                  userAvatar: null,
                  content: article['content'] ?? '',
                  imageBase64: null,
                  imageUrls: article['imageUrl'] != null ? [article['imageUrl']] : [],
                  videoUrl: null,
                  isNews: true,
                  newsUrl: article['url'] ?? '',
                  title: article['title'] ?? '',
                  summary: article['description'] ?? '',
                  timestamp: article['publishedAt'] != null 
                      ? DateTime.parse(article['publishedAt']) 
                      : DateTime.now(),
                ));
              }

              _currentNewsFile++;
            } else {
              print('   ⚠️ Arquivo vazio');
              consecutiveErrors++;
              _currentNewsFile++;
            }
          } else if (resp.statusCode == 404) {
            print('   ⚠️ Arquivo não existe (404)');
            consecutiveErrors++;
            _currentNewsFile++;

            // Se encontrar 3 erros consecutivos, volta pro início
            if (consecutiveErrors >= 3) {
              print('   🔄 Voltando para news1.json');
              _currentNewsFile = 1;
              _hasMoreNews = false; // Pausa até próxima atualização
              break;
            }
          } else {
            print('   ⚠️ Erro ${resp.statusCode}');
            consecutiveErrors++;
            _currentNewsFile++;
          }
        } catch (e) {
          print('   ❌ Erro ao buscar news$_currentNewsFile.json: $e');
          consecutiveErrors++;
          _currentNewsFile++;

          if (consecutiveErrors >= 3) {
            print('   🔄 Muitos erros, voltando para news1.json');
            _currentNewsFile = 1;
            _hasMoreNews = false;
            break;
          }
        }
      }

      // Reset para próxima busca
      _hasMoreNews = true;

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (results.isEmpty) {
        print('❌ NENHUMA NOTÍCIA CARREGADA!');
        print('   Próxima tentativa: news$_currentNewsFile.json');
        _news = [];
      } else {
        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news = results.take(50).toList();
        print('✅ ${_news.length} NOTÍCIAS CARREGADAS!');
        print('📂 $filesLoaded arquivos processados');
        print('🔜 Próximo arquivo: news$_currentNewsFile.json');
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
    if (postId.startsWith('news_')) return; // Não permitir likes em notícias
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
    if (post.isNews) return; // Não permitir shares em notícias
    final ref = _firestore.collection('posts').doc(post.id);
    await ref.update({'shares': FieldValue.increment(1)});
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
    print('✅ Post deletado');
  }

  Future<void> updatePost(String postId, String newContent) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': newContent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Post atualizado');
  }

  void dispose() {
    _postsSub?.cancel();
    _newsTimer?.cancel();
    _controller.close();
    _started = false;
  }
}