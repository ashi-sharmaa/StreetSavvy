
import 'package:flutter/material.dart';
import 'screens/user/user_home_screen.dart';

void main() {
  runApp(const StreetSavvyUserApp());
}

class StreetSavvyUserApp extends StatelessWidget {
  const StreetSavvyUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetSavvy User',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UserHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}