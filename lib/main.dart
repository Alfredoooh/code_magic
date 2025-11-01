import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PostModel> _posts = [];
  bool _isLoading = false;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;

  // Convert image bytes to base64
  String _imageToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  // Convert base64 to image bytes
  Uint8List base64ToImage(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  // Create Post - DESABILITADO TEMPORARIAMENTE
  Future<bool> createPost({
    required dynamic user,
    required String description,
    required List<Uint8List> imagesBytesList,
  }) async {
    debugPrint('Post creation temporarily disabled for testing');
    return false;
  }

  // Load Posts (Feed) - RETORNA VAZIO
  Stream<List<PostModel>> getPostsStream() {
    return Stream.value([]);
  }

  // Load User Posts - RETORNA VAZIO
  Stream<List<PostModel>> getUserPostsStream(String userId) {
    return Stream.value([]);
  }

  // Increment Views
  Future<void> incrementViews(String postId, String userId) async {
    debugPrint('Increment views temporarily disabled');
  }

  // Like Post
  Future<void> toggleLike(String postId, String userId) async {
    debugPrint('Toggle like temporarily disabled');
  }

  // Add Comment
  Future<bool> addComment({
    required String postId,
    required dynamic user,
    required String commentText,
  }) async {
    debugPrint('Add comment temporarily disabled');
    return false;
  }

  // Get Comments Stream - RETORNA VAZIO
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return Stream.value([]);
  }

  // Delete Post
  Future<bool> deletePost(String postId, String userId) async {
    debugPrint('Delete post temporarily disabled');
    return false;
  }

  // Get Real-time stats
  Stream<Map<String, dynamic>> getPostStatsStream(String postId) {
    return Stream.value({'views': 0, 'likes': 0, 'comments': 0});
  }
}