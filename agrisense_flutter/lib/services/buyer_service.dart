import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class BuyerService {
  static Future<Map<String, String>> _getHeaders() async {
    return await AuthService.getAuthHeaders();
  }

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(ApiConfig.buyerProfile),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false};
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(ApiConfig.buyerProfile),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Browse Products
  static Future<List<dynamic>> browseProducts({String query = ''}) async {
    String url = ApiConfig.browseProducts;
    if (query.isNotEmpty) {
      url += '?q=$query';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Cart
  static Future<List<dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse(ApiConfig.cart),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> addToCart(int productId, {int quantity = 1}) async {
    final response = await http.post(
      Uri.parse(ApiConfig.cart),
      headers: await _getHeaders(),
      body: jsonEncode({'product': productId, 'quantity': quantity}),
    );
    return response.statusCode == 201;
  }

  static Future<bool> removeFromCart(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.cart}$cartItemId/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  static Future<Map<String, dynamic>> checkoutInitiate(String address, String phone, String email) async {
    final response = await http.post(
      Uri.parse(ApiConfig.checkoutInitiate),
      headers: await _getHeaders(),
      body: jsonEncode({'address': address, 'phone': phone, 'email': email}),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false, 'error': 'Failed to initiate checkout'};
  }

  static Future<Map<String, dynamic>> checkout(String otp) async {
    final response = await http.post(
      Uri.parse(ApiConfig.checkout),
      headers: await _getHeaders(),
      body: jsonEncode({'otp': otp}),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    final err = response.statusCode == 400
        ? jsonDecode(response.body)['error'] ?? 'Checkout failed'
        : 'Server error';
    return {'success': false, 'error': err};
  }

  // Order History
  static Future<List<dynamic>> getOrderHistory() async {
    final response = await http.get(
      Uri.parse(ApiConfig.orderHistory),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}
