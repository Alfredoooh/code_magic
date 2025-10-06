class ProductModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> images;
  final double price;
  final double originalPrice;
  final int discount;
  final String brand;
  final String category;
  final List<String> colors;
  final List<String> sizes;
  final double rating;
  final int reviews;
  final bool inStock;
  final int stock;
  final List<String> features;
  final Map<String, dynamic> specifications;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.images,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.brand,
    required this.category,
    required this.colors,
    required this.sizes,
    required this.rating,
    required this.reviews,
    required this.inStock,
    required this.stock,
    required this.features,
    required this.specifications,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final double originalPrice = (json['original_price'] ?? json['price'] ?? 0).toDouble();
    final double price = (json['price'] ?? 0).toDouble();
    final int discount = json['discount'] ?? 0;

    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? (json['images'] != null && (json['images'] as List).isNotEmpty ? json['images'][0] : ''),
      images: List<String>.from(json['images'] ?? []),
      price: price,
      originalPrice: originalPrice,
      discount: discount,
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      colors: List<String>.from(json['colors'] ?? []),
      sizes: List<String>.from(json['sizes'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      inStock: json['in_stock'] ?? json['inStock'] ?? true,
      stock: json['stock'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'images': images,
      'price': price,
      'original_price': originalPrice,
      'discount': discount,
      'brand': brand,
      'category': category,
      'colors': colors,
      'sizes': sizes,
      'rating': rating,
      'reviews': reviews,
      'in_stock': inStock,
      'stock': stock,
      'features': features,
      'specifications': specifications,
    };
  }
}