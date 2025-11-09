// lib/models/avatar_model.dart
class AvatarImage {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String color;

  AvatarImage({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.color,
  });

  factory AvatarImage.fromJson(Map<String, dynamic> json) {
    return AvatarImage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'abstract',
      color: json['color'] ?? '#1877F2',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'color': color,
    };
  }
}

class AvatarGalleryMetadata {
  final String version;
  final DateTime lastUpdated;
  final int totalAvatars;
  final List<String> categories;

  AvatarGalleryMetadata({
    required this.version,
    required this.lastUpdated,
    required this.totalAvatars,
    required this.categories,
  });

  factory AvatarGalleryMetadata.fromJson(Map<String, dynamic> json) {
    return AvatarGalleryMetadata(
      version: json['version'] ?? '1.0.0',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      totalAvatars: json['totalAvatars'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
    );
  }
}