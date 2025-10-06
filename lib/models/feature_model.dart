class FeatureModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final double rating;
  final List<String> screenshots;
  final String version;
  final String developer;
  final int downloads;

  FeatureModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.rating,
    required this.screenshots,
    required this.version,
    required this.developer,
    required this.downloads,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? json['iconUrl'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      screenshots: List<String>.from(json['screenshots'] ?? []),
      version: json['version'] ?? '1.0.0',
      developer: json['developer'] ?? '',
      downloads: json['downloads'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'category': category,
      'rating': rating,
      'screenshots': screenshots,
      'version': version,
      'developer': developer,
      'downloads': downloads,
    };
  }
}