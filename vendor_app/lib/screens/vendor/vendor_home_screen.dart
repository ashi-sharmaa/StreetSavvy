import 'package:flutter/material.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vendor Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _createNewCampaign,
                    icon: const Icon(Icons.add),
                    label: const Text('New Campaign'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heatmap on the left
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    Icon(
                                      Icons.map,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Heatmap Will Display Here',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
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
                    
                    const SizedBox(width: 24),
                    
                    // Campaigns on the right
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Campaigns',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.85),
                              itemCount: _campaigns.length,
                              itemBuilder: (context, index) {
                                final campaign = _campaigns[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: CampaignCard(
                                    title: campaign['title']!,
                                    code: campaign['code']!,
                                    description: campaign['description']!,
                                    address: campaign['address']!,
                                    isEnabled: campaign['enabled'] == 'true',
                                    engagementCount: int.parse(campaign['engagements'] ?? '0'),
                                    usageCount: int.parse(campaign['usage'] ?? '0'),
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

  void _createNewCampaign() {
    // TODO: Navigate to campaign creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new campaign - Coming soon!')),
    );
  }

  void _configureHeatmap() {
    // TODO: Show heatmap configuration dialog
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

  void _editCampaign(Map<String, String> campaign) {
    // TODO: Navigate to campaign edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${campaign['title']} - Coming soon!')),
    );
  }

  void _toggleCampaign(Map<String, String> campaign) {
    // TODO: Toggle campaign enabled state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Toggle ${campaign['title']} - Coming soon!')),
    );
  }

  void _deleteCampaign(Map<String, String> campaign) {
    // TODO: Delete campaign
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

class CampaignCard extends StatelessWidget {
  final String title;
  final String code;
  final String address;
  final String description;
  final bool isEnabled;
  final int engagementCount;
  final int usageCount;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const CampaignCard({
    super.key,
    required this.title,
    required this.code,
    required this.address,
    required this.description,
    required this.isEnabled,
    required this.engagementCount,
    required this.usageCount,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isEnabled ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
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
              const SizedBox(height: 6),
              
              // Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Address
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Engagement stats
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$engagementCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Clicks',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$usageCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Used',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      isEnabled ? Icons.toggle_on : Icons.toggle_off,
                      size: 18,
                      color: isEnabled ? Colors.green : Colors.grey,
                    ),
                    tooltip: isEnabled ? 'Disable' : 'Enable',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Test data - will be replaced with API calls later
final List<Map<String, String>> _campaigns = [
  {
    'title': '50% Off Coffee | Starbucks',
    'code': 'COFFEE50',
    'address': '123 Fairview Lane, Dallas, TX, 75001',
    'description': 'Get 50% off your next coffee purchase at our downtown store.',
    'enabled': 'true',
    'engagements': '24',
    'usage': '8',
  },
  {
    'title': 'Free Shipping | CVS Photos',
    'code': 'FREESHIP',
    'address': '456 Main Street, Dallas, TX, 75002',
    'description': 'Free shipping on all orders over \$50.',
    'enabled': 'false',
    'engagements': '12',
    'usage': '3',
  },
  {
    'title': 'Buy 1 Get 1 Free | 7-Eleven',
    'code': 'B1G1',
    'address': '789 Oak Avenue, Dallas, TX, 75003',
    'description': 'Buy one snack and get one free, limited time offer.',
    'enabled': 'true',
    'engagements': '45',
    'usage': '22',
  },
  {
    'title': '20% Off Electronics | Best Buy',
    'code': 'TECH20',
    'address': '321 Technology Blvd, Dallas, TX, 75004',
    'description': 'Save 20% on all electronics this weekend only.',
    'enabled': 'true',
    'engagements': '67',
    'usage': '31',
  },
  {
    'title': 'Free Appetizer | Chili\'s',
    'code': 'FREEAPP',
    'address': '654 Restaurant Row, Dallas, TX, 75005',
    'description': 'Get a free appetizer with any entree purchase.',
    'enabled': 'false',
    'engagements': '18',
    'usage': '9',
  },
];