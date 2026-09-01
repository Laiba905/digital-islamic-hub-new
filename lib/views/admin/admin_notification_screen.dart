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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
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

            return targetRole == 'admin' ||
                title.contains('payment') ||
                title.contains('withdrawal') ||
                title.contains('verification') ||
                title.contains('scholar') ||
                title.contains('answered');
          }).toList();

          docs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['createdAt'] ?? aData['timestamp'];
            Timestamp? bTime = bData['createdAt'] ?? bData['timestamp'];

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

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

              // 🔍 Automatic fallback agar body field missing ho
              String bodyMessage = data['body'] ?? data['message'] ?? '';
              if (bodyMessage.isEmpty) {
                final sName = data['scholarName'];
                final amt = data['amount'];
                if (sName != null) {
                  bodyMessage = "Scholar: $sName" + (amt != null ? " requested Rs. $amt" : "");
                }
              }

              final bool isRead = data['isRead'] ?? false;

              String formattedDate = '';
              var timestampField = data['createdAt'] ?? data['timestamp'];
              if (timestampField != null) {
                try {
                  Timestamp timestamp = timestampField;
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
                color: isDark
                    ? theme.cardColor
                    : (isRead ? Colors.white : theme.colorScheme.primary.withOpacity(0.08)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final lowerTitle = title.toLowerCase();

                    if (lowerTitle.contains('withdrawal') || lowerTitle.contains('answered')) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ScholarAnswerView()));
                    } else if (lowerTitle.contains('payment') || lowerTitle.contains('question')) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QueriesPaymentsView()));
                    } else if (lowerTitle.contains('scholar') || lowerTitle.contains('verification') || lowerTitle.contains('request')) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ScholarRequestsView()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Notification marked as read.")),
                      );
                    }

                    try {
                      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
                        'isRead': true,
                      });
                    } catch (e) {}
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.notifications_active, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark ? Colors.white : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              if (bodyMessage.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  bodyMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.tealAccent : Colors.teal[800],
                                  ),
                                ),
                              ],
                              if (formattedDate.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : Colors.blueGrey,
                                      fontWeight: FontWeight.w500
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: "Delete Notification",
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Notification deleted successfully"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint("Error deleting notification: $e");
                            }
                          },
                        ),
                        const SizedBox(width: 4),
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