

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;
  
  // Test with different users by changing this ID
  String _currentUserId = 'U0001';

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    
    try {
      final campaigns = await ApiService.getCampaignsForUser(_currentUserId);
      setState(() {
        _promotions = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading promotions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with user switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check out what\'s nearby you',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.person, color: Colors.blue),
                    onSelected: (String userId) {
                      setState(() {
                        _currentUserId = userId;
                        _loadPromotions();
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'U0001', child: Text('U0001')),
                      const PopupMenuItem(value: 'U0002', child: Text('U0002')),
                      const PopupMenuItem(value: 'U0003', child: Text('U0003')),
                      const PopupMenuItem(value: 'U0004', child: Text('U0004')),
                      const PopupMenuItem(value: 'U0005', child: Text('U0005')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Google Maps widget at the top
              SizedBox(
                height: 300,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(33.1850, -96.6300), // McKinney area
                        zoom: 13,
                      ),
                      markers: <Marker>{}, // Empty for now
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Carousel of promotions
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _promotions.isEmpty
                    ? const Center(child: Text('No promotions available'))
                    : PageView.builder(
                        controller: PageController(viewportFraction: 0.8),
                        itemCount: _promotions.length,
                        itemBuilder: (context, index) {
                          final promo = _promotions[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: PromotionCard(
                              title: promo['title'] ?? 'Unknown Title',
                              code: promo['code'] ?? 'NO-CODE',
                              description: promo['description'] ?? 'No description',
                              // NOW USING REAL VENDOR ADDRESS FROM DATABASE
                              address: promo['vendor_address'] ?? 'Address not available',
                              onTap: () => _openPromotionDetail(promo),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPromotionDetail(Map<String, dynamic> promotion) async {
    // get current campaign to track engagement 
    final campaignId = promotion['campaign_id'] ?? '';
  
    // Record "clicked" engagement when user opens promotion details
    if (campaignId.isNotEmpty) {
      await ApiService.recordEngagement(
        userId: _currentUserId,
        campaignId: campaignId,
        action: 'clicked',
      );
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promotion['title'] ?? 'Unknown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${promotion['code']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Location: ${promotion['vendor_address'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(promotion['description'] ?? 'No description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Record "used" engagement when user uses promotion
              if (campaignId.isNotEmpty) {
                final success = await ApiService.recordEngagement(
                  userId: _currentUserId,
                  campaignId: campaignId,
                  action: 'used',
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Used promotion: ${promotion['title']}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Failed to record promotion usage'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Use Promotion'),
          ),
        ],
      ),
    );
  }
}

// Original PromotionCard widget (unchanged from your design)
class PromotionCard extends StatelessWidget {
  final String title;
  final String code;
  final String address;
  final String description;
  final VoidCallback? onTap;

  const PromotionCard({
    super.key,
    required this.title,
    required this.code,
    required this.address,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTap,
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}