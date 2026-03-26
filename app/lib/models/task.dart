import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory {
  personal,
  work,
  health,
  finance,
  education,
  shopping,
  other,
}

extension TaskCategoryExtension on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.personal:
        return 'Pessoal';
      case TaskCategory.work:
        return 'Trabalho';
      case TaskCategory.health:
        return 'Saúde';
      case TaskCategory.finance:
        return 'Finanças';
      case TaskCategory.education:
        return 'Educação';
      case TaskCategory.shopping:
        return 'Compras';
      case TaskCategory.other:
        return 'Outro';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.personal:
        return const Color(0xFF6366F1);
      case TaskCategory.work:
        return const Color(0xFF0EA5E9);
      case TaskCategory.health:
        return const Color(0xFF10B981);
      case TaskCategory.finance:
        return const Color(0xFFF59E0B);
      case TaskCategory.education:
        return const Color(0xFF8B5CF6);
      case TaskCategory.shopping:
        return const Color(0xFFEC4899);
      case TaskCategory.other:
        return const Color(0xFF6B7280);
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Baixa';
      case TaskPriority.medium:
        return 'Média';
      case TaskPriority.high:
        return 'Alta';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF10B981);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.high:
        return const Color(0xFFEF4444);
    }
  }
}

class Task {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  TaskPriority priority;
  TaskCategory category;
  DateTime createdAt;
  DateTime? dueDate;
  List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    required this.createdAt,
    this.dueDate,
    List<SubTask>? subTasks,
  }) : subTasks = subTasks ?? [];

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? createdAt,
    DateTime? dueDate,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.index,
      'category': category.index,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subTasks': subTasks.map((s) => s.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      priority: TaskPriority.values[json['priority'] ?? 1],
      category: TaskCategory.values[json['category'] ?? 0],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate:
          json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((s) => SubTask.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SubTask {
  final String id;
  String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
