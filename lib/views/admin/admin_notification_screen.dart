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
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Mark all as read",
            onPressed: () async {
              try {
                final batch = FirebaseFirestore.instance.batch();
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('notifications')
                    .where('targetRole', isEqualTo: 'admin')
                    .where('isRead', isEqualTo: false)
                    .get();

                for (var doc in querySnapshot.docs) {
                  batch.update(doc.reference, {'isRead': true});
                }

                await batch.commit();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All notifications marked as read.")),
                  );
                }
              } catch (e) {
                debugPrint("Error marking all as read: $e");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear all",
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear Notifications"),
                  content: const Text("Delete all admin notifications?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete All", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('targetRole', isEqualTo: 'admin')
                      .get();

                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in querySnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notifications cleared.")),
                    );
                  }
                } catch (e) {
                  debugPrint("Error clearing notifications: $e");
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications found.', style: TextStyle(color: Colors.grey)),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final targetRole = (data['targetRole'] ?? '').toString().toLowerCase();
            final title = (data['title'] ?? '').toString().toLowerCase();

            if (targetRole == 'user' || title.contains('submitted successfully')) return false;

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
              child: Text('No notifications found.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notificationId = docs[index].id;
              final title = data['title'] ?? 'Notification';
              String bodyMessage = data['body'] ?? data['message'] ?? '';
              
              if (bodyMessage.isEmpty) {
                final sName = data['scholarName'];
                final amt = data['amount'];
                if (sName != null) {
                  bodyMessage = "Scholar: $sName" + (amt != null ? " requested Rs. $amt" : "");
                }
              }

              bodyMessage = bodyMessage.replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'), 'A user');
              bodyMessage = bodyMessage.replaceAll(RegExp(r'^\s*[a-zA-Z0-9]{8,}\s*'), 'A user ');

              final bool isRead = data['isRead'] ?? false;
              String formattedDate = '';
              var timestampField = data['createdAt'] ?? data['timestamp'];
              if (timestampField != null) {
                try {
                  Timestamp timestamp = timestampField;
                  DateTime dateTime = timestamp.toDate();
                  formattedDate = DateFormat('MMM d, hh:mm a').format(dateTime);
                } catch (e) {}
              }

              return Card(
                color: isDark ? theme.cardColor : (isRead ? Colors.white : theme.colorScheme.primary.withAlpha(20)),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final lowerTitle = title.toLowerCase();
                    if (lowerTitle.contains('withdrawal') || lowerTitle.contains('answered')) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ScholarAnswerView()));
                    } else if (lowerTitle.contains('payment') || lowerTitle.contains('question')) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QueriesPaymentsView()));
                    } else if (lowerTitle.contains('scholar') || lowerTitle.contains('verification') || lowerTitle.contains('request')) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ScholarRequestsView()));
                    }

                    try {
                      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'isRead': true});
                    } catch (e) {}
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                          child: Icon(Icons.notifications, color: isDark ? Colors.black : Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bodyMessage,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              if (formattedDate.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
                          },
                        ),
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
