import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'scholar_questions_screen.dart';
import 'scholar_payments_screen.dart';

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
        // 👈 Yahan 'isRead == false' ka filter laga diya hai taake read hote hi notification list se hat jaye
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('scholarId', isEqualTo: currentScholarId)
            .where('targetRole', isEqualTo: 'scholar')
            .where('isRead', isEqualTo: false)
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

          var docs = snapshot.data!.docs;

          // Latest notifications ko pehle dikhane ke liye sort kar rahe hain
          docs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['createdAt'] ?? aData['timestamp'];
            Timestamp? bTime = bData['createdAt'] ?? bData['timestamp'];
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              String title = data['title'] ?? "Notification";
              String message = data['message'] ?? data['body'] ?? "";

              // Kyunke query mein sirf unread hain, isliye yeh hamesha true hoga
              bool isUnread = true;

              // Helper function to handle Read & Navigation
              Future<void> handleTapOrRead() async {
                // Database mein isRead ko true kar dein ge taake query se yeh foran nikal jaye
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(docId)
                    .update({'status': 'read', 'isRead': true});

                // Title ya message ke mutabiq screen par navigate karein
                if (context.mounted) {
                  if (title.contains("Question") || message.contains("question")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScholarQuestionsScreen(scholarId: currentScholarId),
                      ),
                    );
                  } else if (title.contains("Earning") || message.contains("earnings") || message.contains("ledger")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScholarPaymentsScreen(scholarId: currentScholarId),
                      ),
                    );
                  }
                }
              }

              return Card(
                color: isDark ? Colors.white.withAlpha(13) : Colors.green.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    message,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.mark_email_read, color: Colors.green),
                    tooltip: "Mark as read & Open",
                    onPressed: handleTapOrRead,
                  ),
                  onTap: handleTapOrRead,
                ),
              );
            },
          );
        },
      ),
    );
  }
}