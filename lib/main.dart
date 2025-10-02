import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_page.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads (with error handling)
  try {
    await AdService.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize ads: $e');
    // Continue without ads
  }
  
  runApp(const MemeMakerApp());
}

class MemeMakerApp extends StatelessWidget {
  const MemeMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meme Maker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
