import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ScholarNotificationsScreen extends StatelessWidget {
  final String currentScholarId;

  const ScholarNotificationsScreen({super.key, required this.currentScholarId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: isDark ? const Color(0xFF003D33) : const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scholar_notifications')
            .where('scholarId', isEqualTo: currentScholarId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No notifications yet.",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;
              bool isUnread = data['status'] == 'unread';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isUnread ? Colors.amber : Colors.grey,
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                title: Text(
                  data['title'] ?? "Notification",
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  data['message'] ?? "",
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
                trailing: isUnread
                    ? IconButton(
                        icon: const Icon(Icons.mark_email_read, color: Colors.green),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('scholar_notifications')
                              .doc(docId)
                              .update({'status': 'read'});
                        },
                      )
                    : null,
                onTap: () async {
                  if (isUnread) {
                    await FirebaseFirestore.instance
                        .collection('scholar_notifications')
                        .doc(docId)
                        .update({'status': 'read'});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
