import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 🚀 Date format ke liye package import kiya hai
import 'user_answer_screen.dart'; // Make sure this path matches your project structure

class UserNotificationScreen extends StatelessWidget {
  const UserNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet!"));
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
            return const Center(child: Text("No notifications yet!"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              bool isRead = data['isRead'] ?? false;

              // Title ko English mein convert karna
              String rawTitle = data['title'] ?? data['heading'] ?? 'Answer Received! ✅';
              String title = rawTitle;
              if (rawTitle.toLowerCase().contains('answer received') || rawTitle.toLowerCase().contains('new answer')) {                title = 'Answer Received! ✅';
              }

              // Body ko English mein set karna
              String rawBody = data['body'] ?? data['message'] ?? data['description'] ?? 'Your question has been answered.';
              String body = rawBody;
              if (rawBody.toLowerCase().contains('has answered your question')) {                body = "A scholar has responded to your question.";
              }

              // 🚀 Timestamp (Date & Time) ko format karna
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
                color: isRead ? Colors.white : Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.blue),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    // 1. Mark notification as read in Firestore
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(docId)
                        .update({'isRead': true});

                    // 2. Navigate to UserAnswerScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserAnswerScreen(),
                      ),
                    );
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