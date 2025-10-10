class StrategyModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String code;
  final double price;
  final double rating;
  final int reviews;

  StrategyModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.code,
    this.price = 0.0,
    this.rating = 0.0,
    this.reviews = 0,
  });

  factory StrategyModel.fromJson(Map<String, dynamic> json) {
    return StrategyModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      code: json['code'] ?? '',
      price: _toDouble(json['price']),
      rating: _toDouble(json['rating']),
      reviews: json['reviews'] is int ? json['reviews'] : 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'code': code,
      'price': price,
      'rating': rating,
      'reviews': reviews,
    };
  }

  StrategyModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? code,
    double? price,
    double? rating,
    int? reviews,
  }) {
    return StrategyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
    );
  }
}
