import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Save JWT tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      
      return {'success': true, 'user': User.fromJson(data['user'])};
    } else {
      return {'success': false, 'error': 'Invalid credentials'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String role,
    required String fullName,
    required String city,
    required String state,
    String phoneNumber = '',
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register(role)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'city': city,
        'state': state,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Save JWT tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);

      return {'success': true, 'user': User.fromJson(data['user'])};
    } else {
      final err = jsonDecode(response.body);
      return {'success': false, 'error': err.toString()};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
