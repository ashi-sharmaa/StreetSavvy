import 'package:flutter/material.dart';
import '../../services/api_service.dart';  // Add this import

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }
  
  Future<void> _loadPromotions() async {
    // Load real campaigns from your backend
    final campaigns = await ApiService.getActiveCampaigns();
    
    setState(() {
      _promotions = campaigns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())  // Show loading
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Check out what's nearby you:",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Map placeholder (same as before)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade100,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Map will appear here', 
                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('McKinney, TX area', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    'Discover Promotions Nearby',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  
                  // Real campaigns from database
                  SizedBox(
                    height: 250,
                    child: _promotions.isEmpty 
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
                                address: 'Vendor ${promo['vendor_id']}',  // We'll improve this later
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

  // Keep your existing _openPromotionDetail method
  void _openPromotionDetail(Map<String, dynamic> promotion) {
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
            Text('Vendor: ${promotion['vendor_id']}'),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Promotion activated!')),
              );
            },
            child: const Text('Use Promotion'),
          ),
        ],
      ),
    );
  }
}

// Keep your existing PromotionCard widget unchanged
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