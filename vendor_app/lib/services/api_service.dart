import 'dart:convert';
import 'package:http/http.dart' as http;

class VendorApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  /// Get analytics data for a specific vendor
  /// Returns campaign performance metrics and vendor summary
  static Future<Map<String, dynamic>?> getVendorAnalytics(String vendorId) async {
    try {
      final url = '$baseUrl/vendors/$vendorId/analytics';
      print('📊 Getting analytics for vendor $vendorId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Analytics loaded: ${data['vendor_summary']['total_campaigns']} campaigns');
        return data;
      } else {
        print('❌ Failed to load analytics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 Error fetching analytics: $e');
      return null;
    }
  }

  /// Parse campaign data from analytics response
  static List<Map<String, dynamic>> getCampaignsFromAnalytics(Map<String, dynamic> analyticsData) {
    final campaigns = analyticsData['campaigns'] as List<dynamic>?;
    return campaigns?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Parse vendor summary from analytics response  
  static Map<String, dynamic> getVendorSummary(Map<String, dynamic> analyticsData) {
    return analyticsData['vendor_summary'] as Map<String, dynamic>? ?? {};
  }
}