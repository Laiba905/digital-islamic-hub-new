import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ScholarPaymentsScreen extends StatefulWidget {
  final String scholarId;

  const ScholarPaymentsScreen({super.key, required this.scholarId});

  @override
  State<ScholarPaymentsScreen> createState() => _ScholarPaymentsScreenState();
}

class _ScholarPaymentsScreenState extends State<ScholarPaymentsScreen> {

  // 🌟 Yeh function aap yahan state class ke andar lagayenge
  void _requestWithdrawal(BuildContext context, double totalAmount) {
    TextEditingController accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Withdrawal Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Aap ke withdrawable paise: RS $totalAmount hain."),
            const SizedBox(height: 12),
            TextField(
              controller: accountController,
              decoration: const InputDecoration(
                labelText: "Apna Account Number / JazzCash / EasyPaisa",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              String accountDetails = accountController.text.trim();
              if (accountDetails.isEmpty) {
                return;
              }

              // Firebase mein request save karna
              await FirebaseFirestore.instance.collection('withdrawal_requests').add({
                'scholarId': widget.scholarId,
                'amount': totalAmount,
                'accountDetails': accountDetails,
                'status': 'pending', // 'pending', 'approved', ya 'paid'
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Withdrawal request admin ko bhej di gayi hai!")),
              );
            },
            child: const Text("Send Request", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Scholar Payments & Earnings"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('scholarId', isEqualTo: widget.scholarId)
            .where('status', isEqualTo: 'answered')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No payment history or earnings found for this scholar.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            );
          }

          var docs = snapshot.data!.docs;
          double totalWithdrawableAmount = 0;
          DateTime now = DateTime.now();
          List<Widget> earningCards = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;

            double amount = double.tryParse(data['scholarShare']?.toString() ?? '50') ?? 50.0;
            Timestamp? answeredTimestamp = data['answeredAt'] as Timestamp?;
            DateTime answerDate = answeredTimestamp != null ? answeredTimestamp.toDate() : DateTime.now();

            Duration difference = now.difference(answerDate);
            bool isOneWeekPassed = difference.inDays >= 7;

            if (isOneWeekPassed) {
              totalWithdrawableAmount += amount;
            }

            earningCards.add(
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['questionText'] ?? "Question",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(answerDate),
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Rs. $amount",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOneWeekPassed ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (!isOneWeekPassed) {
                            int daysLeft = 7 - difference.inDays;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Aap yeh paise 1 haftay ke baad nikal sakte hain. Mazeed $daysLeft din baqi hain.")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Yeh amount withdrawal ke liye tayyar hai!")),
                            );
                          }
                        },
                        child: Text(
                          isOneWeekPassed ? "Withdraw" : "Locked (7 Days)",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ready to Withdraw (1 Week Completed)",
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Rs. $totalWithdrawableAmount",
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: totalWithdrawableAmount > 0
                          ? () => _requestWithdrawal(context, totalWithdrawableAmount)
                          : null,
                      child: const Text("Cashout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: earningCards,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}