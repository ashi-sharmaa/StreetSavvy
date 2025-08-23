import 'dart:convert';
import 'package:http/http.dart' as http;

class VendorApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  /// Get analytics data for a specific vendor
  /// Returns campaign performance metrics and vendor summary
  static Future<Map<String, dynamic>?> getVendorAnalytics(String vendorId) async {
    try {
      final url = '$baseUrl/vendors/$vendorId/analytics';
      print('Getting analytics for vendor $vendorId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Analytics loaded: ${data['vendor_summary']['total_campaigns']} campaigns');
        return data;
      } else {
        print('Failed to load analytics: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching analytics: $e');
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

  /// Get conversion rate from summary data
  static double getConversionRate(Map<String, dynamic> vendorSummary) {
    return (vendorSummary['overall_conversion_rate'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total campaigns count from summary
  static int getTotalCampaigns(Map<String, dynamic> vendorSummary) {
    return vendorSummary['total_campaigns'] as int? ?? 0;
  }

  /// Calculate total clicks across all campaigns
  static int calculateTotalClicks(List<Map<String, dynamic>> campaigns) {
    return campaigns.fold(0, (sum, campaign) => sum + (campaign['total_clicks'] as int? ?? 0));
  }

  /// Calculate total uses across all campaigns
  static int calculateTotalUses(List<Map<String, dynamic>> campaigns) {
    return campaigns.fold(0, (sum, campaign) => sum + (campaign['total_uses'] as int? ?? 0));
  }

  /// Get campaign performance rating (High/Medium/Low based on conversion rate)
  static String getCampaignPerformanceRating(Map<String, dynamic> campaign) {
    final clicks = campaign['total_clicks'] as int? ?? 0;
    final uses = campaign['total_uses'] as int? ?? 0;
    
    if (clicks == 0) return 'No Data';
    
    final conversionRate = (uses / clicks) * 100;
    
    if (conversionRate >= 75) return 'High';
    if (conversionRate >= 40) return 'Medium';
    return 'Low';
  }

  /// Get performance color based on rating
  static String getPerformanceColor(String rating) {
    switch (rating) {
      case 'High': return '#4CAF50';    // Green
      case 'Medium': return '#FF9800';  // Orange  
      case 'Low': return '#F44336';     // Red
      default: return '#9E9E9E';        // Grey
    }
  }
}