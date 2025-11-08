// lib/models/document_template_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentCategory {
  curriculum,
  certificate,
  letter,
  report,
  contract,
  invoice,
  presentation,
  essay,
  other
}

class DocumentTemplate {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DocumentCategory category;
  final bool isActive;
  final DateTime createdAt;
  final int usageCount;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    this.usageCount = 0,
  });

  factory DocumentTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: DocumentCategory.values.firstWhere(
        (c) => c.toString() == data['category'],
        orElse: () => DocumentCategory.other,
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      usageCount: data['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.toString(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'usageCount': usageCount,
    };
  }
}

class DocumentRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String templateId;
  final String templateName;
  final DocumentCategory category;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNotes;

  DocumentRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.templateId,
    required this.templateName,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.adminNotes,
  });

  factory DocumentRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      templateId: data['templateId'] ?? '',
      templateName: data['templateName'] ?? '',
      category: DocumentCategory.values.firstWhere(
        (c) => c.toString() == data['category'],
        orElse: () => DocumentCategory.other,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'normal',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      adminNotes: data['adminNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'templateId': templateId,
      'templateName': templateName,
      'category': category.toString(),
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminNotes': adminNotes,
    };
  }
}