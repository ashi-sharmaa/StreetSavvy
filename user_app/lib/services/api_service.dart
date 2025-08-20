// Create: user_app/lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  /// Get campaigns for a specific user based on their location and segments
  /// No lat/lng needed - backend gets user's latest location from database
  static Future<List<Map<String, dynamic>>> getCampaignsForUser(String userId) async {
    try {
      final url = '$baseUrl/users/$userId/nearby-campaigns';
      print('🔍 Getting campaigns for user $userId from database');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Found ${data.length} campaigns for $userId');
        
        // Data now includes vendor_address, vendor_type, vendor_lat, vendor_lng
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        print('❌ User $userId location not found in database');
        return [];
      } else {
        print('❌ Failed to load campaigns: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 Error fetching campaigns: $e');
      return [];
    }
  }
}