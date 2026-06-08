import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class FarmerService {
  static Future<Map<String, String>> _getHeaders() async {
    return await AuthService.getAuthHeaders();
  }

  // ML Endpoints
  static Future<Map<String, dynamic>> getCropRecommendation({
    required double n, required double p, required double k, required double ph
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.farmerRecommendation),
      headers: await _getHeaders(),
      body: jsonEncode({'N': n, 'P': p, 'K': k, 'ph': ph}),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false, 'error': response.body};
  }

  static Future<List<String>> getYieldPredictionCrops() async {
    final response = await http.get(
      Uri.parse(ApiConfig.farmerYield),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['crops'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>> getYieldPrediction({
    required String crop, required double n, required double p, 
    required double k, required double ph
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.farmerYield),
      headers: await _getHeaders(),
      body: jsonEncode({'crop': crop, 'N': n, 'P': p, 'K': k, 'pH': ph}),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false, 'error': response.body};
  }

  static Future<Map<String, List<String>>> getProfitAnalysisOptions() async {
    final response = await http.get(
      Uri.parse(ApiConfig.farmerProfit),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'states': List<String>.from(data['states'] ?? []),
        'crops': List<String>.from(data['crops'] ?? []),
      };
    }
    return {'states': [], 'crops': []};
  }

  static Future<Map<String, dynamic>> calculateProfit({
    required String state, required String crop, 
    required double area, required double yieldAmount
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.farmerProfit),
      headers: await _getHeaders(),
      body: jsonEncode({'state': state, 'crop': crop, 'area': area, 'yield': yieldAmount}),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false, 'error': response.body};
  }

  // Products
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse(ApiConfig.farmerProducts),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> addProduct({
    required String name, required String description, 
    required double price, required int quantity, required String unit,
    XFile? imageFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.farmerProducts));
    final headers = await _getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['quantity'] = quantity.toString();
    request.fields['unit'] = unit;
    request.fields['is_available'] = 'true';

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response.statusCode == 201;
  }

  static Future<bool> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.farmerProducts}$productId/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  // Orders
  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse(ApiConfig.farmerOrders),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.apiPath}/farmer/orders/$orderId/status/'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': newStatus}),
    );
    return response.statusCode == 200;
  }

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(ApiConfig.farmerProfile),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    }
    return {'success': false};
  }

  static Future<bool> updateProfile(String city, String state) async {
    final response = await http.patch(
      Uri.parse(ApiConfig.farmerProfile),
      headers: await _getHeaders(),
      body: jsonEncode({'city': city, 'state': state}),
    );
    return response.statusCode == 200;
  }
}
