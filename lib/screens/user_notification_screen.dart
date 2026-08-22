import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🚀 Logged-in user ke liye import kiya hai
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_answer_screen.dart';
import '../theme/app_theme.dart';

class UserNotificationScreen extends StatelessWidget {
  const UserNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🚀 Current logged-in user ki unique ID nikalna
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("User Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🚀 Sirf wahi notifications fetch hongi jo is user ki ID se match karti hain
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications yet!", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)));
          }

          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String targetRole = data['targetRole'] ?? '';
            String title = (data['title'] ?? '').toString().toLowerCase();

            if (targetRole == 'admin' || title.contains('new payment & question')) {
              return false;
            }
            return true;
          }).toList();

          if (docs.isEmpty) {
            return Center(child: Text("No notifications yet!", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              bool isRead = data['isRead'] ?? false;

              String rawTitle = data['title'] ?? data['heading'] ?? 'Answer Received! ✅';
              String title = rawTitle;
              if (rawTitle.toLowerCase().contains('answer received') || rawTitle.toLowerCase().contains('new answer')) {
                title = 'Answer Received! ✅';
              }

              String rawBody = data['body'] ?? data['message'] ?? data['description'] ?? 'Your question has been answered.';
              String body = rawBody;
              if (rawBody.toLowerCase().contains('has answered your question')) {
                body = "A scholar has responded to your question.";
              }

              String formattedDate = '';
              if (data['timestamp'] != null) {
                try {
                  Timestamp timestamp = data['timestamp'];
                  DateTime dateTime = timestamp.toDate();
                  formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
                } catch (e) {
                  formattedDate = '';
                }
              }

              return Card(
                color: isRead
                    ? (isDark ? Colors.white.withAlpha(12) : Colors.white)
                    : (isDark ? AppTheme.accentGreen.withAlpha(20) : AppTheme.primaryLight.withAlpha(10)),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                      color: isRead
                          ? (isDark ? Colors.white10 : Colors.grey.shade200)
                          : (isDark ? AppTheme.accentGreen.withAlpha(50) : AppTheme.primaryLight.withAlpha(30))
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey.shade400 : AppTheme.accentGreen,
                    child: Icon(Icons.notifications_active, color: isRead ? Colors.white : AppTheme.primaryDark, size: 20),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(docId)
                        .update({'isRead': true});

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserAnswerScreen(),
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