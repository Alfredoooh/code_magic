import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class CommerceService {
  static const String baseUrl = 'https://alfredoooh.github.io/database/assets/hub';

  Future<List<ProductModel>> fetchAllProducts() async {
    try {
      final List<ProductModel> allProducts = [];
      
      // Carrega múltiplos arquivos JSON (commerce1.json, commerce2.json, etc.)
      for (int i = 1; i <= 2000; i++) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/commerce$i.json'),
          );

          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            final products = jsonData.map((json) => ProductModel.fromJson(json)).toList();
            allProducts.addAll(products);
          } else {
            // Se não encontrar mais arquivos, para o loop
            break;
          }
        } catch (e) {
          // Se houver erro ao carregar um arquivo específico, continua para o próximo
          break;
        }
      }

      return allProducts;
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      return [];
    }
  }

  Future<ProductModel?> fetchProductById(String id) async {
    try {
      final products = await fetchAllProducts();
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      print('Erro ao buscar produto: $e');
      return null;
    }
  }

  List<String> getCategories(List<ProductModel> products) {
    final categories = <String>{'Todos'};
    for (var product in products) {
      categories.add(product.category);
    }
    return categories.toList();
  }

  List<String> getBrands(List<ProductModel> products) {
    final brands = <String>{'Todas'};
    for (var product in products) {
      brands.add(product.brand);
    }
    return brands.toList();
  }

  List<ProductModel> filterByCategory(List<ProductModel> products, String category) {
    if (category == 'Todos') {
      return products;
    }
    return products.where((product) => product.category == category).toList();
  }

  List<ProductModel> filterByBrand(List<ProductModel> products, String brand) {
    if (brand == 'Todas') {
      return products;
    }
    return products.where((product) => product.brand == brand).toList();
  }

  List<ProductModel> filterByPriceRange(List<ProductModel> products, double minPrice, double maxPrice) {
    return products.where((product) => 
      product.price >= minPrice && product.price <= maxPrice
    ).toList();
  }

  List<ProductModel> sortByPrice(List<ProductModel> products, {bool ascending = true}) {
    final sorted = List<ProductModel>.from(products);
    sorted.sort((a, b) => ascending 
      ? a.price.compareTo(b.price) 
      : b.price.compareTo(a.price)
    );
    return sorted;
  }

  List<ProductModel> sortByRating(List<ProductModel> products) {
    final sorted = List<ProductModel>.from(products);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted;
  }

  List<ProductModel> searchProducts(List<ProductModel> products, String query) {
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
             product.description.toLowerCase().contains(lowerQuery) ||
             product.brand.toLowerCase().contains(lowerQuery) ||
             product.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}