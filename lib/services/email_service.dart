import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  Future<void> sendUserData(Map<String, dynamic> userData, String toEmail) async {
    final response = await http.post(
      Uri.parse('https://api.email-service.com/send'), // Replace with real service
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'to': toEmail,
        'subject': 'K_paga User Data',
        'message': jsonEncode(userData),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email');
    }
  }
}