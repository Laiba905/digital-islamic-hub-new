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
  bool _isDarkMode = false;
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
    final isDark = _isDarkMode || Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.amber, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                await FirebaseFirestore.instance.collection('scholar_notifications').doc(docId).update({'status': 'read'});
              },
              child: const Text("OK", style: TextStyle(color: Colors.amber)),
            ),
          ],
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
    final isDark = _isDarkMode ? true : Theme.of(context).brightness == Brightness.dark;
    String userName = user?.displayName ?? "Malaika Tariq";
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isWebOrTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FBE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
        ),
        title: const Text("Digital Islamic Hub", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('scholar_notifications').where('scholarId', isEqualTo: user?.uid).where('status', isEqualTo: 'unread').snapshots(),
            builder: (context, snapshot) {
              bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, size: 26, color: Colors.white),
                    onPressed: () {
                      if (user != null) Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarNotificationsScreen(currentScholarId: user!.uid)));
                    },
                  ),
                  if (hasUnread) Positioned(right: 10, top: 10, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWebOrTablet ? 800 : double.infinity),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Assalamu Alaikum,", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        Text(userName, style: TextStyle(color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 26)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                      child: const CircleAvatar(radius: 26, backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.person, color: Color(0xFF1B5E20))),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Notification Banner
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('scholar_notifications').where('scholarId', isEqualTo: user?.uid).orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    String displayMessage = "No notifications from Admin yet.";
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      displayMessage = snapshot.data!.docs.first.get('message') ?? 'New notification received';
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(20)),
                      child: Text(displayMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    );
                  },
                ),
                const SizedBox(height: 25),
                // Cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWebOrTablet ? 1.6 : 1.2,
                    children: [
                      _DashboardCard(
                        title: "Questions",
                        icon: Icons.chat_bubble_rounded,
                        color: Colors.orange,
                        onTap: () {
                          if (user != null) Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarQuestionsScreen(scholarId: user!.uid)));
                        },
                      ),
                      _DashboardCard(
                        title: "Payments",
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.blue,
                        onTap: () {
                          if (user != null) Navigator.push(context, MaterialPageRoute(builder: (context) => ScholarPaymentsScreen(scholarId: user!.uid)));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: color, size: 38), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))],
        ),
      ),
    );
  }
}