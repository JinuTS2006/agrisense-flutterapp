import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ChatbotService {
  /// Sends a chat message to the Agrisense AgriBot backend.
  /// Returns the bot's reply text, or an error string.
  static Future<String> sendMessage({
    required String message,
    required String language,
    required List<Map<String, dynamic>> conversationHistory,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConfig.chatbot),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'language': language,
          'conversation_history': conversationHistory,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'No response from AgriBot.';
      } else {
        return 'Sorry, I could not process your request right now. Please try again.';
      }
    } catch (e) {
      return 'Connection error. Please check your internet connection and try again.';
    }
  }
}
