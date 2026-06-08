import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class DeliveryService {
  static Future<Map<String, String>> _getHeaders() async {
    return await AuthService.getAuthHeaders();
  }

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(ApiConfig.deliveryProfile),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false};
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(ApiConfig.deliveryProfile),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Assignments
  static Future<List<dynamic>> getAssignments() async {
    final response = await http.get(
      Uri.parse(ApiConfig.deliveryAssignments),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateAssignmentStatus(int assignmentId, String status, [String? otp]) async {
    final body = <String, dynamic>{'status': status};
    if (otp != null) body['otp'] = otp;

    final response = await http.patch(
      Uri.parse('${ApiConfig.deliveryAssignments}$assignmentId/status/'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return {'success': true};
    }
    final err = response.statusCode == 400 ? jsonDecode(response.body)['error'] : 'Failed to update';
    return {'success': false, 'error': err};
  }

  static Future<Map<String, dynamic>> generateDeliveryOTP(int assignmentId) async {
    try {
      final url = ApiConfig.generateDeliveryOTP(assignmentId);
      print('DEBUG: Calling generate OTP at: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      print('DEBUG: Generate OTP response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final errBody = jsonDecode(response.body);
      return {'success': false, 'error': errBody['detail'] ?? errBody['error'] ?? 'Failed to generate OTP (${response.statusCode})'};
    } catch (e) {
      print('DEBUG: Generate OTP exception: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
