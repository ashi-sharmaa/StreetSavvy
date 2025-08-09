import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              
              // Map widget - Fixed height container
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(33.2001, -96.6087), // McKinney, TX
                      zoom: 13.0,
                    ),
                    markers: {
                      const Marker(
                        markerId: MarkerId('McKinney'),
                        position: LatLng(33.1976, -96.6155),
                        infoWindow: InfoWindow(title: 'You are here'),
                      )
                    },
                    mapType: MapType.normal,
                    myLocationEnabled: false, // We'll enable this later with proper permissions
                    zoomControlsEnabled: true,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'Discover Promotions Nearby',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              
              // Carousel widget for promotions - Using PageView instead
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.8),
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    final promo = _promotions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: PromotionCard(
                        title: promo['title']!,
                        code: promo['code']!,
                        description: promo['description']!,
                        address: promo['address']!,
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

  void _openPromotionDetail(Map<String, String> promotion) {
    // TODO: Track engagement and show promotion details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promotion['title']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${promotion['code']}', 
                 style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Address: ${promotion['address']}'),
            const SizedBox(height: 8),
            Text(promotion['description']!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Track that user engaged with promotion
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
              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Code or Discount Name
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
              
              // Vendor address
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
              
              // Description
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Add "Open" button
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

// Test data - will be replaced with API calls later
final List<Map<String, String>> _promotions = [
  {
    'title': '50% Off Coffee | Starbucks',
    'code': 'COFFEE50',
    'address': '123 Fairview Lane, Dallas, TX, 75001',
    'description': 'Get 50% off your next coffee purchase at our downtown store.',
  },
  {
    'title': 'Free Shipping | CVS Photos',
    'code': 'FREESHIP',
    'address': '123 Fairview Lane, Dallas, TX, 75001',
    'description': 'Free shipping on all orders over \$50.',
  },
  {
    'title': 'Buy 1 Get 1 Free | 7-Eleven',
    'code': 'B1G1',
    'address': '123 Fairview Lane, Dallas, TX, 75001',
    'description': 'Buy one snack and get one free, limited time offer.',
  },
  {
    'title': 'Buy 1 Get 1 Free | 7-Eleven',
    'code': 'B1G1',
    'address': '123 Fairview Lane, Dallas, TX, 75001',
    'description': 'Buy one snack and get one free, limited time offer.',
  },
  {
    'title': 'Buy 1 Get 1 Free | 7-Eleven',
    'code': 'B1G1',
    'address': '123 Fairview Lane, Dallas, TX, 75001',
    'description': 'Buy one snack and get one free, limited time offer.',
  },
];