// lib/models/news_stories_models.dart
// Modelo robusto e null-safe para NewsStory, Story e auxiliares.

class NewsStory {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String content;
  final DateTime publishedAt;
  final String author;
  final String source;
  final int likes;
  final int comments;
  final int shares;

  NewsStory({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.content,
    required this.publishedAt,
    required this.author,
    required this.source,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  factory NewsStory.fromJson(Map<String, dynamic> json) {
    // Defensive parsing with sensible fallbacks
    String parseString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    DateTime parseDate(dynamic v) {
      try {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return NewsStory(
      id: parseString(json['id'] ?? json['article_id'] ?? json['url'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      title: parseString(json['title'] ?? json['headline'] ?? 'Sem título'),
      category: parseString(json['category'] ?? json['section'] ?? 'Mundo'),
      imageUrl: parseString(json['imageUrl'] ?? json['urlToImage'] ?? json['image'] ?? json['thumbnail'] ?? 'https://via.placeholder.com/600x400'),
      content: parseString(json['content'] ?? json['description'] ?? ''),
      publishedAt: parseDate(json['publishedAt'] ?? json['pubDate'] ?? json['date']),
      author: parseString(json['author'] ?? (json['source'] is Map ? json['source']['name'] : null) ?? json['creator'] ?? 'Desconhecido'),
      source: parseString(json['source'] ?? (json['source'] is Map ? json['source']['name'] : null) ?? json['source_id'] ?? 'Unknown'),
      likes: (json['likes'] is int) ? json['likes'] : (int.tryParse('${json['likes'] ?? 0}') ?? 0),
      comments: (json['comments'] is int) ? json['comments'] : (int.tryParse('${json['comments'] ?? 0}') ?? 0),
      shares: (json['shares'] is int) ? json['shares'] : (int.tryParse('${json['shares'] ?? 0}') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'content': content,
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'source': source,
      'likes': likes,
      'comments': comments,
      'shares': shares,
    };
  }
}

class Story {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final List<StorySlide> slides;
  final DateTime publishedAt;
  final String? videoUrl;
  final int duration; // duration padrão por slide em segundos (se slide não tiver)

  Story({
    required this.id,
    this.title = '',
    required this.category,
    required this.imageUrl,
    List<StorySlide>? slides,
    DateTime? publishedAt,
    this.videoUrl,
    this.duration = 5,
  })  : slides = slides ?? <StorySlide>[],
        publishedAt = publishedAt ?? DateTime.now();

  factory Story.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    DateTime parseDate(dynamic v) {
      try {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    List<StorySlide> parseSlides(dynamic v) {
      try {
        if (v == null) return <StorySlide>[];
        if (v is List) {
          return v.map((e) {
            if (e is StorySlide) return e;
            if (e is Map<String, dynamic>) return StorySlide.fromJson(e);
            return StorySlide(imageUrl: parseString(e), text: '');
          }).toList();
        }
      } catch (_) {}
      return <StorySlide>[];
    }

    // Support multiple possible field names & structures (defensivo)
    final slidesCandidate = json['slides'] ?? json['story'] ?? json['items'];

    return Story(
      id: parseString(json['id'] ?? json['story_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()),
      title: parseString(json['title'] ?? json['headline'] ?? ''),
      category: parseString(json['category'] ?? json['section'] ?? 'Mundo'),
      imageUrl: parseString(json['imageUrl'] ?? json['image'] ?? json['thumbnail'] ?? 'https://via.placeholder.com/300'),
      slides: parseSlides(slidesCandidate),
      publishedAt: parseDate(json['publishedAt'] ?? json['date']),
      videoUrl: (json['videoUrl'] ?? json['video'] ?? json['video_url']) != null ? parseString(json['videoUrl'] ?? json['video'] ?? json['video_url']) : null,
      duration: (json['duration'] is int) ? json['duration'] : (int.tryParse('${json['duration'] ?? 5}') ?? 5),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'slides': slides.map((s) => s.toJson()).toList(),
      'publishedAt': publishedAt.toIso8601String(),
      'videoUrl': videoUrl,
      'duration': duration,
    };
  }
}

class StorySlide {
  final String imageUrl;
  final String text;
  final int duration; // segundos

  StorySlide({
    required this.imageUrl,
    this.text = '',
    this.duration = 5,
  });

  factory StorySlide.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    return StorySlide(
      imageUrl: parseString(json['imageUrl'] ?? json['image'] ?? json['url'] ?? 'https://via.placeholder.com/300'),
      text: parseString(json['text'] ?? json['caption'] ?? ''),
      duration: (json['duration'] is int) ? json['duration'] : (int.tryParse('${json['duration'] ?? 5}') ?? 5),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'text': text,
      'duration': duration,
    };
  }
}

class Channel {
  final String id;
  final String name;
  final String category;
  final String iconUrl;
  final String description;
  final int followers;
  final bool isVerified;

  Channel({
    required this.id,
    required this.name,
    required this.category,
    required this.iconUrl,
    required this.description,
    required this.followers,
    this.isVerified = false,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    return Channel(
      id: parseString(json['id']),
      name: parseString(json['name']),
      category: parseString(json['category']),
      iconUrl: parseString(json['iconUrl'] ?? json['avatar'] ?? ''),
      description: parseString(json['description']),
      followers: (json['followers'] is int) ? json['followers'] : (int.tryParse('${json['followers'] ?? 0}') ?? 0),
      isVerified: json['isVerified'] == true,
    );
  }
}

class Comment {
  final String id;
  final String newsId;
  final String author;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.newsId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      try {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    String parseString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      return v.toString();
    }

    return Comment(
      id: parseString(json['id']),
      newsId: parseString(json['newsId'] ?? json['storyId'] ?? ''),
      author: parseString(json['author'] ?? 'Anónimo'),
      content: parseString(json['content'] ?? json['text'] ?? ''),
      createdAt: parseDate(json['createdAt'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'newsId': newsId,
        'author': author,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}