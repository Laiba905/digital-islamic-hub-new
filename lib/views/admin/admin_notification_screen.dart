import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'scholar_requests_view.dart';
import 'queries_payments_view.dart';
import 'scholar_answer_view.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final targetRole = (data['targetRole'] ?? '').toString().toLowerCase();
            final title = (data['title'] ?? '').toString().toLowerCase();

            if (targetRole == 'user' || title.contains('submitted successfully')) {
              return false;
            }

            // 🚀 'question' hata diya hai taake yeh list mein show na ho
            return targetRole == 'admin' ||
                title.contains('payment') ||
                title.contains('verification') ||
                title.contains('scholar') ||
                title.contains('answered');
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No admin notifications found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notificationId = docs[index].id;
              final title = data['title'] ?? 'Notification';

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
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.green.shade50,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final lowerTitle = title.toLowerCase();

                    if (lowerTitle.contains('answered')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScholarAnswerView(),
                        ),
                      );
                    } else if (lowerTitle.contains('scholar') || lowerTitle.contains('verification')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScholarRequestsView(),
                        ),
                      );
                    } else if (lowerTitle.contains('payment')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QueriesPaymentsView(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Notification read kar li gayi hai."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notificationId)
                          .delete();
                    } catch (e) {
                      // ignore error
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF004D40),
                          child: Icon(Icons.notifications_active, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                              if (formattedDate.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}