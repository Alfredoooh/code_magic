import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _currentUserKey = 'current_user';
  static const String _sessionTokenKey = 'session_token';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Salvar usuário atual
  static Future<void> saveCurrentUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      
      // Salvar dados básicos no SharedPreferences
      await prefs.setString(_currentUserKey, userJson);
      
      // Salvar dados sensíveis no Secure Storage
      await _secureStorage.write(
        key: '${_currentUserKey}_secure',
        value: userJson,
      );
      
      // Salvar timestamp da sessão
      await prefs.setInt('session_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Usuário salvo: ${user.email}');
    } catch (e) {
      print('❌ Erro ao salvar usuário: $e');
      throw Exception('Erro ao salvar dados do usuário');
    }
  }

  /// Obter usuário atual
  static Future<User?> getCurrentUser() async {
    try {
      // Tentar primeiro do Secure Storage
      final secureData = await _secureStorage.read(key: '${_currentUserKey}_secure');
      if (secureData != null) {
        final userMap = json.decode(secureData) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }

      // Fallback para SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_currentUserKey);
      if (userData != null) {
        final userMap = json.decode(userData) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }

      return null;
    } catch (e) {
      print('❌ Erro ao obter usuário atual: $e');
      return null;
    }
  }

  /// Limpar dados do usuário atual
  static Future<void> clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Limpar SharedPreferences
      await prefs.remove(_currentUserKey);
      await prefs.remove('session_timestamp');
      await prefs.remove(_loginAttemptsKey);
      await prefs.remove(_lastLoginAttemptKey);
      
      // Limpar Secure Storage
      await _secureStorage.delete(key: '${_currentUserKey}_secure');
      await _secureStorage.delete(key: _sessionTokenKey);
      
      print('✅ Dados do usuário limpos');
    } catch (e) {
      print('❌ Erro ao limpar dados: $e');
    }
  }

  /// Verificar se a sessão é válida
  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('session_timestamp');
      
      if (timestamp == null) return false;
      
      final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(sessionTime).inHours;
      
      // Sessão válida por 24 horas
      return difference < 24;
    } catch (e) {
      return false;
    }
  }

  /// Salvar tentativas de login falhadas
  static Future<void> saveLoginAttempts(String email, int attempts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_loginAttemptsKey}_$email', attempts);
      await prefs.setInt('${_lastLoginAttemptKey}_$email', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Erro ao salvar tentativas de login: $e');
    }
  }

  /// Obter tentativas de login falhadas
  static Future<int> getLoginAttempts(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('${_loginAttemptsKey}_$email') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Limpar tentativas de login
  static Future<void> clearLoginAttempts(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_loginAttemptsKey}_$email');
      await prefs.remove('${_lastLoginAttemptKey}_$email');
    } catch (e) {
      print('❌ Erro ao limpar tentativas de login: $e');
    }
  }

  /// Verificar se o usuário está bloqueado localmente
  static Future<bool> isUserBlocked(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attempts = prefs.getInt('${_loginAttemptsKey}_$email') ?? 0;
      final lastAttempt = prefs.getInt('${_lastLoginAttemptKey}_$email');
      
      if (attempts < 3 || lastAttempt == null) return false;
      
      final lastAttemptTime = DateTime.fromMillisecondsSinceEpoch(lastAttempt);
      final now = DateTime.now();
      final difference = now.difference(lastAttemptTime).inHours;
      
      // Bloqueado por 24 horas
      if (difference >= 24) {
        // Limpar tentativas após 24 horas
        await clearLoginAttempts(email);
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Salvar configurações do app
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings);
      await prefs.setString('app_settings', settingsJson);
    } catch (e) {
      print('❌ Erro ao salvar configurações: $e');
    }
  }

  /// Obter configurações do app
  static Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsData = prefs.getString('app_settings');
      if (settingsData != null) {
        return json.decode(settingsData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Salvar histórico de login
  static Future<void> saveLoginHistory(String userId, DateTime loginTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'login_history_$userId';
      
      List<String> history = prefs.getStringList(historyKey) ?? [];
      history.add(loginTime.toIso8601String());
      
      // Manter apenas os últimos 10 logins
      if (history.length > 10) {
        history = history.sublist(history.length - 10);
      }
      
      await prefs.setStringList(historyKey, history);
    } catch (e) {
      print('❌ Erro ao salvar histórico de login: $e');
    }
  }

  /// Obter histórico de login
  static Future<List<DateTime>> getLoginHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'login_history_$userId';
      final history = prefs.getStringList(historyKey) ?? [];
      
      return history.map((dateString) => DateTime.parse(dateString)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Salvar dados offline
  static Future<void> saveOfflineData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = json.encode(data);
      await prefs.setString('offline_$key', dataJson);
      await prefs.setInt('offline_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Erro ao salvar dados offline: $e');
    }
  }

  /// Obter dados offline
  static Future<Map<String, dynamic>?> getOfflineData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('offline_$key');
      final timestamp = prefs.getInt('offline_${key}_timestamp');
      
      if (dataString == null || timestamp == null) return null;
      
      // Verificar se os dados não são muito antigos (24 horas)
      final dataTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      if (now.difference(dataTime).inHours > 24) {
        await prefs.remove('offline_$key');
        await prefs.remove('offline_${key}_timestamp');
        return null;
      }
      
      return json.decode(dataString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Limpar todos os dados
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _secureStorage.deleteAll();
      print('✅ Todos os dados foram limpos');
    } catch (e) {
      print('❌ Erro ao limpar todos os dados: $e');
    }
  }

  /// Verificar espaço disponível
  static Future<bool> hasStorageSpace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Verificar se não há muitas chaves (limite arbitrário)
      return keys.length < 1000;
    } catch (e) {
      return true; // Assumir que há espaço em caso de erro
    }
  }

  /// Obter estatísticas de armazenamento
  static Future<Map<String, int>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalSize = 0;
      int userDataSize = 0;
      int settingsSize = 0;
      int cacheSize = 0;
      
      for (final key in keys) {
        final value = prefs.get(key);
        final size = value.toString().length;
        totalSize += size;
        
        if (key.startsWith('current_user') || key.startsWith('login_')) {
          userDataSize += size;
        } else if (key.startsWith('app_settings')) {
          settingsSize += size;
        } else if (key.startsWith('offline_')) {
          cacheSize += size;
        }
      }
      
      return {
        'total': totalSize,
        'userData': userDataSize,
        'settings': settingsSize,
        'cache': cacheSize,
        'keyCount': keys.length,
      };
    } catch (e) {
      return {};
    }
  }
}