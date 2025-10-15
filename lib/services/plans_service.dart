// lib/services/plans_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plan_model.dart';

class PlansService {
  static const String _baseUrl = 'https://alfredoooh.github.io/database/data/PLANS/plans.json';
  
  // Cache para evitar requisições desnecessárias
  List<PlanModel>? _cachedPlans;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Busca os planos da API
  Future<List<PlanModel>> fetchPlans({bool forceRefresh = false}) async {
    // Verifica se existe cache válido
    if (!forceRefresh && 
        _cachedPlans != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedPlans!;
    }

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout ao buscar planos. Verifique sua conexão.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // Verifica se a estrutura está correta
        if (!jsonData.containsKey('plans')) {
          throw Exception('Formato de dados inválido: chave "plans" não encontrada');
        }

        final List<dynamic> plansJson = jsonData['plans'];
        
        if (plansJson.isEmpty) {
          throw Exception('Nenhum plano disponível no momento');
        }

        _cachedPlans = plansJson.map((json) => PlanModel.fromJson(json)).toList();
        _lastFetchTime = DateTime.now();
        
        return _cachedPlans!;
      } else if (response.statusCode == 404) {
        throw Exception('Planos não encontrados (404)');
      } else if (response.statusCode == 500) {
        throw Exception('Erro no servidor (500)');
      } else {
        throw Exception('Erro ao carregar planos: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erro de rede: Verifique sua conexão com a internet');
    } on FormatException catch (e) {
      throw Exception('Erro ao processar dados: Formato JSON inválido');
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        rethrow;
      }
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Busca um plano específico pelo nome
  Future<PlanModel?> getPlanByName(String name) async {
    final plans = await fetchPlans();
    try {
      return plans.firstWhere(
        (plan) => plan.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Busca planos populares
  Future<List<PlanModel>> getPopularPlans() async {
    final plans = await fetchPlans();
    return plans.where((plan) => plan.popular).toList();
  }

  /// Busca planos por faixa de preço
  Future<List<PlanModel>> getPlansByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    final plans = await fetchPlans();
    return plans.where((plan) {
      // Remove caracteres não numéricos do preço
      final priceString = plan.price.replaceAll(RegExp(r'[^\d.]'), '');
      
      if (priceString.isEmpty || priceString == 'Grátis') {
        return minPrice == 0;
      }
      
      try {
        final price = double.parse(priceString);
        return price >= minPrice && price <= maxPrice;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Busca planos gratuitos
  Future<List<PlanModel>> getFreePlans() async {
    final plans = await fetchPlans();
    return plans.where((plan) => 
      plan.price.toLowerCase().contains('grátis') || 
      plan.price.toLowerCase().contains('free') ||
      plan.price == '\$0' ||
      plan.price == '0'
    ).toList();
  }

  /// Busca planos pagos
  Future<List<PlanModel>> getPaidPlans() async {
    final plans = await fetchPlans();
    return plans.where((plan) => 
      !plan.price.toLowerCase().contains('grátis') && 
      !plan.price.toLowerCase().contains('free') &&
      plan.price != '\$0' &&
      plan.price != '0'
    ).toList();
  }

  /// Limpa o cache
  void clearCache() {
    _cachedPlans = null;
    _lastFetchTime = null;
  }

  /// Verifica se o cache é válido
  bool get hasCachedData {
    return _cachedPlans != null && 
           _lastFetchTime != null &&
           DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Retorna o tempo desde a última atualização
  Duration? get timeSinceLastFetch {
    if (_lastFetchTime == null) return null;
    return DateTime.now().difference(_lastFetchTime!);
  }
}