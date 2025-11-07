// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar; // Base64 (mantido)
  final String content;
  final String? imageBase64; // Imagem em Base64 (mantido)

  // NOVOS CAMPOS OPCIONAIS (backward-compatible)
  final List<String>? imageUrls; // imagens por URL (opcional)
  final String? videoUrl; // link para vídeo (YouTube / web)
  final bool isNews; // se é conteúdo vindo de API de notícias
  final String? newsUrl;
  final String? title; // título da notícia (se for)
  final String? summary; // resumo da notícia (se for)

  final DateTime timestamp;
  final int likes;
  final int comments;
  final int shares;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.imageBase64,
    this.imageUrls,
    this.videoUrl,
    this.isNews = false,
    this.newsUrl,
    this.title,
    this.summary,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.likedBy = const [],
  });

  /// Converte para Map para Firestore (mantém compatibilidade)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageBase64': imageBase64,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'isNews': isNews,
      'newsUrl': newsUrl,
      'title': title,
      'summary': summary,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'likedBy': likedBy,
    };
  }

  /// Cria Post a partir de Firestore (compatível com versões antigas)
  factory Post.fromFirestore(DocumentSnapshot doc, {String? currentUid}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime ts;
    try {
      ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    } catch (_) {
      ts = DateTime.now();
    }

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuário',
      userAvatar: data['userAvatar'] as String?,
      content: data['content'] ?? '',
      imageBase64: data['imageBase64'] as String?,
      imageUrls: (data['imageUrls'] as List?)?.map((e) => e.toString()).toList(),
      videoUrl: data['videoUrl'] as String?,
      isNews: data['isNews'] == true,
      newsUrl: data['newsUrl'] as String?,
      title: data['title'] as String?,
      summary: data['summary'] as String?,
      timestamp: ts,
      likes: (data['likes'] as int?) ?? 0,
      comments: (data['comments'] as int?) ?? 0,
      shares: (data['shares'] as int?) ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  /// Copia post com alterações
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageBase64,
    List<String>? imageUrls,
    String? videoUrl,
    bool? isNews,
    String? newsUrl,
    String? title,
    String? summary,
    DateTime? timestamp,
    int? likes,
    int? comments,
    int? shares,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageBase64: imageBase64 ?? this.imageBase64,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      isNews: isNews ?? this.isNews,
      newsUrl: newsUrl ?? this.newsUrl,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  /// Verifica se usuário curtiu o post
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar; // Base64
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.likedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime ts;
    try {
      ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    } catch (_) {
      ts = DateTime.now();
    }

    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuário',
      userAvatar: data['userAvatar'] as String?,
      content: data['content'] ?? '',
      timestamp: ts,
      likes: (data['likes'] as int?) ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }
}