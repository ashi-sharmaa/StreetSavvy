import 'package:flutter/material.dart';
import 'vendor_home_screen.dart';

void main() {
  runApp(const StreetSavvyVendorApp());
}

class StreetSavvyVendorApp extends StatelessWidget {
  const StreetSavvyVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetSavvy Vendor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VendorHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}