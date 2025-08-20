import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  // STATE VARIABLES: Data storage for the screen
  List<Map<String, dynamic>> _campaigns = [];  // Stores campaign analytics from API
  bool _isLoading = true;                       // Controls loading spinner
  String _currentVendorId = 'V0001';           // Which vendor we're viewing

  @override
  void initState() {
    super.initState();
    _loadCampaigns();  // Load data when screen first appears
  }

  // DATA LOADING: Fetch analytics from backend and extract campaigns
  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    
    try {
      // Get analytics data from backend (includes campaigns + summary)
      final analyticsData = await VendorApiService.getVendorAnalytics(_currentVendorId);
      
      if (analyticsData != null) {
        // Extract just the campaigns array from analytics response
        final campaigns = VendorApiService.getCampaignsFromAnalytics(analyticsData);
        setState(() {
          _campaigns = campaigns;
          _isLoading = false;
        });
      } else {
        setState(() {
          _campaigns = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading campaigns: $e');
      setState(() {
        _campaigns = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TOP HEADER: Vendor Dashboard title + New Campaign button + Vendor switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vendor Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // VENDOR SWITCHER: Dropdown to test different vendors
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.business),
                        onSelected: (String vendorId) {
                          setState(() {
                            _currentVendorId = vendorId;
                            _loadCampaigns();  // Reload data for new vendor
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'V0001', child: Text('V0001 (Panera)')),
                          const PopupMenuItem(value: 'V0002', child: Text('V0002 (Valero)')),
                          const PopupMenuItem(value: 'V0003', child: Text('V0003 (Starbucks)')),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // NEW CAMPAIGN BUTTON: Create campaign (placeholder)
                      ElevatedButton(
                        onPressed: _createNewCampaign,
                        child: const Text('New Campaign'),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // MAIN CONTENT: Two-column layout (Heatmap | Campaigns)
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) // LOADING STATE
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDE: Heatmap placeholder (unchanged from original)
                        Expanded(
                          flex: 1,  // Takes 50% of width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEATMAP HEADER: Title + Configure button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Live Heatmap',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  TextButton.icon(
                                    onPressed: _configureHeatmap,
                                    icon: const Icon(Icons.settings),
                                    label: const Text('Configure'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              
                              // HEATMAP PLACEHOLDER: Will be replaced with real heatmap later
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.map, size: 48, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'Heatmap Will Display Here',
                                          style: TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold, 
                                            color: Colors.grey
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Real-time user density around your location',
                                          style: TextStyle(color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 24), // SPACING between columns
                        
                        // RIGHT SIDE: Campaign analytics (updated with real data)
                        Expanded(
                          flex: 1,  // Takes 50% of width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CAMPAIGNS HEADER: Shows count from API
                              Text(
                                'Your Campaigns (${_campaigns.length})',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              
                              // CAMPAIGNS CAROUSEL: Real data from analytics API
                              Expanded(
                                child: _campaigns.isEmpty
                                  ? const Center(
                                      child: Text('No campaigns yet. Create your first campaign!')
                                    )
                                  : PageView.builder(
                                      controller: PageController(viewportFraction: 0.85),
                                      itemCount: _campaigns.length,
                                      itemBuilder: (context, index) {
                                        final campaign = _campaigns[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: CampaignCard(
                                            // CAMPAIGN DATA: From analytics API response
                                            title: campaign['title'] ?? 'Unknown Campaign',
                                            code: campaign['code'] ?? 'NO-CODE',
                                            description: 'Campaign analytics', // Simplified
                                            address: 'Vendor $_currentVendorId',
                                            isEnabled: campaign['enabled'] == true,
                                            // ANALYTICS DATA: Real engagement metrics
                                            engagementCount: campaign['total_clicks'] ?? 0,
                                            usageCount: campaign['total_uses'] ?? 0,
                                            // ACTION HANDLERS
                                            onEdit: () => _editCampaign(campaign),
                                            onToggle: () => _toggleCampaign(campaign),
                                            onDelete: () => _deleteCampaign(campaign),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BUTTON HANDLERS: Action methods (mostly placeholders for now)

  void _createNewCampaign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new campaign - Coming soon!')),
    );
  }

  void _configureHeatmap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Heatmap Configuration'),
        content: const Text('Configure colors and density thresholds - Coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editCampaign(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${campaign['title']} - Coming soon!')),
    );
  }

  void _toggleCampaign(Map<String, dynamic> campaign) {
    final isEnabled = campaign['enabled'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isEnabled ? 'Disable' : 'Enable'} ${campaign['title']} - Coming soon!'),
      ),
    );
  }

  void _deleteCampaign(Map<String, dynamic> campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Are you sure you want to delete ${campaign['title']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Campaign deleted - Coming soon!')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// CAMPAIGN CARD: Individual campaign display with analytics (FULL HEIGHT LAYOUT)
class CampaignCard extends StatelessWidget {
  final String title;
  final String code;
  final String description;
  final String address;
  final bool isEnabled;
  final int engagementCount;    // Now shows real clicks from analytics
  final int usageCount;         // Now shows real uses from analytics
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const CampaignCard({
    super.key,
    required this.title,
    required this.code,
    required this.description,
    required this.address,
    required this.isEnabled,
    required this.engagementCount,
    required this.usageCount,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CAMPAIGN HEADER: Title + Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // STATUS INDICATOR: Green for active, red for inactive
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEnabled ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEnabled ? 'ON' : 'OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // CAMPAIGN CODE: Blue chip showing code
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
            
            // SPACER: Pushes analytics and buttons toward the middle and bottom
            const Spacer(flex: 1),
            
            // ANALYTICS DISPLAY: Real engagement metrics from API (EXPANDED TO FILL SPACE)
            Expanded(
              flex: 2, // Takes more space for better proportion
              child: Row(
                children: [
                  // CLICKS METRIC: Shows total_clicks from analytics
                  Expanded(
                    child: Container(
                      height: double.infinity, // Fills available height
                      padding: const EdgeInsets.all(12), // Increased padding
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Centers content vertically
                        children: [
                          const Icon(Icons.touch_app, color: Colors.blue, size: 28), // Larger icon
                          const SizedBox(height: 8),
                          Text(
                            '$engagementCount',
                            style: const TextStyle(
                              fontSize: 24, // Larger number
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Clicks',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12), // Increased spacing
                  
                  // USAGE METRIC: Shows total_uses from analytics
                  Expanded(
                    child: Container(
                      height: double.infinity, // Fills available height
                      padding: const EdgeInsets.all(12), // Increased padding
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Centers content vertically
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 28), // Larger icon
                          const SizedBox(height: 8),
                          Text(
                            '$usageCount',
                            style: const TextStyle(
                              fontSize: 24, // Larger number
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Used',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // SPACER: Pushes buttons to bottom
            const Spacer(flex: 1),
            
            // ACTION BUTTONS: Edit, Toggle, Delete (AT BOTTOM OF CARD)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 6), // Slightly more spacing
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggle,
                    icon: Icon(isEnabled ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(isEnabled ? 'Off' : 'On'),
                  ),
                ),
                const SizedBox(width: 6), // Slightly more spacing
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Del'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}