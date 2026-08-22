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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('scholarId', isEqualTo: currentScholarId)
            .where('targetRole', isEqualTo: 'scholar')
            .where('isRead', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
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

          docs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['createdAt'] ?? aData['timestamp'];
            Timestamp? bTime = bData['createdAt'] ?? bData['timestamp'];
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              String title = data['title'] ?? "Notification";
              String message = data['message'] ?? data['body'] ?? "";

              Future<void> handleTapOrRead() async {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(docId)
                    .update({'status': 'read', 'isRead': true});

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
                color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isDark ? Colors.white10 : AppTheme.primaryLight.withAlpha(30))
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentGreen,
                    child: Icon(Icons.notifications, color: AppTheme.primaryDark, size: 20),
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
                    icon: Icon(Icons.mark_email_read, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
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