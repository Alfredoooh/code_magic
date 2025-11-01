import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  List<PostModel> _posts = [];
  bool _isLoading = false;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;

  // Comprimir imagem para reduzir tamanho
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Decode imagem
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Redimensionar se for muito grande (max 1200px de largura)
      if (image.width > 1200) {
        image = img.copyResize(image, width: 1200);
      }

      // Comprimir para JPEG com qualidade 85%
      List<int> compressed = img.encodeJpg(image, quality: 85);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return bytes;
    }
  }

  // Convert image bytes to base64
  String _imageToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  // Convert base64 to image bytes
  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  // Verificar se string é base64 ou URL
  bool isBase64(String str) {
    return !str.startsWith('http://') && !str.startsWith('https://');
  }

  // Create Post com compressão otimizada
  Future<bool> createPost({
    required UserModel user,
    required String description,
    required List<Uint8List> imagesBytesList,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Processar e comprimir imagens
      List<String> imagesBase64 = [];
      for (var imageBytes in imagesBytesList) {
        // Comprimir imagem
        Uint8List compressedBytes = await _compressImage(imageBytes);
        
        // Verificar tamanho após compressão
        double sizeInKB = compressedBytes.length / 1024;
        debugPrint('Image size after compression: ${sizeInKB.toStringAsFixed(2)} KB');
        
        // Se ainda for muito grande (>200KB), comprimir mais
        if (compressedBytes.length > 200000) {
          img.Image? image = img.decodeImage(compressedBytes);
          if (image != null) {
            // Reduzir ainda mais a resolução
            if (image.width > 800) {
              image = img.copyResize(image, width: 800);
            }
            // Qualidade menor
            List<int> moreCompressed = img.encodeJpg(image, quality: 70);
            compressedBytes = Uint8List.fromList(moreCompressed);
            debugPrint('Re-compressed to: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
          }
        }
        
        imagesBase64.add(_imageToBase64(compressedBytes));
      }

      String postId = const Uuid().v4();

      PostModel newPost = PostModel(
        postId: postId,
        userId: user.userId,
        userName: user.name,
        userNickname: user.nickname,
        userPhotoBase64: user.photoURL,
        description: description,
        imagesBase64: imagesBase64,
        createdAt: DateTime.now(),
      );

      // Verificar tamanho total do documento
      String jsonStr = jsonEncode(newPost.toMap());
      double docSizeKB = utf8.encode(jsonStr).length / 1024;
      debugPrint('Total document size: ${docSizeKB.toStringAsFixed(2)} KB');

      if (docSizeKB > 900) {
        // Firestore tem limite de 1MB por documento
        debugPrint('WARNING: Document size approaching Firestore limit!');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.userId)
          .collection('posts')
          .doc(postId)
          .set(newPost.toMap());

      // Also save to global posts collection for feed
      await _firestore.collection('posts').doc(postId).set(newPost.toMap());

      // Save to Realtime Database for real-time updates
      await _realtimeDb.ref('posts/$postId').set({
        'postId': postId,
        'userId': user.userId,
        'views': 0,
        'likes': 0,
        'comments': 0,
        'createdAt': ServerValue.timestamp,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating post: $e');
      return false;
    }
  }

  // Load Posts (Feed)
  Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  // Load User Posts
  Stream<List<PostModel>> getUserPostsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  // Increment Views
  Future<void> incrementViews(String postId, String userId) async {
    try {
      // Check if user already viewed
      DocumentSnapshot viewDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('views')
          .doc(userId)
          .get();

      if (!viewDoc.exists) {
        // Add view record
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('views')
            .doc(userId)
            .set({
          'userId': userId,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        // Increment view count
        await _firestore.collection('posts').doc(postId).update({
          'views': FieldValue.increment(1),
        });

        // Update in Realtime Database
        await _realtimeDb.ref('posts/$postId/views').set(ServerValue.increment(1));
      }
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  // Like Post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      DocumentSnapshot postDoc =
          await _firestore.collection('posts').doc(postId).get();

      if (postDoc.exists) {
        PostModel post = PostModel.fromFirestore(postDoc);
        List<String> likedBy = List.from(post.likedBy);
        bool isLiked = likedBy.contains(userId);

        if (isLiked) {
          // Unlike
          likedBy.remove(userId);
          await _firestore.collection('posts').doc(postId).update({
            'likes': FieldValue.increment(-1),
            'likedBy': likedBy,
          });
          await _realtimeDb.ref('posts/$postId/likes').set(ServerValue.increment(-1));
        } else {
          // Like
          likedBy.add(userId);
          await _firestore.collection('posts').doc(postId).update({
            'likes': FieldValue.increment(1),
            'likedBy': likedBy,
          });
          await _realtimeDb.ref('posts/$postId/likes').set(ServerValue.increment(1));
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Add Comment
  Future<bool> addComment({
    required String postId,
    required UserModel user,
    required String commentText,
  }) async {
    try {
      String commentId = const Uuid().v4();

      CommentModel comment = CommentModel(
        commentId: commentId,
        postId: postId,
        userId: user.userId,
        userName: user.name,
        userNickname: user.nickname,
        userPhotoBase64: user.photoURL,
        comment: commentText,
        createdAt: DateTime.now(),
      );

      // Save comment
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      // Increment comment count
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      // Update in Realtime Database
      await _realtimeDb.ref('posts/$postId/comments').set(ServerValue.increment(1));

      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  // Get Comments Stream
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    });
  }

  // Delete Post
  Future<bool> deletePost(String postId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete from user's posts
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .delete();

      // Delete from global posts
      await _firestore.collection('posts').doc(postId).delete();

      // Delete from Realtime Database
      await _realtimeDb.ref('posts/$postId').remove();

      // Delete all comments
      QuerySnapshot comments = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (var doc in comments.docs) {
        await doc.reference.delete();
      }

      // Delete all views
      QuerySnapshot views = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('views')
          .get();

      for (var doc in views.docs) {
        await doc.reference.delete();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  // Get Real-time stats from Realtime Database
  Stream<Map<String, dynamic>> getPostStatsStream(String postId) {
    return _realtimeDb.ref('posts/$postId').onValue.map((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'views': data['views'] ?? 0,
          'likes': data['likes'] ?? 0,
          'comments': data['comments'] ?? 0,
        };
      }
      return {'views': 0, 'likes': 0, 'comments': 0};
    });
  }
}