import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScholarPaymentsScreen extends StatefulWidget {
  final String scholarId;

  const ScholarPaymentsScreen({super.key, required this.scholarId});

  @override
  State<ScholarPaymentsScreen> createState() => _ScholarPaymentsScreenState();
}

class _ScholarPaymentsScreenState extends State<ScholarPaymentsScreen> {

  void _processItemWithdrawal(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Withdrawal"),
        content: Text("Aap Rs. ${amount.toStringAsFixed(0)} withdraw karna chahte hain?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Aap ko aglay kuch time baad paise account mein transfer kar diye jayenge!"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🖼️ Pop-up function to show Receipt & Screenshot for a specific transaction
  void _showSingleReceiptPopup(BuildContext context, Map<String, dynamic> data, bool isDark) {
    String transactionId = data['transactionId'] ?? 'TRX-Pending / Not Provided';
    String imageUrl = data['paymentScreenshot'] ?? data['screenshot'] ?? data['receiptUrl'] ?? data['paymentProofUrl'] ?? '';
    double amount = double.tryParse(data['paidAmount']?.toString() ?? data['scholarShare']?.toString() ?? '50') ?? 50.0;

    Timestamp? paidTimestamp = data['paidAt'] as Timestamp? ?? data['answeredAt'] as Timestamp?;
    String formattedDayTime = "N/A";
    if (paidTimestamp != null) {
      formattedDayTime = DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(paidTimestamp.toDate());
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Payment Receipt & Proof", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Amount: RS ${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                const SizedBox(height: 8),
                Text("Transaction ID: $transactionId", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent : const Color(0xFF004D40))),
                const SizedBox(height: 4),
                Text("Date & Time: $formattedDayTime", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 20),
                const Text("Payment Screenshot / Proof:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text("Image load nahi ho saki.", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Koi screenshot attach nahi hai.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
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
          double totalEarnings = 0;
          double paidAmountTotal = 0;
          List<Map<String, dynamic>> paidQuestionsList = [];

          DateTime now = DateTime.now();

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;

            double amount = double.tryParse(data['scholarShare']?.toString() ?? data['amount']?.toString() ?? '50') ?? 50.0;
            totalEarnings += amount;

            bool isPaid = data['isPaidToScholar'] ?? false;
            if (isPaid) {
              paidAmountTotal += amount;
              paidQuestionsList.add(data);
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
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
                          "Total Earnings",
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs. ${totalEarnings.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Paid: Rs. ${paidAmountTotal.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScholarPaymentDetailsScreen(
                              scholarId: widget.scholarId,
                              paidQuestions: paidQuestionsList.isNotEmpty
                                  ? paidQuestionsList
                                  : docs.map((e) => e.data() as Map<String, dynamic>).toList(),
                              isDark: isDark,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet, size: 16),
                      label: const Text(
                        "Cashout History",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    double amount = double.tryParse(data['scholarShare']?.toString() ?? '50') ?? 50.0;
                    String userId = data['userId'] ?? 'unknown_user';

                    Timestamp? answeredTimestamp = data['answeredAt'] as Timestamp?;
                    DateTime answerDate = answeredTimestamp != null ? answeredTimestamp.toDate() : DateTime.now();

                    bool isPaid = data['isPaidToScholar'] ?? false;
                    bool is7DaysPassed = now.difference(answerDate).inDays >= 7;
                    bool isUnlocked = isPaid || is7DaysPassed;

                    String transactionId = data['transactionId'] ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        String displayName = "User";

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          String? fetchedName = userData?['displayName'] ?? userData?['name'] ?? userData?['fullName'] ?? userData?['userName'];
                          String? fetchedEmail = userData?['email'] ?? userData?['userEmail'];

                          if (fetchedName != null && fetchedName.trim().isNotEmpty) {
                            displayName = fetchedName;
                          } else if (fetchedEmail != null && fetchedEmail.contains('@')) {
                            displayName = fetchedEmail.split('@').first;
                          } else {
                            displayName = "User ($userId)";
                          }
                        } else if (data['userName'] != null && data['userName'].toString().trim().isNotEmpty && data['userName'] != "User") {
                          displayName = data['userName'];
                        } else if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
                          displayName = data['name'];
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // User Name Displayed Here
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 14, color: Color(0xFF2E7D32)),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.tealAccent : const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['questionText'] ?? "Question",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(answerDate),
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            "Rs. ${amount.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                          if (isPaid) ...[
                                            const SizedBox(width: 10),
                                            InkWell(
                                              onTap: () => _showSingleReceiptPopup(context, data, isDark),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.green),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.receipt, size: 12, color: Colors.green),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      transactionId.isNotEmpty ? "ID: $transactionId" : "Payment Transferred",
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Agar payment already ho chuki hai, toh Withdraw button ki jagah Paid badge show hoga
                                isPaid
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text(
                                        "Paid",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                )
                                    : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isUnlocked ? Colors.green : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: isUnlocked ? () => _processItemWithdrawal(context, amount) : null,
                                  icon: Icon(isUnlocked ? Icons.account_balance_wallet : Icons.lock, size: 14),
                                  label: Text(
                                    isUnlocked ? "Withdraw" : "Locked",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
            ],
          );
        },
      ),
    );
  }
}

class ScholarPaymentDetailsScreen extends StatelessWidget {
  final String scholarId;
  final List<Map<String, dynamic>> paidQuestions;
  final bool isDark;

  const ScholarPaymentDetailsScreen({
    super.key,
    required this.scholarId,
    required this.paidQuestions,
    required this.isDark,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Payment Receipt & Transaction Proof"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: paidQuestions.isEmpty
          ? const Center(
        child: Text(
          "Abhi tak koi payment record mojood nahi hai.",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paidQuestions.length,
        itemBuilder: (context, index) {
          var item = paidQuestions[index];

          String transactionId = item['transactionId'] ?? 'TRX-Pending / Not Provided';
          String imageUrl = item['paymentScreenshot'] ?? item['screenshot'] ?? item['receiptUrl'] ?? item['paymentProofUrl'] ?? '';

          double amount = double.tryParse(item['paidAmount']?.toString() ?? item['scholarShare']?.toString() ?? '0') ?? 0;
          bool isPaid = item['isPaidToScholar'] ?? false;

          Timestamp? paidTimestamp = item['paidAt'] as Timestamp? ?? item['answeredAt'] as Timestamp?;
          String formattedDayTime = "N/A";
          if (paidTimestamp != null) {
            DateTime dateTime = paidTimestamp.toDate();
            formattedDayTime = DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(dateTime);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      if (imageUrl.isNotEmpty) {
                        _showImageDialog(context, imageUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Koi screenshot attach nahi hai.")),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isPaid ? Colors.green : Colors.orange).withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isPaid ? Colors.green : Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(isPaid ? Icons.check_circle : Icons.hourglass_top, size: 12, color: isPaid ? Colors.green : Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                isPaid ? "Payment Transferred (Click for Pic)" : "Pending Transfer",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.orange),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "RS ${amount.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.numbers, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Transaction ID / Receipt Number:", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 1),
                            SelectableText(
                              transactionId,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : const Color(0xFF004D40)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time_filled, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Payment Day & Time:", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 1),
                          Text(
                            formattedDayTime,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}