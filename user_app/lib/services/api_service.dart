// user_app/lib/services/api_service.dart
// ORIGINAL WORKING VERSION - before CORS complexity

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  /// Get campaigns for a user AND their current location
  /// Returns both campaigns and user's position for proper map centering
  static Future<Map<String, dynamic>> getCampaignsAndLocationForUser(String userId) async {
    try {
      final url = '$baseUrl/users/$userId/nearby-campaigns';
      print('🔍 Getting campaigns + location for user $userId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Found ${data.length} campaigns for $userId');
        
        // Process campaigns with vendor coordinates
        List<Map<String, dynamic>> processedCampaigns = [];
        Map<String, double>? userLocation;
        
        for (var campaign in data) {
          // Extract user's location from first campaign response
          // (backend uses user's location to find campaigns, so coordinates are available)
          userLocation ??= await _getUserLocation(userId);
          
          // Ensure we have valid vendor coordinates for map markers
          final vendorLat = campaign['vendor_lat']?.toDouble();
          final vendorLng = campaign['vendor_lng']?.toDouble();
          
          if (vendorLat != null && vendorLng != null && vendorLat != 0.0 && vendorLng != 0.0) {
            processedCampaigns.add({
              // Campaign info
              'campaign_id': campaign['campaign_id'] ?? '',
              'title': campaign['title'] ?? 'Unknown Campaign',
              'code': campaign['code'] ?? 'NO-CODE',
              'description': campaign['description'] ?? 'No description',
              
              // Vendor info
              'vendor_id': campaign['vendor_id'] ?? '',
              'vendor_address': campaign['vendor_address'] ?? 'Address not available',
              'vendor_type': campaign['vendor_type'] ?? 'Unknown',
              
              // Map coordinates
              'vendor_lat': vendorLat,
              'vendor_lng': vendorLng,
              
              // Status
              'enabled': campaign['enabled'] ?? false,
            });
          }
        }
        
        print('🗺 Processed ${processedCampaigns.length} campaigns with coordinates');
        print('📍 User location: ${userLocation?['latitude']}, ${userLocation?['longitude']}');
        
        return {
          'campaigns': processedCampaigns,
          'userLocation': userLocation ?? {'latitude': 33.1850, 'longitude': -96.6300}, // Default fallback
        };
        
      } else if (response.statusCode == 404) {
        print('❌ User $userId location not found in database');
        return {
          'campaigns': <Map<String, dynamic>>[],
          'userLocation': {'latitude': 33.1850, 'longitude': -96.6300},
        };
      } else {
        print('❌ Failed to load campaigns: ${response.statusCode}');
        return {
          'campaigns': <Map<String, dynamic>>[],
          'userLocation': {'latitude': 33.1850, 'longitude': -96.6300},
        };
      }
    } catch (e) {
      print('💥 Error fetching campaigns: $e');
      return {
        'campaigns': <Map<String, dynamic>>[],
        'userLocation': {'latitude': 33.1850, 'longitude': -96.6300},
      };
    }
  }

  /// Helper: Get user's current location from backend
  static Future<Map<String, double>?> _getUserLocation(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/location'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'latitude': data['latitude'].toDouble(),
          'longitude': data['longitude'].toDouble(),
        };
      }
    } catch (e) {
      print('💥 Error fetching user location: $e');
    }
    return null;
  }

  /// Record user engagement with campaigns (clicked or used)
  static Future<bool> recordEngagement({
    required String userId,
    required String campaignId,
    required String action, // "clicked" or "used"
  }) async {
    try {
      final url = '$baseUrl/users/$userId/campaigns/$campaignId/engage';
      print('📊 Recording engagement: $userId $action $campaignId');
      
      final requestBody = {
        'action': action,
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Engagement recorded: ${data['message']}');
        return true;
      } else {
        print('❌ Failed to record engagement: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error recording engagement: $e');
      return false;
    }
  }
}