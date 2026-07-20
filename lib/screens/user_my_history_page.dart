import 'dart:convert'; // Base64 screenshot decode karne ke liye
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMyHistoryPage extends StatelessWidget {
  const UserMyHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Verification History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF003D33) : const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: currentUserId == null
          ? const Center(child: Text("Please log in to view history."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          var historyDocs = snapshot.data?.docs ?? [];

          if (historyDocs.isEmpty) {
            return Center(
              child: Text(
                "No scholar verifications requested yet.",
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: historyDocs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var data = historyDocs[index].data() as Map<String, dynamic>;

              String status = data['status'] ?? 'pending_verification';
              Color statusColor = Colors.orange;
              String statusText = "Pending Admin Review";

              if (status == 'sent_to_scholar') {
                statusColor = Colors.blue;
                statusText = "Assigned to Scholar";
              } else if (status == 'answered') {
                statusColor = Colors.green;
                statusText = "Answered by Scholar";
              }

              // 🚀 FETCH FIX: Check both 'aiResponse' and 'aiAnswer' just in case
              String aiResponseText = data['aiResponse'] ?? data['aiAnswer'] ?? '';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.green.shade50),
                ),
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 💳 Top Row: TID and Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TID: ${data['transactionId'] ?? 'N/A'}',
                            style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                                fontSize: 13,
                                fontStyle: FontStyle.italic
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PKR ${data['amountPaid'] ?? '100'}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 25),

                      // ❓ User Question
                      const Text(
                        'Your Question:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['questionText'] ?? 'No text.',
                        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 15),

                      // 🤖 AI Answer Section (Khoobsurat Layout Design)
                      if (aiResponseText.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blueGrey.withOpacity(0.1) : Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.smart_toy_rounded, color: Colors.blueGrey.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Initial AI Answer:',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700, fontSize: 13),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.black12, height: 15),
                              Text(
                                aiResponseText,
                                style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade800, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // 🖼️ Payment Screenshot Display
                      if (data['paymentScreenshot'] != null && data['paymentScreenshot'].toString().isNotEmpty) ...[
                        Text(
                          'Payment Screenshot:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(data['paymentScreenshot']),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Text("Error loading image"),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // 🔄 Current Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),

                      // 🌟 Scholar Answer Section (Sirf tab dikhe jab scholar jwb de de)
                      if (status == 'answered' && data['scholarAnswer'] != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1).withOpacity(isDark ? 0.1 : 1.0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF004D40).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified_user, color: Color(0xFF004D40), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Scholar Verification Answer:',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), fontSize: 13),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.black12, height: 15),
                              Text(
                                data['scholarAnswer'],
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: isDark ? Colors.white : const Color(0xFF004D40),
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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