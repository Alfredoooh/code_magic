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
  static const _apiBaseUrl = 'https://data-ekoe.onrender.com';

  StreamSubscription<QuerySnapshot>? _postsSub;
  Timer? _newsTimer;
  bool _started = false;
  List<Post> _posts = [];
  List<Post> _news = [];
  FeedFilter _currentFilter = FeedFilter.mixed;
  int _currentNewsFile = 1;
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

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 PostService iniciado');
    print('🌐 API Base: $_apiBaseUrl');
    print('♾️ Sistema de news infinito ativado');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _listenPosts();
    _fetchNewsFromAPI();

    _newsTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      print('🔄 Atualizando notícias automaticamente...');
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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final List<Post> results = [];
    int consecutiveErrors = 0;
    int filesLoaded = 0;
    const maxFiles = 10;
    const maxConsecutiveErrors = 3;

    try {
      while (_hasMoreNews && filesLoaded < maxFiles && consecutiveErrors < maxConsecutiveErrors) {
        final url = '$_apiBaseUrl/news/news$_currentNewsFile.json';
        print('🔍 Tentando: news$_currentNewsFile.json');
        print('   URL completa: $url');

        try {
          final resp = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 15));

          print('   Status: ${resp.statusCode}');

          if (resp.statusCode == 200) {
            try {
              final json = jsonDecode(resp.body);
              print('   ✅ JSON parseado com sucesso');
              print('   Estrutura: ${json.keys.toList()}');

              final List? articles = json['articles'];
              
              if (articles == null) {
                print('   ⚠️ Campo "articles" não encontrado no JSON');
                consecutiveErrors++;
                _currentNewsFile++;
                continue;
              }

              if (articles.isEmpty) {
                print('   ⚠️ Array "articles" está vazio');
                consecutiveErrors++;
                _currentNewsFile++;
                continue;
              }

              print('   ✅ ${articles.length} artigos encontrados');
              filesLoaded++;
              consecutiveErrors = 0;

              for (var i = 0; i < articles.length; i++) {
                final article = articles[i];
                
                try {
                  // Debug do artigo
                  print('   📄 Artigo $i: ${article['title']?.substring(0, 50) ?? 'sem título'}...');
                  
                  final imageUrl = article['imageUrl'] ?? article['urlToImage'];
                  if (imageUrl != null) {
                    print('      🖼️ Imagem: $imageUrl');
                  } else {
                    print('      ⚠️ Sem imagem');
                  }

                  final publishedAt = article['publishedAt'];
                  DateTime timestamp;
                  
                  if (publishedAt != null) {
                    try {
                      timestamp = DateTime.parse(publishedAt);
                    } catch (e) {
                      print('      ⚠️ Data inválida: $publishedAt');
                      timestamp = DateTime.now();
                    }
                  } else {
                    timestamp = DateTime.now();
                  }

                  final post = Post(
                    id: article['id'] ?? 'news_${_currentNewsFile}_$i',
                    userId: 'news_api',
                    userName: article['source']?['name'] ?? article['source'] ?? 'News API',
                    userAvatar: null,
                    content: article['content'] ?? article['description'] ?? '',
                    imageBase64: null,
                    imageUrls: imageUrl != null ? [imageUrl] : null,
                    videoUrl: null,
                    isNews: true,
                    newsUrl: article['url'] ?? '',
                    title: article['title'] ?? 'Sem título',
                    summary: article['description'] ?? '',
                    timestamp: timestamp,
                  );

                  results.add(post);
                  print('      ✅ Notícia adicionada');
                  
                } catch (e) {
                  print('      ❌ Erro ao processar artigo: $e');
                }
              }

              _currentNewsFile++;
              
            } catch (e) {
              print('   ❌ Erro ao fazer parse do JSON: $e');
              print('   Body: ${resp.body.substring(0, 200)}...');
              consecutiveErrors++;
              _currentNewsFile++;
            }
            
          } else if (resp.statusCode == 404) {
            print('   ⚠️ Arquivo não existe (404)');
            consecutiveErrors++;
            _currentNewsFile++;
          } else {
            print('   ⚠️ Erro HTTP ${resp.statusCode}');
            print('   Body: ${resp.body}');
            consecutiveErrors++;
            _currentNewsFile++;
          }
          
        } catch (e) {
          print('   ❌ Erro de rede: $e');
          consecutiveErrors++;
          _currentNewsFile++;
        }

        // Pequeno delay entre requisições
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Reset do contador se necessário
      if (consecutiveErrors >= maxConsecutiveErrors) {
        print('🔄 Muitos erros consecutivos, voltando para news1.json');
        _currentNewsFile = 1;
        _hasMoreNews = false;
      }

      // Reset para próxima busca
      Future.delayed(const Duration(minutes: 10), () {
        _hasMoreNews = true;
      });

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (results.isEmpty) {
        print('❌ NENHUMA NOTÍCIA CARREGADA!');
        print('   Próxima tentativa em 10 minutos');
        print('   Próximo arquivo: news$_currentNewsFile.json');
        
        // IMPORTANTE: Não limpa as notícias antigas se falhar
        if (_news.isEmpty) {
          _news = [];
        }
      } else {
        results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _news = results.take(50).toList();
        
        print('✅ ${_news.length} NOTÍCIAS CARREGADAS COM SUCESSO!');
        print('📂 $filesLoaded arquivos processados');
        print('🔜 Próximo arquivo: news$_currentNewsFile.json');
        
        // Debug das notícias carregadas
        final newsWithImages = _news.where((n) => n.imageUrls?.isNotEmpty == true).length;
        print('🖼️ Notícias com imagem: $newsWithImages/${_news.length}');
      }
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      _emitCombined();
      
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERRO CRÍTICO ao buscar notícias: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Não limpa as notícias antigas em caso de erro crítico
      if (_news.isEmpty) {
        _news = [];
      }
      _emitCombined();
    }
  }

  void _emitCombined() {
    List<Post> combined = [];

    switch (_currentFilter) {
      case FeedFilter.mixed:
        // Intercala 2 posts + 1 notícia
        int postIdx = 0;
        int newsIdx = 0;
        
        while (postIdx < _posts.length || newsIdx < _news.length) {
          // Adiciona 2 posts
          for (int i = 0; i < 2 && postIdx < _posts.length; i++) {
            combined.add(_posts[postIdx++]);
          }
          // Adiciona 1 notícia
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

    print('📊 Feed emitido:');
    print('   📝 Posts: $postsCount');
    print('   📰 Notícias: $newsCount');
    print('   📦 Total: ${combined.length}');
    print('   🎯 Filtro: $_currentFilter');

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
        'imageUrls': null,
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
    if (postId.startsWith('news_')) {
      print('⚠️ Não é possível curtir notícias');
      return;
    }
    
    final docRef = _firestore.collection('posts').doc(postId);
    
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) {
          print('⚠️ Post não encontrado: $postId');
          return;
        }
        
        final data = snap.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final likes = (data['likes'] as int?) ?? 0;
        
        if (likedBy.contains(uid)) {
          likedBy.remove(uid);
          tx.update(docRef, {
            'likedBy': likedBy,
            'likes': likes > 0 ? likes - 1 : 0,
          });
          print('👎 Like removido');
        } else {
          likedBy.add(uid);
          tx.update(docRef, {
            'likedBy': likedBy,
            'likes': likes + 1,
          });
          print('👍 Like adicionado');
        }
      });
    } catch (e) {
      print('❌ Erro ao dar like: $e');
    }
  }

  Future<void> sharePost(Post post) async {
    if (post.isNews) {
      print('⚠️ Não é possível compartilhar notícias');
      return;
    }
    
    try {
      final ref = _firestore.collection('posts').doc(post.id);
      await ref.update({'shares': FieldValue.increment(1)});
      print('✅ Post compartilhado');
    } catch (e) {
      print('❌ Erro ao compartilhar: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      print('✅ Post deletado');
    } catch (e) {
      print('❌ Erro ao deletar: $e');
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
      print('❌ Erro ao atualizar: $e');
    }
  }

  void dispose() {
    _postsSub?.cancel();
    _newsTimer?.cancel();
    _controller.close();
    _started = false;
    print('🛑 PostService finalizado');
  }
}