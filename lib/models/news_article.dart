class NewsArticle {
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final String category;
  final DateTime publishedAt;
  final String url;

  NewsArticle({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    required this.category,
    required this.publishedAt,
    required this.url,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(publishedAt);
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}sem atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }

  factory NewsArticle.fromCustomJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['imageUrl'] ?? '',
      source: json['source'] ?? 'Desconhecido',
      category: json['category'] ?? 'all',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      url: json['url'] ?? '',
    );
  }

  factory NewsArticle.fromNewsdata(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['image_url'] ?? '',
      source: json['source_id'] ?? 'Desconhecido',
      category: (json['category'] != null && json['category'].isNotEmpty) 
          ? json['category'][0] 
          : 'all',
      publishedAt: DateTime.parse(json['pubDate'] ?? DateTime.now().toIso8601String()),
      url: json['link'] ?? '',
    );
  }

  factory NewsArticle.fromNewsApi(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['urlToImage'] ?? '',
      source: json['source']['name'] ?? 'Desconhecido',
      category: 'all',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      url: json['url'] ?? '',
    );
  }

  factory NewsArticle.fromGNews(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição',
      imageUrl: json['image'] ?? '',
      source: json['source']['name'] ?? 'Desconhecido',
      category: 'all',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      url: json['url'] ?? '',
    );
  }
}