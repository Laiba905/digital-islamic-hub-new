import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ScholarNotificationsScreen extends StatelessWidget {
  final String currentScholarId;
  const ScholarNotificationsScreen({super.key, required this.currentScholarId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Scholar Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('scholarId', isEqualTo: currentScholarId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 60, color: isDark ? Colors.white24 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No notifications yet", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final String timeStr = createdAt != null 
                  ? DateFormat('EEE, dd MMM, hh:mm a').format(createdAt.toDate()) 
                  : 'Recent';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
                  boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentGreen.withAlpha(30),
                    child: const Icon(Icons.notifications, color: AppTheme.accentGreen),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        data['message'] ?? '',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    FirebaseFirestore.instance.collection('notifications').doc(docs[index].id).update({'isRead': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
