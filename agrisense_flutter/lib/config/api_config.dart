import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Automatically switch between localhost for Web/iOS and local IP for physical devices
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else {
      // Local IP for physical device testing
      return 'http://10.30.110.87:8000';
    }
  }

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
