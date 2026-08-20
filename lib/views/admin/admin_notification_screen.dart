import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
            .where('targetRole', isEqualTo: 'admin')
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

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notificationId = docs[index].id;

              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final userName = data['userName'] ?? 'User';
              final amount = data['amountPaid'] ?? '0';

              // 🕒 Timestamp formatting
              String formattedDate = '';
              if (data['timestamp'] != null) {
                Timestamp timestamp = data['timestamp'];
                DateTime dateTime = timestamp.toDate();
                formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // 🟢 Green background for notifications
                color: isDark ? const Color(0xFF1E1E1E) : Colors.green.shade50,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // 1️⃣ Click hote hi notification database aur screen se delete ho jaye gi
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notificationId)
                        .delete();

                    if (!mounted) return;

                    // 2️⃣ Phir ScholarAnswerView wali screen par chale jayenge
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScholarAnswerView(),
                      ),
                    );
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
                                  color: Color(0xFF004D40), // 🟢 Green title color
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(message),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'User: $userName | Paid: RS $amount',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (formattedDate.isNotEmpty)
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
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