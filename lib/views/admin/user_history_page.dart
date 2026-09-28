import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserHistoryPage extends StatelessWidget {
  const UserHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Payments History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user_questions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var records = snapshot.data?.docs ?? [];
          if (records.isEmpty) {
            return const Center(child: Text("No history found."));
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView.builder(
                padding: EdgeInsets.all(screenWidth < 600 ? 16 : 24),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  var data = records[index].data() as Map<String, dynamic>;

                  String uName = data['userName'] ?? 'Unknown User';
                  String uEmail = data['userEmail'] ?? 'No Email';
                  String tId = data['transactionId'] ?? 'N/A';
                  String amount = data['amountPaid']?.toString() ?? '0';
                  String question = data['questionText'] ?? 'No Question Provided.';
                  String? screenshotUrl = data['screenshot'] ?? data['paymentScreenshot'] ?? data['screenshotUrl'];

                  String formattedDate = 'N/A';
                  if (data['verifiedAt'] != null) {
                    formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format((data['verifiedAt'] as Timestamp).toDate());
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      leading: CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF81C784).withAlpha(40) : const Color(0xFF004D40).withAlpha(20),
                        child: Icon(Icons.account_balance_wallet, color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40)),
                      ),
                      title: Text(uName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('TID: $tId | Amount: RS $amount', style: const TextStyle(fontSize: 12)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              Text('📧 Email: $uEmail', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('📅 Verified: $formattedDate', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 16),
                              const Text('Question:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: Text(question, style: const TextStyle(fontSize: 13, height: 1.4)),
                              ),
                              const SizedBox(height: 16),
                              if (screenshotUrl != null && screenshotUrl.isNotEmpty) ...[
                                const Text('Payment Receipt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    screenshotUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
