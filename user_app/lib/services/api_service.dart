import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Your backend URL
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Get user data
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }
  
  // Get active campaigns
  static Future<List<Map<String, dynamic>>> getActiveCampaigns() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/campaigns/active'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Failed to load campaigns: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching campaigns: $e');
      return [];
    }
  }
}