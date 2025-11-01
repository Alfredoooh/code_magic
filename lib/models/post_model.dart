import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String userName;
  final String userNickname;
  final String userPhotoBase64;
  final String description;
  final List<String> imagesBase64;
  final int views;
  final int likes;
  final int comments;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userNickname,
    this.userPhotoBase64 = '',
    required this.description,
    this.imagesBase64 = const [],
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userNickname: data['userNickname'] ?? '',
      userPhotoBase64: data['userPhotoBase64'] ?? '',
      description: data['description'] ?? '',
      imagesBase64: List<String>.from(data['imagesBase64'] ?? []),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userNickname': userNickname,
      'userPhotoBase64': userPhotoBase64,
      'description': description,
      'imagesBase64': imagesBase64,
      'views': views,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PostModel copyWith({
    String? description,
    List<String>? imagesBase64,
    int? views,
    int? likes,
    int? comments,
    List<String>? likedBy,
  }) {
    return PostModel(
      postId: postId,
      userId: userId,
      userName: userName,
      userNickname: userNickname,
      userPhotoBase64: userPhotoBase64,
      description: description ?? this.description,
      imagesBase64: imagesBase64 ?? this.imagesBase64,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class CommentModel {
  final String commentId;
  final String postId;
  final String userId;
  final String userName;
  final String userNickname;
  final String userPhotoBase64;
  final String comment;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userNickname,
    this.userPhotoBase64 = '',
    required this.comment,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userNickname: data['userNickname'] ?? '',
      userPhotoBase64: data['userPhotoBase64'] ?? '',
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userNickname': userNickname,
      'userPhotoBase64': userPhotoBase64,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}