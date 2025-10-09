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
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      code: json['code'],
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'code': code,
      'price': price,
      'rating': rating,
      'reviews': reviews,
    };
  }
}