// lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cria novo post com imagem em Base64
  Future<void> createPost({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    String? imageBase64,
  }) async {
    try {
      await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'imageBase64': imageBase64,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'likedBy': [],
      });
    } catch (e) {
      throw Exception('Erro ao criar post: $e');
    }
  }

  /// Stream de posts em tempo real
  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Busca posts do usuário
  Stream<List<Post>> getUserPostsStream(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Curtir/Descurtir post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final doc = await postRef.get();
      
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likes = data['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        // Descurtir
        await postRef.update({
          'likes': likes > 0 ? likes - 1 : 0,
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Curtir
        await postRef.update({
          'likes': likes + 1,
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception('Erro ao curtir post: $e');
    }
  }

  /// Deletar post
  Future<void> deletePost(String postId) async {
    try {
      // Deleta comentários do post
      final comments = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (var doc in comments.docs) {
        batch.delete(doc.reference);
      }

      // Deleta o post
      batch.delete(_firestore.collection('posts').doc(postId));
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao deletar post: $e');
    }
  }

  /// Adicionar comentário
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
  }) async {
    try {
      final batch = _firestore.batch();

      // Adiciona comentário
      final commentRef = _firestore.collection('comments').doc();
      batch.set(commentRef, {
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      // Incrementa contador de comentários
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'comments': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao adicionar comentário: $e');
    }
  }

  /// Stream de comentários
  Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  /// Curtir comentário
  Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      final doc = await commentRef.get();
      
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likes = data['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        await commentRef.update({
          'likes': likes > 0 ? likes - 1 : 0,
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await commentRef.update({
          'likes': likes + 1,
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception('Erro ao curtir comentário: $e');
    }
  }

  /// Compartilhar post (incrementa contador)
  Future<void> sharePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shares': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erro ao compartilhar post: $e');
    }
  }

  /// Buscar posts por texto
  Future<List<Post>> searchPosts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final posts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) =>
              post.content.toLowerCase().contains(query.toLowerCase()) ||
              post.userName.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return posts;
    } catch (e) {
      throw Exception('Erro ao buscar posts: $e');
    }
  }
}