import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Real user locations from your test data with expected campaigns
  static const Map<String, Map<String, dynamic>> testUserScenarios = {
    'U0001': {
      'name': 'User U0001 (Bronze @ Panera)',
      'lat': 33.1709356, 
      'lng': -96.6422084,
      'loyalty_tier': 'bronze',
      'most_frequent_vendor_type': 'restaurant',
      'description': 'Bronze tier, restaurant preference - at Panera location',
      'expected_campaigns': ['C0001'], // Update based on your curl result
    },
    'U0002': {
      'name': 'User U0002 (Silver @ Valero)', 
      'lat': 33.1979930, 
      'lng': -96.6381283,
      'loyalty_tier': 'silver',
      'most_frequent_vendor_type': 'gas',
      'description': 'Silver tier, gas preference - at Valero gas station',
      'expected_campaigns': ['C0002'], // Update based on your curl result
    },
    'U0003': {
      'name': 'User U0003 (Gold @ Starbucks)',
      'lat': 33.1985642, 
      'lng': -96.6156789,
      'loyalty_tier': 'gold',
      'most_frequent_vendor_type': 'coffee',
      'description': 'Gold tier, coffee preference - at Starbucks location',
      'expected_campaigns': ['C0003'], // Update based on your curl result
    },
    'U0004': {
      'name': 'User U0004 (Bronze @ Starbucks)',
      'lat': 33.1985642, 
      'lng': -96.6156789,
      'loyalty_tier': 'bronze',
      'most_frequent_vendor_type': 'coffee',
      'description': 'Bronze tier, coffee preference - at Starbucks location',
      'expected_campaigns': ['C0003'], // Same location as U0003
    },
    'U0005': {
      'name': 'User U0005 (Silver @ Panera)',
      'lat': 33.1709356, 
      'lng': -96.6422084,
      'loyalty_tier': 'silver',
      'most_frequent_vendor_type': 'restaurant',
      'description': 'Silver tier, restaurant preference - at Panera location',
      'expected_campaigns': ['C0001'], // Same location as U0001
    },
  };
  
  // Campaign details mapping (from your database)
  static const Map<String, Map<String, dynamic>> campaignDetails = {
    'C0001': {
      'title': 'Bronze Coffee Special',
      'vendor_id': 'V0001',
      'vendor_type': 'restaurant',
      'code': 'COFFEE50',
      'description': 'Morning coffee 50% off for bronze members',
      'location': 'Panera Bread, McKinney'
    },
    'C0002': {
      'title': 'Morning Fuel Deal',  
      'vendor_id': 'V0002',
      'vendor_type': 'gas',
      'code': 'MFUEL10',
      'description': '10% off all morning fuel combos',
      'location': 'Valero Gas Station, McKinney'
    },
    'C0003': {
      'title': 'Gold Member Premium',
      'vendor_id': 'V0003', 
      'vendor_type': 'coffee',
      'code': 'GOLDPREM',
      'description': 'Exclusive gold member morning special',
      'location': 'Starbucks, McKinney'
    },
    'C0004': {
      'title': 'Silver Lunch Deal',
      'vendor_id': 'V0001',
      'vendor_type': 'restaurant', 
      'code': 'SILVLUNCH',
      'description': 'Silver member lunch special',
      'location': 'Panera Bread, McKinney'
    },
  };
  
  // Get campaigns for a specific test user
  static Future<List<Map<String, dynamic>>> getCampaignsForUser(String userId, {double radius = 0.5}) async {
    final userScenario = testUserScenarios[userId];
    if (userScenario == null) {
      print('Unknown user: $userId');
      return [];
    }
    
    try {
      final url = '$baseUrl/campaigns/nearby?lat=${userScenario['lat']}&lng=${userScenario['lng']}&radius=$radius';
      print('Getting campaigns for ${userScenario['name']}');
      print('Expected: ${userScenario['expected_campaigns']}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} campaigns for $userId');
        
        // Add extra details from our hardcoded campaign info
        for (var campaign in data) {
          final campaignId = campaign['campaign_id'];
          final details = campaignDetails[campaignId];
          if (details != null) {
            campaign['vendor_type'] = details['vendor_type'];
            campaign['location'] = details['location'];
          }
        }
        
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