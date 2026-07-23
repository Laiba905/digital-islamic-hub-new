import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarEarningsView extends StatelessWidget {
  final String scholarId;
  const ScholarEarningsView({super.key, required this.scholarId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings & Wallet'),
        backgroundColor: const Color(0xFF004D40),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scholar_earnings_ledger')
            .where('scholarId', isEqualTo: scholarId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          double totalBalance = 0.0;
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            totalBalance += (data['amount'] ?? 0.0) as double;
          }

          // 1 Hafte (7 Days) ka check
          bool canWithdraw = false;
          if (docs.isNotEmpty) {
            Timestamp firstEntryTime = docs.first['createdAt'] ?? Timestamp.now();
            DateTime date = firstEntryTime.toDate();
            if (DateTime.now().difference(date).inDays >= 7) {
              canWithdraw = true;
            }
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Accumulated Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("RS $totalBalance", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canWithdraw ? Colors.amber : Colors.grey,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: canWithdraw ? () {
                        // Withdraw Logic Yahan Aayegi
                      } : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Withdrawal locked! Funds can only be withdrawn after 1 week.")),
                        );
                      },
                      child: Text(canWithdraw ? "Withdraw" : "Locked (1 Week)"),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Earnings History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    double amount = data['amount'] ?? 0.0;
                    Timestamp? t = data['createdAt'];
                    String dateStr = t != null ? t.toDate().toString().split('.').first : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF004D40),
                          child: Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                        title: const Text("Question Resolution Share"),
                        subtitle: Text("Credited on: $dateStr"),
                        trailing: Text("+ RS $amount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}