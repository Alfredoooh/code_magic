import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feature_model.dart';

class FeatureService {
  static const String baseUrl = 'https://alfredoooh.github.io/database/assets/hub';

  Future<List<FeatureModel>> fetchAllFeatures() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/features.json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => FeatureModel.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar funcionalidades');
      }
    } catch (e) {
      print('Erro ao buscar funcionalidades: $e');
      return [];
    }
  }

  Future<FeatureModel?> fetchFeatureById(String id) async {
    try {
      final features = await fetchAllFeatures();
      return features.firstWhere((feature) => feature.id == id);
    } catch (e) {
      print('Erro ao buscar funcionalidade: $e');
      return null;
    }
  }

  List<String> getCategories(List<FeatureModel> features) {
    final categories = <String>{'Todos'};
    for (var feature in features) {
      categories.add(feature.category);
    }
    return categories.toList();
  }

  List<FeatureModel> filterByCategory(List<FeatureModel> features, String category) {
    if (category == 'Todos') {
      return features;
    }
    return features.where((feature) => feature.category == category).toList();
  }

  List<FeatureModel> searchFeatures(List<FeatureModel> features, String query) {
    final lowerQuery = query.toLowerCase();
    return features.where((feature) {
      return feature.name.toLowerCase().contains(lowerQuery) ||
             feature.description.toLowerCase().contains(lowerQuery) ||
             feature.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}