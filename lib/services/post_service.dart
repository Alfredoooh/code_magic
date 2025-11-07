// lib/services/post_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<List<Post>> _controller = StreamController.broadcast();

  Stream<List<Post>> get stream => _controller.stream;

  // news keys (usar com cuidado; para produção mover para servidor)
  static const _newsdataKeys = [
    'pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c',
    'pub_8101437cf6db27e4bb3a5473976cdc86571fc',
    'pub_fccded6d857d4110a59fb1ef1f02418c',
  ];
  static const _newsApiKey = 'b2e4d59068e545abbdffaf947c371bcd';
  static const _gnewsKeys = ['5a3e9cdd12d67717cfb6643d25ebaeb5', '6faf083df1638391a56bb22c4f91e132'];

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
    _newsTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchNewsOnce());
  }

  void _listenPosts() {
    _postsSub = _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots().listen((snap) {
      _posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      _emitCombined();
    }, onError: (e) {
      _controller.addError(e);
    });
  }

  Future<void> _fetchNewsOnce() async {
    try {
      final List<Post> results = [];

      // Try Newsdata (keys list)
      for (final key in _newsdataKeys) {
        try {
          final url = Uri.parse('https://newsdata.io/api/1/news?apikey=$key&language=en');
          final resp = await http.get(url).timeout(const Duration(seconds: 8));
          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['results'] ?? [];
            for (var it in items.take(5)) {
              results.add(Post(
                id: (it['link'] ?? it['title'] ?? DateTime.now().toIso8601String()).toString(),
                userId: 'newsdata',
                userName: 'News',
                userAvatar: null,
                content: (it['description'] ?? '').toString(),
                imageBase64: null,
                imageUrls: [(it['image_url'] ?? it['image'])?.toString()].where((e) => e != 'null' && e != 'null').toList(),
                videoUrl: null,
                isNews: true,
                newsUrl: it['link'] ?? it['url'],
                title: it['title'],
                summary: it['description'],
                timestamp: (it['pubDate'] != null) ? DateTime.tryParse(it['pubDate']) ?? DateTime.now() : DateTime.now(),
              ));
            }
            break;
          }
        } catch (_) {
          continue;
        }
      }

      // fallback: newsapi.org
      if (results.length < 5) {
        try {
          final uri = Uri.parse('https://newsapi.org/v2/top-headlines?language=en&pageSize=5&apiKey=$_newsApiKey');
          final resp = await http.get(uri).timeout(const Duration(seconds: 8));
          if (resp.statusCode == 200) {
            final json = jsonDecode(resp.body) as Map<String, dynamic>;
            final List items = json['articles'] ?? [];
            for (var it in items) {
              results.add(Post(
                id: it['url'] ?? it['title'] ?? DateTime.now().toIso8601String(),
                userId: 'newsapi',
                userName: 'News',
                userAvatar: null,
                content: it['description'] ?? '',
                imageBase64: null,
                imageUrls: [it['urlToImage']?.toString()].where((e) => e != null && e != 'null').toList(),
                videoUrl: null,
                isNews: true,
                newsUrl: it['url'],
                title: it['title'],
                summary: it['description'],
                timestamp: it['publishedAt'] != null ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now() : DateTime.now(),
              ));
            }
          }
        } catch (_) {}
      }

      // gnews fallback
      if (results.length < 5) {
        for (final key in _gnewsKeys) {
          try {
            final uri = Uri.parse('https://gnews.io/api/v4/top-headlines?token=$key&lang=en&max=5');
            final resp = await http.get(uri).timeout(const Duration(seconds: 8));
            if (resp.statusCode == 200) {
              final json = jsonDecode(resp.body) as Map<String, dynamic>;
              final List items = json['articles'] ?? [];
              for (var it in items) {
                results.add(Post(
                  id: it['url'] ?? DateTime.now().toIso8601String(),
                  userId: 'gnews',
                  userName: 'News',
                  userAvatar: null,
                  content: it['description'] ?? '',
                  imageBase64: null,
                  imageUrls: [it['image']?.toString()].where((e) => e != null && e != 'null').toList(),
                  videoUrl: null,
                  isNews: true,
                  newsUrl: it['url'],
                  title: it['title'],
                  summary: it['description'],
                  timestamp: it['publishedAt'] != null ? DateTime.tryParse(it['publishedAt']) ?? DateTime.now() : DateTime.now(),
                ));
              }
              break;
            }
          } catch (_) {
            continue;
          }
        }
      }

      _news = results;
      _emitCombined();
    } catch (_) {
      // não fatal
    }
  }

  void _emitCombined() {
    final List<Post> combined = [];
    // posts first (realtime), then news
    combined.addAll(_posts);
    combined.addAll(_news);
    _controller.add(combined);
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