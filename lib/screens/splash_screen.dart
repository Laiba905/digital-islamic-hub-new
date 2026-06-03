import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen())
        );
      }
    });
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
            const Spacer(), // Logo ko center mein rakhne ke liye vertical spacing

            // 🎯 APP LOGO INTEGRATION
            // Agar aapke logo ka naam ya path different hai to yahan change kar sakti hain
            Image.asset(
              'assets/images/logo.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Background safe fallback agar image load na ho ya path galat ho
                return const Icon(
                    Icons.auto_awesome,
                    size: 100,
                    color: AppTheme.accentGreen
                );
              },
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              "Digital Islamic Hub",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5
              ),
            ),

            const Spacer(), // Niche spacing push karne ke liye

            // ⏳ PREMIUM LOADING INDICATOR
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(height: 40), // Bottom edge se safe distance
          ],
        ),
      ),
    );
  }
}