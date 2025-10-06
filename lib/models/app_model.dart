class AppModel {
  final String id;
  final String name;
  final String description;
  final String longDescription;
  final String category;
  final String developer;
  final String version;
  final String size;
  final double rating;
  final int reviewCount;
  final String iconUrl;
  final List<String> screenshots;
  final String webviewUrl;
  final List<String> features;
  final String ageRating;
  final DateTime releaseDate;
  final DateTime lastUpdate;
  final bool isFree;
  final double? price;
  final List<String> languages;
  final String? whatsNew;

  AppModel({
    required this.id,
    required this.name,
    required this.description,
    required this.longDescription,
    required this.category,
    required this.developer,
    required this.version,
    required this.size,
    required this.rating,
    required this.reviewCount,
    required this.iconUrl,
    required this.screenshots,
    required this.webviewUrl,
    required this.features,
    required this.ageRating,
    required this.releaseDate,
    required this.lastUpdate,
    this.isFree = true,
    this.price,
    required this.languages,
    this.whatsNew,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      longDescription: json['longDescription'] ?? json['description'] ?? '',
      category: json['category'] ?? 'Outros',
      developer: json['developer'] ?? 'Desconhecido',
      version: json['version'] ?? '1.0.0',
      size: json['size'] ?? '0 MB',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      iconUrl: json['iconUrl'] ?? json['favicon'] ?? '',
      screenshots: List<String>.from(json['screenshots'] ?? []),
      webviewUrl: json['webviewUrl'] ?? json['url'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      ageRating: json['ageRating'] ?? '12+',
      releaseDate: json['releaseDate'] != null 
          ? DateTime.parse(json['releaseDate']) 
          : DateTime.now(),
      lastUpdate: json['lastUpdate'] != null 
          ? DateTime.parse(json['lastUpdate']) 
          : DateTime.now(),
      isFree: json['isFree'] ?? true,
      price: json['price']?.toDouble(),
      languages: List<String>.from(json['languages'] ?? ['Português']),
      whatsNew: json['whatsNew'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'longDescription': longDescription,
      'category': category,
      'developer': developer,
      'version': version,
      'size': size,
      'rating': rating,
      'reviewCount': reviewCount,
      'iconUrl': iconUrl,
      'screenshots': screenshots,
      'webviewUrl': webviewUrl,
      'features': features,
      'ageRating': ageRating,
      'releaseDate': releaseDate.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'isFree': isFree,
      'price': price,
      'languages': languages,
      'whatsNew': whatsNew,
    };
  }
}

class AppUsageStats {
  final String appId;
  final int openCount;
  final Duration totalUsageTime;
  final DateTime lastUsed;

  AppUsageStats({
    required this.appId,
    required this.openCount,
    required this.totalUsageTime,
    required this.lastUsed,
  });

  factory AppUsageStats.fromJson(Map<String, dynamic> json) {
    return AppUsageStats(
      appId: json['appId'] ?? '',
      openCount: json['openCount'] ?? 0,
      totalUsageTime: Duration(seconds: json['totalUsageSeconds'] ?? 0),
      lastUsed: json['lastUsed'] != null 
          ? DateTime.parse(json['lastUsed'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'openCount': openCount,
      'totalUsageSeconds': totalUsageTime.inSeconds,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }
}