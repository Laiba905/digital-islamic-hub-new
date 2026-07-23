import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'scholar_questions_screen.dart';
import 'scholar_payments_screen.dart';
import 'profile_screen.dart';
import 'scholar_notifications_screen.dart';

class ScholarDashboard extends StatefulWidget {
  const ScholarDashboard({super.key});

  @override
  State<ScholarDashboard> createState() => _ScholarDashboardState();
}

class _ScholarDashboardState extends State<ScholarDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _listenToIncomingNotifications();
  }

  void _listenToIncomingNotifications() {
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('scholar_notifications')
        .where('scholarId', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          String docId = change.doc.id;
          String title = data['title'] ?? "Alert";
          String message = data['message'] ?? "New update available.";

          _showTopNotificationBanner(title, message, docId);
        }
      }
    });
  }

  void _showTopNotificationBanner(String title, String message, String docId) {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.amber, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  await FirebaseFirestore.instance.collection('scholar_notifications').doc(docId).update({'status': 'read'});
                },
                child: const Text("OK", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF002921) : const Color(0xFF1B5E20),
        duration: const Duration(seconds: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 160, left: 16, right: 16),
      ),
    );
  }

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
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 26, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarNotificationsScreen(currentScholarId: user!.uid))),
          ),
          const SizedBox(width: 12),
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
              const SizedBox(height: 24),
              // crossAxisCount ko 4 kar diya hai taake sab aik line mein aa jayein
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2, // Chhotay aur compact cards ke liye
                children: [
                  _DashboardCard(
                    title: "Questions",
                    icon: Icons.chat_bubble_rounded,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarQuestionsScreen(scholarId: user!.uid))),
                  ),
                  _DashboardCard(
                    title: "Payments",
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarPaymentsScreen(scholarId: user!.uid))),
                  ),
                  _DashboardCard(
                    title: "Profile",
                    icon: Icons.person_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                  ),
                  _DashboardCard(
                    title: "Logout",
                    icon: Icons.logout_rounded,
                    color: Colors.red,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))],
          border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }
}