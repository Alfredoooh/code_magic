// lib/models/advertisement_model.dart
class Advertisement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String actionUrl;
  final String actionText;
  final String category;
  final String backgroundColor;
  final int priority;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.actionUrl,
    required this.actionText,
    required this.category,
    required this.backgroundColor,
    required this.priority,
    required this.isActive,
    required this.startDate,
    required this.endDate,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      actionUrl: json['actionUrl'] ?? '',
      actionText: json['actionText'] ?? 'Ver Mais',
      category: json['category'] ?? '',
      backgroundColor: json['backgroundColor'] ?? '#1877F2',
      priority: json['priority'] ?? 0,
      isActive: json['isActive'] ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(const Duration(days: 365)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'category': category,
      'backgroundColor': backgroundColor,
      'priority': priority,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  bool isValid() {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}

class AdvertisementMetadata {
  final String version;
  final DateTime lastUpdated;
  final int totalAds;
  final int autoRotationInterval;

  AdvertisementMetadata({
    required this.version,
    required this.lastUpdated,
    required this.totalAds,
    required this.autoRotationInterval,
  });

  factory AdvertisementMetadata.fromJson(Map<String, dynamic> json) {
    return AdvertisementMetadata(
      version: json['version'] ?? '1.0.0',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      totalAds: json['totalAds'] ?? 0,
      autoRotationInterval: json['autoRotationInterval'] ?? 5000,
    );
  }
}