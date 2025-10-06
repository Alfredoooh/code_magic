import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static const String baseUrl = 'https://alfredoooh.github.io/database/assets';
  static const int maxApiFiles = 20;
  static const int maxLoginAttempts = 3;

  static Map<String, UsersResponse> _apiCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration cacheTimeout = Duration(minutes: 5);

  static Future<List<User>> fetchAllUsers() async {
    final List<User> allUsers = [];

    if (_isCacheValid()) {
      _apiCache.values.forEach((response) {
        allUsers.addAll(response.users);
      });
      return allUsers;
    }

    _apiCache.clear();

    for (int i = 1; i <= maxApiFiles; i++) {
      try {
        final String fileName = i == 1 ? 'users.json' : 'users$i.json';
        final String url = '$baseUrl/$fileName';
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final UsersResponse usersResponse = UsersResponse.fromJson(jsonData);
          
          _apiCache[fileName] = usersResponse;
          allUsers.addAll(usersResponse.users);
          
          print('✅ Carregado: $fileName - ${usersResponse.users.length} usuários');
        } else {
          print('⚠️ Arquivo não encontrado: $fileName (${response.statusCode})');
        }
      } catch (e) {
        print('❌ Erro ao carregar arquivo $i: $e');
        continue;
      }
    }

    _lastCacheUpdate = DateTime.now();
    print('📊 Total de usuários carregados: ${allUsers.length}');
    return allUsers;
  }

  static bool _isCacheValid() {
    if (_lastCacheUpdate == null || _apiCache.isEmpty) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < cacheTimeout;
  }

  static Future<AuthResult> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Email e palavra-passe são obrigatórios',
        );
      }

      final List<User> allUsers = await fetchAllUsers();
      
      if (allUsers.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Erro ao conectar com o servidor. Tente novamente.',
        );
      }

      User? foundUser;
      for (final user in allUsers) {
        if (user.email.toLowerCase() == email.toLowerCase()) {
          foundUser = user;
          break;
        }
      }

      if (foundUser == null) {
        return AuthResult(
          success: false,
          message: 'Email não encontrado no sistema',
        );
      }

      if (foundUser.isBlocked) {
        final blockedUntil = foundUser.blockedUntil;
        if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
          final remainingTime = blockedUntil.difference(DateTime.now());
          final hours = remainingTime.inHours;
          return AuthResult(
            success: false,
            message: 'Conta bloqueada. Tente novamente em $hours horas.',
          );
        }
      }

      if (foundUser.password != password) {
        final updatedUser = await _handleFailedLogin(foundUser);
        
        if (updatedUser.failedAttempts >= maxLoginAttempts) {
          return AuthResult(
            success: false,
            message: 'Conta bloqueada por 24 horas devido a múltiplas tentativas falhadas.',
          );
        }

        return AuthResult(
          success: false,
          message: 'Palavra-passe incorreta. ${maxLoginAttempts - updatedUser.failedAttempts} tentativas restantes.',
        );
      }

      if (!foundUser.access) {
        return AuthResult(
          success: false,
          message: 'Conta desativada. Contacte o administrador.',
        );
      }

      if (foundUser.isExpired) {
        return AuthResult(
          success: false,
          message: 'Conta expirada. Contacte o administrador.',
        );
      }

      foundUser = foundUser.copyWith(
        failedAttempts: 0,
        blocked: false,
        blockedUntil: null,
        lastLogin: DateTime.now(),
      );

      await StorageService.saveCurrentUser(foundUser);

      return AuthResult(
        success: true,
        message: 'Login realizado com sucesso!',
        user: foundUser,
        requiresTwoFactor: foundUser.twoFactorAuth,
      );

    } catch (e) {
      print('Erro no login: $e');
      return AuthResult(
        success: false,
        message: 'Erro interno do sistema. Tente novamente.',
      );
    }
  }

  static Future<User> _handleFailedLogin(User user) async {
    final updatedUser = user.copyWith(
      failedAttempts: user.failedAttempts + 1,
    );

    if (updatedUser.failedAttempts >= maxLoginAttempts) {
      final blockedUntil = DateTime.now().add(const Duration(days: 1));
      return updatedUser.copyWith(
        blocked: true,
        blockedUntil: blockedUntil,
      );
    }

    return updatedUser;
  }

  static Future<AuthResult> verifyTwoFactor(User user, String enteredCode) async {
    try {
      if (enteredCode.trim() == user.twoFactorCode.trim()) {
        final updatedUser = user.copyWith(lastLogin: DateTime.now());
        await StorageService.saveCurrentUser(updatedUser);

        return AuthResult(
          success: true,
          message: 'Autenticação realizada com sucesso!',
          user: updatedUser,
        );
      } else {
        final updatedUser = await _handleFailedLogin(user);
        await StorageService.saveCurrentUser(updatedUser);

        if (updatedUser.failedAttempts >= maxLoginAttempts) {
          return AuthResult(
            success: false,
            message: 'Conta bloqueada por 24 horas devido a múltiplas tentativas falhadas.',
          );
        }

        return AuthResult(
          success: false,
          message: 'Código incorreto. ${maxLoginAttempts - updatedUser.failedAttempts} tentativas restantes.',
          user: updatedUser,
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erro ao verificar código. Tente novamente.',
      );
    }
  }

  /// NOVO: Verificar OTP dinâmico do JSON
  static Future<bool> verifyOTP(User user, String enteredOTP) async {
    try {
      clearCache();
      
      final List<User> allUsers = await fetchAllUsers();
      
      User? currentUser;
      for (final u in allUsers) {
        if (u.id == user.id) {
          currentUser = u;
          break;
        }
      }

      if (currentUser == null) {
        return false;
      }

      if (currentUser.otp.trim() == enteredOTP.trim() && currentUser.otp.isNotEmpty) {
        await StorageService.saveCurrentUser(currentUser);
        return true;
      }

      return false;
    } catch (e) {
      print('Erro ao verificar OTP: $e');
      return false;
    }
  }

  static Future<bool> validateSession(User user) async {
    if (!user.access || user.isExpired || user.isBlocked) {
      return false;
    }

    try {
      final allUsers = await fetchAllUsers();
      final currentUser = allUsers.firstWhere(
        (u) => u.id == user.id,
        orElse: () => throw Exception('User not found'),
      );

      return currentUser.access && !currentUser.isExpired && !currentUser.isBlocked;
    } catch (e) {
      return false;
    }
  }

  static Future<User?> refreshUserData(String userId) async {
    try {
      final allUsers = await fetchAllUsers();
      return allUsers.firstWhere(
        (user) => user.id == userId,
        orElse: () => throw Exception('User not found'),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<AuthResult> verifyUserAccess(User user, String? password, String? userKey) async {
    if (password != null && password.isNotEmpty) {
      if (password == user.password) {
        return AuthResult(success: true, message: 'Acesso autorizado');
      }
    }

    if (userKey != null && userKey.isNotEmpty) {
      if (userKey == user.userKey) {
        return AuthResult(success: true, message: 'Acesso autorizado');
      }
    }

    return AuthResult(
      success: false,
      message: 'Credenciais inválidas',
    );
  }

  static Future<void> logout() async {
    await StorageService.clearCurrentUser();
    _apiCache.clear();
    _lastCacheUpdate = null;
  }

  static String generateSHA256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static void clearCache() {
    _apiCache.clear();
    _lastCacheUpdate = null;
  }
}

class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final bool requiresTwoFactor;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.requiresTwoFactor = false,
  });
}