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
                ? [AppTheme.primaryLight, AppTheme.primaryDark]
                : [AppTheme.primaryLight, AppTheme.primaryDark],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            Image.asset(
              'assets/images/logo.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                    Icons.auto_awesome,
                    size: 100,
                    color: AppTheme.accentGreen
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              "Digital Islamic Hub",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5
              ),
            ),

            const Spacer(),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}