import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> images;
  final Timestamp? timestamp;
  final int likes;
  final int comments;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.images = const [],
    this.timestamp,
    this.likes = 0,
    this.comments = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      timestamp: json['timestamp'] as Timestamp?,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'images': images,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
    };
  }
}