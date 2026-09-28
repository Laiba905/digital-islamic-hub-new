import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminWithdrawalRequest extends StatelessWidget {
  const AdminWithdrawalRequest({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scholar_earnings_ledger')
            .where('status', isEqualTo: 'withdrawal_requested')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No pending payout requests."),
            );
          }

          var docs = snapshot.data!.docs;

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var docId = docs[index].id;
                  var data = docs[index].data() as Map<String, dynamic>;
                  String scholarName = data['scholarName'] ?? 'Scholar';
                  String scholarId = data['scholarId'] ?? '';
                  double amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(scholarId).get(),
                    builder: (context, userSnapshot) {
                      String paymentDetails = "Loading payment info...";
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        String accountTitle = userData['accountTitle'] ?? userData['name'] ?? 'N/A';
                        String accountNumber = userData['accountNumber'] ?? userData['phone'] ?? 'N/A';
                        String bankName = userData['bankName'] ?? userData['paymentMethod'] ?? 'JazzCash/EasyPaisa';
                        paymentDetails = "$bankName\nTitle: $accountTitle\nA/C: $accountNumber";
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(scholarName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.orange.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                                    child: Text("RS $amount", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(5) : Colors.blueGrey.withAlpha(10),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.blueGrey.withAlpha(20)),
                                ),
                                child: Text(
                                  paymentDetails,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () => _markAsPaid(context, docId, scholarId, amount),
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text("MARK AS PAID"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context, String docId, String scholarId, double amount) async {
    await FirebaseFirestore.instance.collection('scholar_earnings_ledger').doc(docId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'targetId': scholarId,
      'targetRole': 'scholar',
      'title': 'Payment Transferred! 💸',
      'message': 'Your withdrawal request of RS $amount has been successfully paid.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payout marked as paid!")),
      );
    }
  }
}
