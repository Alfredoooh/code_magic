import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  Future<Map<String, dynamic>?> fetchUser(String email, String password) async {
    for (int i = 1; i <= 200; i++) {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/assets/users$i.json'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data['users'] as List<dynamic>;
        for (var user in users) {
          if (user['email'] == email && user['password'] == password) {
            return user;
          }
        }
      }
    }
    return null;
  }
}
