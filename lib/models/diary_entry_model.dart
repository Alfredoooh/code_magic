// lib/models/diary_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DiaryMood { happy, sad, motivated, calm, stressed, excited, tired, grateful }

class DiaryEntry {
  final String id;
  final String userId;
  final DateTime date;
  final String title;
  final String content;
  final DiaryMood mood;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      mood: DiaryMood.values.firstWhere(
        (m) => m.toString() == data['mood'],
        orElse: () => DiaryMood.happy,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'title': title,
      'content': content,
      'mood': mood.toString(),
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  DiaryEntry copyWith({
    String? title,
    String? content,
    DiaryMood? mood,
    List<String>? tags,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id,
      userId: userId,
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}