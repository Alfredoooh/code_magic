class SheetStory {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime createdAt;

  SheetStory({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
  });

  factory SheetStory.fromJson(Map<String, dynamic> json) {
    return SheetStory(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sheet',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}