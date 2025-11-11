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
  // Singleton
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<List<Post>> _controller = StreamController<List<Post>>.broadcast();

  // Endpoint (GitHub raw)
  static const _apiBaseUrl = 'https://raw.githubusercontent.com/Alfredoooh/data-server/main/public';

  StreamSubscription<QuerySnapshot>? _postsSub;
  Timer? _newsTimer;

  // Estado interno
  bool _started = false;
  bool _isLoadingNews = false;
  bool _hasMoreNews = true;
  int _currentNewsFile = 1;

  final List<Post> _posts = [];
  final List<Post> _news = [];

  FeedFilter _currentFilter = FeedFilter.mixed;
  FeedFilter get currentFilter => _currentFilter;

  /// Stream público usado pela UI
  Stream<List<Post>> get stream {
    ensureStarted();
    // Emite o estado atual assim que alguém escuta, para evitar UI esperando indefinidamente
    Future.microtask(() => _emitCombined());
    return _controller.stream;
  }

  /// Inicia o serviço (idempotente)
  void ensureStarted() {
    if (_started) return;
    _started = true;

    _listenPosts();
    _fetchNewsFromAPI(); // primeira carga
    _newsTimer = Timer.periodic(const Duration(minutes: 10), (_) => _fetchNewsFromAPI());
  }

  void _listenPosts() {
    _postsSub = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      try {
        _posts
          ..clear()
          ..addAll(snap.docs.map((d) => Post.fromFirestore(d)).toList());
        _emitCombined();
      } catch (e) {
        // Se der erro ao desserializar, envia erro para o stream (UI pode tratar)
        _controller.addError(e);
      }
    }, onError: (e) {
      _controller.addError(e);
    });
  }

  /// Busca notícias do endpoint público. Implementado para ser robusto a 404 / timeouts.
  Future<void> _fetchNewsFromAPI() async {
    if (_isLoadingNews) return;
    _isLoadingNews = true;

    const maxConsecutiveErrors = 3;
    const maxFilesPerRun = 50;
    int consecutiveErrors = 0;
    int triedFiles = 0;

    if (_currentNewsFile < 1) _currentNewsFile = 1;
    // Se já foi determinado que não há mais arquivos, tenta novamente a partir do 1
    if (!_hasMoreNews) {
      _currentNewsFile = 1;
      _hasMoreNews = true;
    }

    final List<Post> results = [];

    try {
      while (triedFiles < maxFilesPerRun && consecutiveErrors < maxConsecutiveErrors && _hasMoreNews) {
        final url = '$_apiBaseUrl/news/news$_currentNewsFile.json';

        http.Response resp;
        try {
          resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
        } catch (e) {
          // erro de rede/timeout → avança arquivo e conta erro
          consecutiveErrors++;
          _currentNewsFile++;
          triedFiles++;
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }

        if (resp.statusCode == 200) {
          dynamic jsonMap;
          try {
            jsonMap = jsonDecode(resp.body);
          } catch (e) {
            // JSON inválido → pula arquivo
            consecutiveErrors++;
            _currentNewsFile++;
            triedFiles++;
            await Future.delayed(const Duration(milliseconds: 250));
            continue;
          }

          final List? articles = jsonMap is Map ? (jsonMap['articles'] as List?) : null;
          if (articles == null || articles.isEmpty) {
            // Arquivo sem artigos válidos → pula
            consecutiveErrors++;
            _currentNewsFile++;
            triedFiles++;
            await Future.delayed(const Duration(milliseconds: 250));
            continue;
          }

          // Processa artigos válidos
          for (var i = 0; i < articles.length; i++) {
            try {
              final article = (articles[i] as Map).cast<String, dynamic>();
              final imageUrl = article['imageUrl'] ?? article['urlToImage'];
              final publishedAt = article['publishedAt'];
              DateTime timestamp;
              if (publishedAt != null) {
                try {
                  timestamp = DateTime.parse(publishedAt.toString());
                } catch (_) {
                  timestamp = DateTime.now();
                }
              } else {
                timestamp = DateTime.now();
              }

              final post = Post(
                id: (article['id'] ?? 'news_${_currentNewsFile}_$i').toString(),
                userId: 'news_api',
                userName: article['source'] is Map ? (article['source']['name'] ?? 'News API') : (article['source'] ?? 'News API'),
                userAvatar: null,
                content: (article['content'] ?? article['description'] ?? '').toString(),
                imageBase64: null,
                imageUrls: imageUrl != null ? [imageUrl.toString()] : null,
                videoUrl: null,
                isNews: true,
                newsUrl: (article['url'] ?? '').toString(),
                title: (article['title'] ?? 'Sem título').toString(),
                summary: (article['description'] ?? '').toString(),
                timestamp: timestamp,
              );

              results.add(post);
            } catch (_) {
              // ignora artigo com formato inesperado
              continue;
            }
          }

          // arquivo processado com sucesso → avançar
          consecutiveErrors = 0;
          _currentNewsFile++;
          triedFiles++;
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        } else if (resp.statusCode == 404) {
          // 404 = fim dos arquivos publicados
          _hasMoreNews = false;
          break;
        } else {
          // outros códigos HTTP → conta erro e avança
          consecutiveErrors++;
          _currentNewsFile++;
          triedFiles++;
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }
      }

      if (results.isNotEmpty) {
        // ordena por timestamp (mais recente primeiro) e limita
        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news
          ..clear()
          ..addAll(results.take(100).toList());
        _emitCombined();
      } else {
        // se não carregou nada e não há notícias anteriores, emite estado vazio para UI
        if (_news.isEmpty) _emitCombined();
      }
    } catch (_) {
      // qualquer erro inesperado: garante que UI receba estado atual
      if (_news.isEmpty) _emitCombined();
    } finally {
      _isLoadingNews = false;
    }
  }

  /// Força carregamento de mais notícias (scroll infinito)
  Future<void> loadMoreNews() async {
    if (!_hasMoreNews || _isLoadingNews) return;
    await _fetchNewsFromAPI();
  }

  /// Emite lista combinada para o stream conforme o filtro atual
  void _emitCombined() {
    final List<Post> combined = [];

    switch (_currentFilter) {
      case FeedFilter.mixed:
        {
          int p = 0, n = 0;
          while (p < _posts.length || n < _news.length) {
            for (int i = 0; i < 2 && p < _posts.length; i++) combined.add(_posts[p++]);
            if (n < _news.length) combined.add(_news[n++]);
          }
        }
        break;
      case FeedFilter.postsOnly:
        combined.addAll(_posts);
        break;
      case FeedFilter.newsOnly:
        combined.addAll(_news);
        break;
    }

    // Emite estado atual (mesmo que vazio)
    if (!_controller.isClosed) _controller.add(List.unmodifiable(combined));
  }

  /// Ajusta filtro e emite novamente
  void setFilter(FeedFilter filter) {
    _currentFilter = filter;
    _emitCombined();
  }

  /// Funções de CRUD / utilitárias (mantidas compatíveis com o código existente)
  Future<void> createPost({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    String? imageBase64,
    String? videoUrl,
  }) async {
    await _firestore.collection('posts').add({
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageBase64': imageBase64,
      'imageUrls': null,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'likedBy': [],
      'isNews': false,
    });
  }

  Future<void> toggleLike(String postId, String uid) async {
    if (postId.startsWith('news_')) return;
    final docRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likes = (data['likes'] as int?) ?? 0;
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        tx.update(docRef, {'likedBy': likedBy, 'likes': likes > 0 ? likes - 1 : 0});
      } else {
        likedBy.add(uid);
        tx.update(docRef, {'likedBy': likedBy, 'likes': likes + 1});
      }
    });
  }

  Future<void> sharePost(Post post) async {
    if (post.isNews) return;
    final ref = _firestore.collection('posts').doc(post.id);
    await ref.update({'shares': FieldValue.increment(1)});
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> updatePost(String postId, String newContent) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': newContent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  /// Limpeza
  void dispose() {
    _postsSub?.cancel();
    _newsTimer?.cancel();
    if (!_controller.isClosed) _controller.close();
    _started = false;
  }
}