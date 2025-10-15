// lib/models/plan_model.dart
import 'package:flutter/material.dart';

class PlanModel {
  final String name;
  final String price;
  final String tokens;
  final String period;
  final Color color;
  final List<String> features;
  final bool popular;

  PlanModel({
    required this.name,
    required this.price,
    required this.tokens,
    required this.period,
    required this.color,
    required this.features,
    required this.popular,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      tokens: json['tokens'] ?? '',
      period: json['period'] ?? '',
      color: _parseColor(json['color']),
      features: List<String>.from(json['features'] ?? []),
      popular: json['popular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'tokens': tokens,
      'period': period,
      'color': _colorToHex(color),
      'features': features,
      'popular': popular,
    };
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return const Color(0xFF6C757D);
    
    if (colorValue is String) {
      // Remove '#' se existir
      String hexColor = colorValue.replaceAll('#', '');
      
      // Adiciona FF no início se não tiver alpha
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      
      try {
        return Color(int.parse(hexColor, radix: 16));
      } catch (e) {
        return const Color(0xFF6C757D);
      }
    }
    
    if (colorValue is int) {
      return Color(colorValue);
    }
    
    return const Color(0xFF6C757D);
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  PlanModel copyWith({
    String? name,
    String? price,
    String? tokens,
    String? period,
    Color? color,
    List<String>? features,
    bool? popular,
  }) {
    return PlanModel(
      name: name ?? this.name,
      price: price ?? this.price,
      tokens: tokens ?? this.tokens,
      period: period ?? this.period,
      color: color ?? this.color,
      features: features ?? this.features,
      popular: popular ?? this.popular,
    );
  }

  @override
  String toString() {
    return 'PlanModel(name: $name, price: $price, tokens: $tokens, period: $period, popular: $popular)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlanModel &&
        other.name == name &&
        other.price == price &&
        other.tokens == tokens &&
        other.period == period &&
        other.color == color &&
        other.popular == popular;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        price.hashCode ^
        tokens.hashCode ^
        period.hashCode ^
        color.hashCode ^
        popular.hashCode;
  }
}