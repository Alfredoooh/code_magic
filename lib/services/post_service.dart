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

  // 🔥 SEU ENDPOINT CUSTOMIZADO (substitua pelo URL do Render após deploy)
  static const String _newsEndpoint = 'https://seu-app.onrender.com/news.json';

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
    print('🌐 Endpoint: $_newsEndpoint');

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
    print('📰 BUSCANDO NOTÍCIAS DA API...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      print('🌐 URL: $_newsEndpoint');
      
      final response = await http
          .get(Uri.parse(_newsEndpoint))
          .timeout(const Duration(seconds: 15));

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Valida estrutura do JSON
        if (jsonData is! Map<String, dynamic>) {
          throw Exception('JSON inválido: esperado um objeto');
        }

        final List<dynamic>? articles = jsonData['articles'];
        final String? version = jsonData['version'];
        final String? lastUpdate = jsonData['lastUpdate'];

        print('📌 Versão da API: $version');
        print('🕐 Última atualização: $lastUpdate');
        print('📄 Total de artigos: ${articles?.length ?? 0}');

        if (articles == null || articles.isEmpty) {
          print('⚠️ Nenhum artigo encontrado no JSON');
          _news = [];
          _emitCombined();
          return;
        }

        final List<Post> results = [];
        int added = 0;
        int skipped = 0;

        for (var article in articles) {
          try {
            final post = _parseArticle(article, added);
            if (post != null) {
              results.add(post);
              added++;
            } else {
              skipped++;
            }
          } catch (e) {
            print('   ❌ Erro ao processar artigo: $e');
            skipped++;
          }
        }

        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news = results;

        print('');
        print('✅ $added notícias carregadas com sucesso');
        print('⚠️ $skipped artigos ignorados');
        print('');
        
        if (_news.isNotEmpty) {
          print('📋 Primeiras 3 notícias:');
          for (int i = 0; i < _news.length && i < 3; i++) {
            final post = _news[i];
            print('   ${i + 1}. ${post.title}');
            print('      Fonte: ${post.userName}');
            print('      Categoria: ${post.content.split('|').first}');
            print('');
          }
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _emitCombined();

      } else {
        print('❌ Erro HTTP ${response.statusCode}');
        print('   Body: ${response.body}');
        _news = [];
        _emitCombined();
      }
    } catch (e) {
      print('❌ ERRO ao buscar notícias: $e');
      _news = [];
      _emitCombined();
    }
  }

  Post? _parseArticle(Map<String, dynamic> article, int index) {
    // Validações obrigatórias
    final String? id = article['id'];
    final String? title = article['title'];
    final String? url = article['url'];

    if (id == null || id.isEmpty) {
      print('   ⚠️ Artigo sem ID');
      return null;
    }

    if (title == null || title.isEmpty || title.contains('[Removed]')) {
      print('   ⚠️ Artigo sem título válido');
      return null;
    }

    if (url == null || url.isEmpty) {
      print('   ⚠️ Artigo sem URL');
      return null;
    }

    // Campos opcionais
    final String? description = article['description'];
    final String? imageUrl = article['imageUrl'];
    final String? source = article['source'];
    final String? category = article['category'];
    final String? author = article['author'];
    final String? publishedAt = article['publishedAt'];

    // Parse da data
    DateTime timestamp = DateTime.now();
    if (publishedAt != null && publishedAt.isNotEmpty) {
      try {
        timestamp = DateTime.parse(publishedAt);
      } catch (e) {
        print('   ⚠️ Data inválida: $publishedAt');
      }
    }

    // Cria o conteúdo com categoria
    final String content = category != null 
        ? '$category | ${description ?? title}'
        : description ?? title;

    print('   ✓ ${title.substring(0, title.length > 50 ? 50 : title.length)}...');

    return Post(
      id: 'news_$id',
      userId: 'newsapi_${category?.replaceAll(' ', '_').toLowerCase() ?? 'general'}',
      userName: source ?? 'News Source',
      userAvatar: null,
      content: content,
      imageBase64: null,
      imageUrls: (imageUrl != null && imageUrl.isNotEmpty) ? [imageUrl] : [],
      videoUrl: null,
      isNews: true,
      newsUrl: url,
      title: title,
      summary: description ?? title,
      timestamp: timestamp,
    );
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
    try {
      await _firestore.collection('posts').doc(postId).delete();
      print('✅ Post deletado');
    } catch (e) {
      print('❌ Erro ao deletar post: $e');
    }
  }

  Future<void> updatePost(String postId, String newContent) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Post atualizado');
    } catch (e) {
      print('❌ Erro ao atualizar post: $e');
    }
  }

  void dispose() {
    _postsSub?.cancel();
    _newsTimer?.cancel();
    _controller.close();
    _started = false;
  }
}