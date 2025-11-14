// lib/models/reminder_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { task, custom }

class Reminder {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledDateTime;
  final ReminderType type;
  final String? linkedTaskId; // ID da tarefa vinculada (se for reminder de task)
  final bool isCompleted;
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledDateTime,
    this.type = ReminderType.custom,
    this.linkedTaskId,
    this.isCompleted = false,
    this.notificationSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'type': type.name,
      'linkedTaskId': linkedTaskId,
      'isCompleted': isCompleted,
      'notificationSent': notificationSent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    return Reminder(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      scheduledDateTime: (map['scheduledDateTime'] as Timestamp).toDate(),
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.custom,
      ),
      linkedTaskId: map['linkedTaskId'],
      isCompleted: map['isCompleted'] ?? false,
      notificationSent: map['notificationSent'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Reminder copyWith({
    String? title,
    String? description,
    DateTime? scheduledDateTime,
    bool? isCompleted,
    bool? notificationSent,
  }) {
    return Reminder(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      type: type,
      linkedTaskId: linkedTaskId,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
