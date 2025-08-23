// user_app/lib/screens/user/user_home_screen.dart
// UPDATED: Added loyalty status bar at top

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
  List<Map<String, dynamic>> _promotions = [];              // Removed bottom spacing and made button smaller
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(60, 30), // Smaller button
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(fontSize: 12), // Smaller text
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} Personalized recommendations
  List<Map<String, dynamic>> _allCampaigns = [];            // All campaigns sorted by distance
  Map<String, dynamic>? _campaignsAndLocation;
  bool _isLoading = true;
  bool _isLoadingAllCampaigns = false;                       // Loading state for distance list
  
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
    _loadAllCampaigns(); // Load distance-sorted campaigns
  }

  /// LOAD PROMOTIONS: Gets campaigns and user location from backend (UNCHANGED)
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

  // Load all campaigns sorted by distance
  Future<void> _loadAllCampaigns() async {
    setState(() => _isLoadingAllCampaigns = true);
    
    try {
      final allCampaigns = await ApiService.getAllCampaignsSortedByDistance(_currentUserId);
      
      setState(() {
        _allCampaigns = allCampaigns;
        _isLoadingAllCampaigns = false;
      });
      
      print('📱 Loaded ${_allCampaigns.length} distance-sorted campaigns for user $_currentUserId');
      
    } catch (e) {
      print('💥 Error loading distance-sorted campaigns: $e');
      setState(() => _isLoadingAllCampaigns = false);
    }
  }

  // SHOW MORE: Open full-screen popup and track click (UNCHANGED)
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

  // USE PROMOTION: Track usage and reveal code (UNCHANGED)
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
  }

  // FULL-SCREEN PROMOTION DETAILS POPUP (UNCHANGED)
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
                      // VENDOR ADDRESS + DISTANCE - CENTERED
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  promotion['vendor_address'] ?? promotion['vendor_name'] ?? 'Address not available',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // Show distance in popup if available
                                if (promotion['distance_display'] != null)
                                  Text(
                                    promotion['distance_display'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getDistanceColor(promotion['distance_meters']?.toDouble() ?? 0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
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

  // Utility function for distance colors
  Color _getDistanceColor(double distanceMeters) {
    if (distanceMeters < 500) return Colors.green;     // Very close - walking
    if (distanceMeters < 2000) return Colors.blue;     // Close - short drive  
    if (distanceMeters < 5000) return Colors.orange;   // Moderate - longer drive
    return Colors.red;                                  // Far - significant trip
  }

  // Get current user's loyalty tier based on their ID
  String _getCurrentUserLoyaltyTier() {
    switch (_currentUserId) {
      case 'U0001': return 'bronze';
      case 'U0002': return 'silver';
      case 'U0003': return 'gold';
      case 'U0004': return 'bronze';
      case 'U0005': return 'silver';
      default: return 'bronze';
    }
  }

  // Get loyalty tier color
  Color _getLoyaltyColor(String tier) {
    switch (tier) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'gold': return const Color(0xFFFFD700);
      default: return Colors.grey;
    }
  }

  // Get loyalty tier gradient
  LinearGradient _getLoyaltyGradient(String tier) {
    switch (tier) {
      case 'bronze':
        return LinearGradient(
          colors: [const Color(0xFFCD7F32), const Color(0xFFB8860B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 'silver':
        return LinearGradient(
          colors: [const Color(0xFFC0C0C0), const Color(0xFF808080)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 'gold':
        return LinearGradient(
          colors: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.grey, Colors.grey.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  // Get loyalty tier icon
  IconData _getLoyaltyIcon(String tier) {
    switch (tier) {
      case 'bronze': return Icons.workspace_premium;
      case 'silver': return Icons.military_tech;
      case 'gold': return Icons.diamond;
      default: return Icons.person;
    }
  }

  // Get loyalty tier description
  String _getLoyaltyDescription(String tier) {
    switch (tier) {
      case 'bronze': return 'Starter benefits • Basic offers';
      case 'silver': return 'Enhanced rewards • Priority deals';
      case 'gold': return 'Premium perks • Exclusive access';
      default: return 'Member benefits';
    }
  }

  // Build distance campaign card for the scrollable list
  Widget _buildDistanceCampaignCard(Map<String, dynamic> campaign, int index) {
    final distanceMeters = campaign['distance_meters']?.toDouble() ?? 0;
    final distanceDisplay = campaign['distance_display'] ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _handleShowMore(campaign),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // LEFT: Ranking number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // MIDDLE: Campaign info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campaign title
                      Text(
                        campaign['title'] ?? 'Unknown Campaign',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Vendor name
                      Row(
                        children: [
                          const Icon(Icons.store, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              campaign['vendor_name'] ?? 'Unknown Vendor',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Code preview
                      Text(
                        'Code: ${campaign['code'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // RIGHT: Distance with color coding
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getDistanceColor(distanceMeters).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getDistanceColor(distanceMeters).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    distanceDisplay,
                    style: TextStyle(
                      color: _getDistanceColor(distanceMeters),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                              _loadAllCampaigns(); // Also reload distance list
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
                    const SizedBox(height: 16),

                    // USER LOYALTY STATUS BAR
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _getLoyaltyGradient(_getCurrentUserLoyaltyTier()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getLoyaltyColor(_getCurrentUserLoyaltyTier()).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getLoyaltyIcon(_getCurrentUserLoyaltyTier()),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_currentUserId • ${_getCurrentUserLoyaltyTier().toUpperCase()} Member',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _getLoyaltyDescription(_getCurrentUserLoyaltyTier()),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_promotions.length} offers',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PROMOTIONS SECTION - removed "on map"
                    Text(
                      'Promotions (${_promotions.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // CAMPAIGN CAROUSEL - Better responsive sizing
                    SizedBox(
                      height: 180, // Reduced from 200 to prevent overflow
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
                              controller: PageController(viewportFraction: 0.85), // Slightly larger cards
                              itemCount: _promotions.length,
                              itemBuilder: (context, index) {
                                final promo = _promotions[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced padding
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
                    
                    const SizedBox(height: 24),
                    
                    // ALL CAMPAIGNS SECTION (Distance-sorted)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'All Offers Near You',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Show count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '${_allCampaigns.length} nearby',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // DISTANCE-SORTED SCROLLABLE LIST
                    Expanded(
                      child: _isLoadingAllCampaigns
                          ? const Center(child: CircularProgressIndicator())
                          : _allCampaigns.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No campaigns available nearby',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _allCampaigns.length,
                                  itemBuilder: (context, index) {
                                    final campaign = _allCampaigns[index];
                                    return _buildDistanceCampaignCard(campaign, index);
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

// PROMOTION CARD - More responsive sizing
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced vertical margin
        child: Padding(
          padding: const EdgeInsets.all(14), // Reduced from 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Slightly smaller
                maxLines: 2, // Allow 2 lines for title
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // Reduced spacing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Smaller padding
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: theme.textTheme.titleSmall?.copyWith( // Smaller text
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14, // Smaller icon
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11, // Smaller text
                      ),
                      maxLines: 1, // Only 1 line for address
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced spacing
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12), // Smaller text
                  maxLines: 2, // Reduced to 2 lines
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              //