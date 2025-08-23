import 'package:flutter/material.dart';
import 'api_service.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  // STATE VARIABLES: Data storage for the screen
  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic> _vendorSummary = {};
  bool _isLoading = true;
  String _currentVendorId = 'V0001';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  // Enhanced data loading to get both campaigns and summary
  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final analyticsData = await VendorApiService.getVendorAnalytics(_currentVendorId);
      
      if (analyticsData != null) {
        final campaigns = VendorApiService.getCampaignsFromAnalytics(analyticsData);
        final summary = VendorApiService.getVendorSummary(analyticsData);
        
        setState(() {
          _campaigns = campaigns;
          _vendorSummary = summary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _campaigns = [];
          _vendorSummary = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _campaigns = [];
        _vendorSummary = {};
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
            children: [
              // TOP HEADER: Same as before
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vendor $_currentVendorId Analytics',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.business),
                        onSelected: (String vendorId) {
                          setState(() {
                            _currentVendorId = vendorId;
                            _loadAnalytics();
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'V0001', child: Text('V0001 (Panera)')),
                          const PopupMenuItem(value: 'V0002', child: Text('V0002 (Valero)')),
                          const PopupMenuItem(value: 'V0003', child: Text('V0003 (Starbucks)')),
                        ],
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _createNewCampaign,
                        child: const Text('New Campaign'),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // MAIN CONTENT: Enhanced layout
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDE: Analytics Dashboard (replaces heatmap)
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Performance Analytics',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // ANALYTICS DASHBOARD
                              Expanded(
                                child: AnalyticsDashboard(
                                  vendorSummary: _vendorSummary,
                                  campaigns: _campaigns,
                                  vendorId: _currentVendorId,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // RIGHT SIDE: Campaign cards (same as before)
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Campaigns (${_campaigns.length})',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
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
                                            title: campaign['title'] ?? 'Unknown Campaign',
                                            code: campaign['code'] ?? 'NO-CODE',
                                            description: 'Campaign analytics',
                                            address: 'Vendor $_currentVendorId',
                                            isEnabled: campaign['enabled'] == true,
                                            engagementCount: campaign['total_clicks'] ?? 0,
                                            usageCount: campaign['total_uses'] ?? 0,
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

  // Button handlers (same as before)
  void _createNewCampaign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new campaign - Coming soon!')),
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

// NEW: Analytics Dashboard Widget
class AnalyticsDashboard extends StatelessWidget {
  final Map<String, dynamic> vendorSummary;
  final List<Map<String, dynamic>> campaigns;
  final String vendorId;

  const AnalyticsDashboard({
    super.key,
    required this.vendorSummary,
    required this.campaigns,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalClicks = campaigns.fold<int>(0, (int sum, Map<String, dynamic> c) => sum + ((c['total_clicks'] as int?) ?? 0));
    final totalUses = campaigns.fold<int>(0, (int sum, Map<String, dynamic> c) => sum + ((c['total_uses'] as int?) ?? 0));
    final conversionRate = vendorSummary['overall_conversion_rate'] ?? 0.0;
    
    return Column(
      children: [
        // OVERVIEW METRICS ROW
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Clicks',
                value: '$totalClicks',
                icon: Icons.touch_app,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Total Uses',
                value: '$totalUses',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // CONVERSION RATE CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                '${conversionRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Conversion Rate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // CAMPAIGN PERFORMANCE LIST
        Text(
          'Campaign Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: campaigns.isEmpty
            ? const Center(
                child: Text(
                  'No campaign data available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  return CampaignPerformanceItem(campaign: campaign);
                },
              ),
        ),
      ],
    );
  }
}

// Metric Card Widget
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Campaign Performance Item
class CampaignPerformanceItem extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const CampaignPerformanceItem({
    super.key,
    required this.campaign,
  });

  @override
  Widget build(BuildContext context) {
    final clicks = campaign['total_clicks'] ?? 0;
    final uses = campaign['total_uses'] ?? 0;
    final conversionRate = clicks > 0 ? (uses / clicks * 100) : 0.0;
    final isEnabled = campaign['enabled'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Campaign info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${campaign['code'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Metrics
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$clicks',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                  Text(
                    '$uses',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${conversionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Campaign Card (same as before, keeping your existing implementation)
class CampaignCard extends StatelessWidget {
  final String title;
  final String code;
  final String description;
  final String address;
  final bool isEnabled;
  final int engagementCount;
  final int usageCount;
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
            
            const Spacer(flex: 1),
            
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app, color: Colors.blue, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '$engagementCount',
                            style: const TextStyle(
                              fontSize: 24,
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
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '$usageCount',
                            style: const TextStyle(
                              fontSize: 24,
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
            
            const Spacer(flex: 1),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggle,
                    icon: Icon(isEnabled ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(isEnabled ? 'Off' : 'On'),
                  ),
                ),
                const SizedBox(width: 6),
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