import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'scholar_payments_screen.dart';
import 'scholar_questions_screen.dart';

class ScholarNotificationsScreen extends StatelessWidget {
  final String currentScholarId;
  final String scholarName;

  const ScholarNotificationsScreen({
    super.key,
    required this.currentScholarId,
    this.scholarName = "Scholar",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['createdAt'];
            Timestamp? timeB = dataB['createdAt'];
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final String timeStr = createdAt != null
                  ? DateFormat('EEE, dd MMM, hh:mm a').format(createdAt.toDate())
                  : 'Recent';

              final String title = data['title'] ?? 'Notification';
              final String notificationMessage = data['body'] ?? data['message'] ?? '';
              final bool isRead = data['isRead'] ?? false;

              // Unread notifications ke liye green prominent background, read ke liye simple
              final cardBackgroundColor = isRead
                  ? (isDark ? Colors.white.withAlpha(5) : Colors.white)
                  : (isDark ? AppTheme.accentGreen.withAlpha(25) : Colors.green.shade50);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isRead
                        ? (isDark ? Colors.white10 : Colors.grey.shade200)
                        : AppTheme.accentGreen.withAlpha(100),
                    width: isRead ? 1 : 1.5,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey.withAlpha(30) : AppTheme.accentGreen.withAlpha(40),
                    child: Icon(
                      isRead ? Icons.notifications_outlined : Icons.notifications_active,
                      color: isRead ? Colors.grey : AppTheme.accentGreen,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notificationMessage,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ],
                  ),
                  // Delete option button
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: "Delete Notification",
                    onPressed: () async {
                      // Firestore se notification delete kar dein
                      await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
                    },
                  ),
                  onTap: () {
                    if (!isRead) {
                      FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
                    }

                    String lowerTitle = title.toLowerCase();
                    String lowerMsg = notificationMessage.toLowerCase();

                    if (lowerTitle.contains('payment') ||
                        lowerTitle.contains('earning') ||
                        lowerTitle.contains('withdrawal') ||
                        lowerMsg.contains('rs') ||
                        lowerMsg.contains('added') ||
                        lowerMsg.contains('payout')) {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScholarPaymentsScreen(
                            scholarId: currentScholarId,
                            scholarName: scholarName,
                          ),
                        ),
                      );
                    } else if (lowerTitle.contains('question') ||
                        lowerMsg.contains('question')) {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScholarQuestionsScreen(
                            scholarId: currentScholarId,
                          ),
                        ),
                      );
                    } else if (lowerTitle.contains('issue') ||
                        lowerTitle.contains('complaint') ||
                        lowerMsg.contains('admin responded')) {

                      // Note: Agar ScholarMyComplaintsScreen bhi import nahi hai toh usko bhi import kar lijiyega
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScholarMyComplaintsScreen(
                            scholarId: currentScholarId,
                            isDark: isDark,
                          ),
                        ),
                      );
                    }
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