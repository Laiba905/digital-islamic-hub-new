import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../core/database/db_helper.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  void _startApp() async {
    try {
      // 1. Give UI a moment to render
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Initialize Notifications
      setState(() => _status = "Setting up notifications...");
      await NotificationService.init();

      // 3. Initialize Databases (Heaviest part)
      setState(() => _status = "Preparing Quran & Hadith...");
      await DBHelper.db; // This will trigger the copy if needed
      await DBHelper.hadithDb;

      // 4. Check Authentication
      setState(() => _status = "Checking session...");
      User? user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => _status = "Error: Please restart the app");
      print("Startup Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF003D33), AppTheme.primaryDark]
                : [AppTheme.primaryLight, AppTheme.primaryDark],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              'assets/images/islamic_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_awesome, size: 80, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const Text(
              "Digital Islamic Hub",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _status, // Show real-time status to user
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
