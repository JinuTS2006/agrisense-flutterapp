import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final result = await AuthService.login(username, password);
    if (result['success']) {
      _user = result['user'];
      _token = await AuthService.getToken();
      
      // Save user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String role,
    required String fullName,
    required String city,
    required String state,
    String phoneNumber = '',
  }) async {
    final result = await AuthService.register(
      username: username,
      password: password,
      role: role,
      fullName: fullName,
      city: city,
      state: state,
      phoneNumber: phoneNumber,
    );
    if (result['success']) {
      _user = result['user'];
      _token = await AuthService.getToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));

      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }
}
