// user_app/lib/screens/user/user_home_screen.dart
// ORIGINAL WORKING VERSION - with popup that handles clicked vs used properly

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // DATA STORAGE
  List<Map<String, dynamic>> _promotions = [];
  Map<String, dynamic>? _campaignsAndLocation;
  bool _isLoading = true;
  
  // SIMPLIFIED STATE: Only track which campaigns have revealed codes
  final Set<String> _usedCampaigns = <String>{}; // Just tracks: has user seen the promo code?
  
  // MAP CONTROL
  GoogleMapController? _mapController;
  
  // USER SIMULATION
  String _currentUserId = 'U0001'; // Change this to test different users
  
  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  /// LOAD PROMOTIONS: Gets campaigns and user location from backend
  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    
    try {
      // Load campaigns and user location together
      final campaignsAndLocation = await ApiService.getCampaignsAndLocationForUser(_currentUserId);
      
      setState(() {
        _campaignsAndLocation = campaignsAndLocation;
        _promotions = campaignsAndLocation['campaigns'] ?? [];
        _isLoading = false;
        // Reset campaign states when switching users
        _usedCampaigns.clear();
      });
      
      print('📱 Loaded ${_promotions.length} promotions for user $_currentUserId');
      
    } catch (e) {
      print('💥 Error loading promotions: $e');
      setState(() => _isLoading = false);
    }
  }

  // SHOW MORE: Open full-screen popup and track click
  Future<void> _handleShowMore(Map<String, dynamic> promotion) async {
    final campaignId = promotion['campaign_id'];
    
    // Record "clicked" engagement
    final success = await ApiService.recordEngagement(
      userId: _currentUserId,
      campaignId: campaignId,
      action: 'clicked',
    );
    
    if (success) {
      print('✅ Recorded click for campaign: $campaignId');
      
      // Show full-screen popup
      _showPromotionDetailsPopup(promotion);
    }
  }

  // USE PROMOTION: Track usage and reveal code (NO SNACKBAR HERE)
  Future<void> _handleUsePromotion(Map<String, dynamic> promotion) async {
    final campaignId = promotion['campaign_id'];
    
    // Record "used" engagement
    final success = await ApiService.recordEngagement(
      userId: _currentUserId,
      campaignId: campaignId,
      action: 'used',
    );
    
    if (success) {
      setState(() {
        _usedCampaigns.add(campaignId); // Mark as used to reveal code
      });
      
      // NO SNACKBAR HERE - will show in popup instead
      print('✅ Recorded use for campaign: $campaignId');
    }
    
    // Return success status so popup can handle feedback
    return; // We'll handle feedback in the popup
  }

  // FULL-SCREEN PROMOTION DETAILS POPUP - HANDLES COMPLEXITY INTERNALLY
  void _showPromotionDetailsPopup(Map<String, dynamic> promotion) {
    final campaignId = promotion['campaign_id'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( // KEY: Allows popup to update internally
        builder: (context, setModalState) {
          // CHECK STATE INSIDE BUILDER - this gets updated values!
          final isUsed = _usedCampaigns.contains(campaignId);
          
          return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // POPUP HEADER - CENTERED
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          promotion['title'] ?? 'Promotion Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // POPUP CONTENT - CENTERED
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // VENDOR ADDRESS - CENTERED
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              promotion['vendor_address'] ?? 'Address not available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // DESCRIPTION SECTION - CENTERED
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          promotion['description'] ?? 'No description available',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // PROMOTION CODE SECTION (if used) - CENTERED
                      if (isUsed) ...[
                        const Text(
                          'Promotion Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade300, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🎉 Your Promotion Code:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade400),
                                ),
                                child: Text(
                                  promotion['code'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Show this code to the vendor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // INTERNAL STATE HANDLING: Show different buttons based on isUsed
                      if (!isUsed) ...[
                        // BEFORE USE: Show "Use Promotion" button
                        Center(
                          child: SizedBox(
                            width: 280,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                print('🔄 Use Promotion clicked...');
                                
                                // Update global state FIRST
                                await _handleUsePromotion(promotion);
                                
                                print('✅ Global state updated, refreshing popup...');
                                
                                // Then update popup - now _usedCampaigns contains the campaign
                                setModalState(() {}); // This will trigger rebuild with updated isUsed
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Use Promotion',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // AFTER USE: Show "Close" button
                        Center(
                          child: SizedBox(
                            width: 280,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  /// Center map on user's location (if available)
  Future<void> _centerMapOnUser(Map<String, double> userLocation) async {
    if (_mapController == null) return;
    
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(userLocation['latitude']!, userLocation['longitude']!),
          zoom: 14.0, // Closer zoom since we're centering on user
        ),
      ),
    );
    
    print('🎯 Centered map on user location: ${userLocation['latitude']}, ${userLocation['longitude']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER: Title + User switcher
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
                          icon: const Icon(Icons.person, color: Colors.blue),
                          onSelected: (String userId) {
                            setState(() {
                              _currentUserId = userId;
                              _loadPromotions(); // Reload for new user
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

                    // PROMOTIONS SECTION: Shows campaign count from API
                    Row(
                      children: [
                        Text(
                          'Promotions (${_promotions.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // CAMPAIGN CAROUSEL: Same layout as before
                    Expanded(
                      child: _promotions.isEmpty
                          ? const Center(
                              child: Text(
                                'No promotions available nearby',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
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
                                    address: promo['vendor_address'] ?? 'Address not available',
                                    onTap: () => _handleShowMore(promo),
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
}

// PROMOTION CARD: Same as before (no changes needed)
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