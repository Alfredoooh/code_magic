import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';

class AppService {
  static const String baseUrl = 'https://alfredoooh.github.io/database/apps';
  static const String cacheKey = 'cached_apps';
  static const String usageStatsKey = 'app_usage_stats';
  static const String favoritesKey = 'favorite_apps';

  Future<List<AppModel>> fetchAllApps() async {
    List<AppModel> allApps = [];

    try {
      for (int i = 1; i <= 20; i++) {
        String url = i == 1 
            ? '$baseUrl/apps.json' 
            : '$baseUrl/apps$i.json';
        
        try {
          final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            final apps = jsonData.map((json) => AppModel.fromJson(json)).toList();
            allApps.addAll(apps);
          }
        } catch (e) {
          print('Erro ao carregar $url: $e');
          continue;
        }
      }

      // Salvar cache local
      await _cacheApps(allApps);
      
      return allApps;
    } catch (e) {
      print('Erro geral ao buscar apps: $e');
      // Tentar carregar do cache
      return await _loadCachedApps();
    }
  }

  Future<void> _cacheApps(List<AppModel> apps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(apps.map((app) => app.toJson()).toList());
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      print('Erro ao salvar cache: $e');
    }
  }

  Future<List<AppModel>> _loadCachedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonData = json.decode(jsonString);
        return jsonData.map((json) => AppModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erro ao carregar cache: $e');
    }
    
    return [];
  }

  // Gerenciamento de estatísticas de uso
  Future<void> recordAppUsage(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(usageStatsKey);
    
    Map<String, dynamic> allStats = {};
    if (statsJson != null) {
      allStats = json.decode(statsJson);
    }

    if (allStats.containsKey(appId)) {
      final stats = AppUsageStats.fromJson(allStats[appId]);
      allStats[appId] = AppUsageStats(
        appId: appId,
        openCount: stats.openCount + 1,
        totalUsageTime: stats.totalUsageTime,
        lastUsed: DateTime.now(),
      ).toJson();
    } else {
      allStats[appId] = AppUsageStats(
        appId: appId,
        openCount: 1,
        totalUsageTime: Duration.zero,
        lastUsed: DateTime.now(),
      ).toJson();
    }

    await prefs.setString(usageStatsKey, json.encode(allStats));
  }

  Future<Map<String, AppUsageStats>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(usageStatsKey);
    
    if (statsJson != null) {
      final Map<String, dynamic> allStats = json.decode(statsJson);
      return allStats.map(
        (key, value) => MapEntry(key, AppUsageStats.fromJson(value)),
      );
    }
    
    return {};
  }

  // Favoritos
  Future<void> toggleFavorite(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(favoritesKey) ?? [];
    
    if (favorites.contains(appId)) {
      favorites.remove(appId);
    } else {
      favorites.add(appId);
    }
    
    await prefs.setStringList(favoritesKey, favorites);
  }

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(favoritesKey) ?? [];
  }

  Future<bool> isFavorite(String appId) async {
    final favorites = await getFavorites();
    return favorites.contains(appId);
  }

  // Busca e filtros
  List<AppModel> searchApps(List<AppModel> apps, String query) {
    if (query.isEmpty) return apps;
    
    final lowerQuery = query.toLowerCase();
    return apps.where((app) {
      return app.name.toLowerCase().contains(lowerQuery) ||
             app.description.toLowerCase().contains(lowerQuery) ||
             app.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<AppModel> filterByCategory(List<AppModel> apps, String category) {
    if (category == 'Todos') return apps;
    return apps.where((app) => app.category == category).toList();
  }

  List<String> getCategories(List<AppModel> apps) {
    final categories = apps.map((app) => app.category).toSet().toList();
    categories.sort();
    return ['Todos', ...categories];
  }
}
