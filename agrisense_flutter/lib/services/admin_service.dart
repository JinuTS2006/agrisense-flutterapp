import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  static Future<Map<String, String>> _getHeaders() async {
    return await AuthService.getAuthHeaders();
  }

  // Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminDashboard),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false};
  }

  // Users
  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminUsers),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> updateUser(int userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminUsers}$userId/'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminUsers}$userId/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }
}
