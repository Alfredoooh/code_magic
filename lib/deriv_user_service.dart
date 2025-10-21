import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Serviço para obter informações do usuário da Deriv
class DerivUserService {
  static const String APP_ID = '71954';
  static const String WS_URL = 'wss://ws.derivws.com/websockets/v3?app_id=$APP_ID';

  /// Obtém informações do usuário (nome, email)
  static Future<Map<String, String>> getUserInfo(String token) async {
    WebSocketChannel? channel;
    
    try {
      // Conecta ao WebSocket
      channel = WebSocketChannel.connect(Uri.parse(WS_URL));
      
      // Autoriza com o token
      final authorizeRequest = jsonEncode({
        'authorize': token,
      });
      
      channel.sink.add(authorizeRequest);
      
      // Aguarda resposta de autorização
      final response = await channel.stream.first.timeout(
        const Duration(seconds: 10),
      );
      
      final data = jsonDecode(response);
      
      if (data.containsKey('error')) {
        throw Exception('Erro de autorização: ${data['error']['message']}');
      }
      
      if (data.containsKey('authorize')) {
        final authorizeData = data['authorize'];
        
        // Extrai informações
        final fullName = authorizeData['fullname'] as String? ?? 'Usuário';
        final email = authorizeData['email'] as String?;
        final loginId = authorizeData['loginid'] as String?;
        
        return {
          'name': fullName,
          'email': email ?? loginId ?? 'sem-email@deriv.com',
          'loginId': loginId ?? '',
        };
      }
      
      throw Exception('Resposta inválida da API');
      
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return {
        'name': 'Usuário',
        'email': 'usuario@deriv.com',
        'loginId': '',
      };
    } finally {
      await channel?.sink.close();
    }
  }
  
  /// Obtém saldo da conta
  static Future<Map<String, dynamic>> getBalance(String token) async {
    WebSocketChannel? channel;
    
    try {
      channel = WebSocketChannel.connect(Uri.parse(WS_URL));
      
      // Autoriza
      channel.sink.add(jsonEncode({'authorize': token}));
      await channel.stream.first;
      
      // Solicita saldo
      channel.sink.add(jsonEncode({'balance': 1, 'subscribe': 1}));
      
      final response = await channel.stream.first.timeout(
        const Duration(seconds: 10),
      );
      
      final data = jsonDecode(response);
      
      if (data.containsKey('balance')) {
        return {
          'balance': data['balance']['balance'],
          'currency': data['balance']['currency'],
        };
      }
      
      throw Exception('Erro ao obter saldo');
      
    } catch (e) {
      print('Erro ao buscar saldo: $e');
      return {
        'balance': 0.0,
        'currency': 'USD',
      };
    } finally {
      await channel?.sink.close();
    }
  }
}