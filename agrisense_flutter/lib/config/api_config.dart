import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Production URL on Render
  static const String baseUrl = 'https://agrisense-flutterapp.onrender.com';

  // For Android Emulator: Use 10.0.2.2 instead of localhost
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For Physical Device on same network: Use your computer's IP address
  // static const String baseUrl = 'http://192.168.1.xxx:8000';

  // Base API Path
  static String get apiPath => '$baseUrl/api/v1';

  // Auth endpoints
  static String get login => '$apiPath/accounts/login/';
  static String register(String role) => '$apiPath/accounts/register/$role/';

  // Farmer endpoints
  static String get farmerProfile => '$apiPath/farmer/profile/';
  static String get farmerProducts => '$apiPath/farmer/products/';
  static String get farmerOrders => '$apiPath/farmer/orders/';
  static String get farmerRecommendation => '$apiPath/farmer/recommendation/';
  static String get farmerYield => '$apiPath/farmer/yield/';
  static String get farmerProfit => '$apiPath/farmer/profit/';

  // Buyer endpoints
  static String get buyerProfile => '$apiPath/buyer/profile/';
  static String get browseProducts => '$apiPath/buyer/products/';
  static String get cart => '$apiPath/buyer/cart/';
  static String get checkoutInitiate => '$apiPath/buyer/cart/checkout/initiate/';
  static String get checkout => '$apiPath/buyer/cart/checkout/';
  static String get orderHistory => '$apiPath/buyer/orders/';

  // Delivery endpoints
  static String get deliveryProfile => '$apiPath/delivery/profile/';
  static String get deliveryAssignments => '$apiPath/delivery/assignments/';
  static String generateDeliveryOTP(int assignmentId) => '$apiPath/delivery/assignments/$assignmentId/generate_otp/';

  // Admin endpoints
  static String get adminDashboard => '$apiPath/admin/dashboard/';
  static String get adminUsers => '$apiPath/admin/users/';

  // Chatbot endpoint
  static String get chatbot => '$apiPath/accounts/chatbot/';
}
