import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_islamic_hub_new/screens/scholar_questions_screen.dart';
import 'package:digital_islamic_hub_new/screens/scholar_payments_screen.dart';
import 'package:digital_islamic_hub_new/screens/scholar_profile_screen.dart';

class ScholarDashboard extends StatefulWidget {
  const ScholarDashboard({super.key});

  @override
  State<ScholarDashboard> createState() => _ScholarDashboardState();
}

class _ScholarDashboardState extends State<ScholarDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String userName = user?.displayName ?? "Scholar";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FBE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text("Scholar Dashboard", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // 👤 Profile Icon Button
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 26, color: Colors.white),
            tooltip: "Profile",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScholarProfileScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Assalamu Alaikum,", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              const SizedBox(height: 4),
              Text(userName, style: TextStyle(color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 26)),
              const SizedBox(height: 30),

              // 👇 Yahan humne Row use kiya hai taake cards ki width aur height dono controlled (choti) rahein
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800), // Web ke liye maximum width limit
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 260, // 👈 Yahan se aap cards ki height mazeed kam ya zyada kar sakte hain
                          child: _DashboardCard(
                            title: "Questions",
                            icon: Icons.chat_bubble_rounded,
                            color: Colors.orange,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarQuestionsScreen(scholarId: user!.uid))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Dono cards ke darmiyan fasla
                      Expanded(
                        child: SizedBox(
                          height: 260, // 👈 Height dono ki barabar rahegi
                          child: _DashboardCard(
                            title: "Payments",
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.blue,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarPaymentsScreen(scholarId: user!.uid))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 3))],
          border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}