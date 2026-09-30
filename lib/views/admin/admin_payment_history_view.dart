import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentHistoryView extends StatelessWidget {
  const AdminPaymentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2, // Do tabs: Verified History aur Rejected History
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
        appBar: AppBar(
          title: const Text('Payment History & Records', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF004D40),
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Verified History", icon: Icon(Icons.check_circle_outline)),
              Tab(text: "Rejected History", icon: Icon(Icons.cancel_outlined)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear payment records",
              onPressed: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Clear Payment History"),
                    content: const Text("Are you sure you want to delete these payment records? This action cannot be undone."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete All", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    // Yahan current active tab ke mutabiq delete kar sakte hain ya sabhi sent_to_scholar
                    final querySnapshot = await FirebaseFirestore.instance
                        .collection('user_questions')
                        .where('status', isEqualTo: 'sent_to_scholar')
                        .get();

                    final batch = FirebaseFirestore.instance.batch();
                    for (var doc in querySnapshot.docs) {
                      batch.delete(doc.reference);
                    }
                    await batch.commit();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Verified payment history cleared successfully.")),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error clearing payment history: $e");
                  }
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Verified History List
            _buildHistoryList(statusFilter: 'sent_to_scholar', isDark: isDark),

            // Tab 2: Rejected History List
            _buildHistoryList(statusFilter: 'rejected', isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList({required String statusFilter, required bool isDark}) {
    bool isRejectedTab = statusFilter == 'rejected';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_questions')
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isRejectedTab ? "No rejected payment history found." : "No verified payment history found yet.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          );
        }

        var docs = snapshot.data!.docs;

        docs.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          Timestamp? timeA = dataA['verifiedAt'] ?? dataA['createdAt'];
          Timestamp? timeB = dataB['verifiedAt'] ?? dataB['createdAt'];
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            String userName = data['userName'] ?? data['name'] ?? 'User';
            String scholarName = data['scholarName'] ?? data['requestedScholarName'] ?? 'Scholar';
            double totalAmount = double.tryParse(data['totalAmount']?.toString() ?? data['amountPaid']?.toString() ?? '0') ?? 0.0;
            double scholarShare = double.tryParse(data['scholarShare']?.toString() ?? '0') ?? (totalAmount / 2);
            double adminShare = double.tryParse(data['adminShare']?.toString() ?? '0') ?? (totalAmount / 2);

            Timestamp? timestamp = data['verifiedAt'] ?? data['createdAt'];
            String dateStr = timestamp != null ? timestamp.toDate().toString().split('.').first : 'N/A';

            String userQuestion = data['questionText'] ?? data['question'] ?? 'No Question text.';
            String aiResponse = data['aiAnswer'] ?? data['aiResponse'] ?? data['response'] ?? '';
            String optionalText = (data['userRemarks'] ?? data['optionalNote'] ?? data['userFeedback'] ?? data['feedback'] ?? data['additionalNote'] ?? '').toString().trim();
            String transactionId = data['transactionId'] ?? data['tid'] ?? 'N/A';
            String? rejectionReason = data['rejectionReason'];
            bool isResubmitted = data['isResubmitted'] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: isRejectedTab ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.15)),
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isRejectedTab ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  child: Icon(
                    isRejectedTab ? Icons.cancel : Icons.verified,
                    color: isRejectedTab ? Colors.red : Colors.green,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (isResubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Re-submitted 🔄",
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Text(
                        isRejectedTab ? "Status: Rejected" : "Scholar: $scholarName",
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Total: RS $totalAmount",
                        style: TextStyle(color: isRejectedTab ? Colors.red.shade700 : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: "Delete Record",
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('user_questions')
                              .doc(docId)
                              .delete();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Record deleted successfully"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("Error deleting record: $e");
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "TID: $transactionId",
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                            Text(isRejectedTab ? "Rejected On: $dateStr" : "Verified On: $dateStr", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (isRejectedTab && rejectionReason != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Text(
                              "Rejection Reason: $rejectionReason",
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else if (!isRejectedTab) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Scholar Share (50%): RS $scholarShare", style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Admin Share (50%): RS $adminShare", style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Divider(height: 24),
                        const Text("  Question:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(userQuestion, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87, height: 1.4)),
                        const SizedBox(height: 16),
                        if (aiResponse.isNotEmpty) ...[
                          _buildResponseBox(title: "AI Response :", message: aiResponse, icon: Icons.auto_awesome, themeColor: Colors.blue, isDark: isDark),
                          const SizedBox(height: 16),
                        ],
                        if (optionalText.isNotEmpty && optionalText != 'null') ...[
                          _buildResponseBox(title: "User's Additional Note / Remarks:", message: optionalText, icon: Icons.rate_review_outlined, themeColor: Colors.purple, isDark: isDark),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.receipt_long_outlined, size: 18),
                            label: const Text("Check Payment Receipt"),
                            onPressed: () => _showPaymentReceiptBottomSheet(context, data),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResponseBox({required String title, required String message, required IconData icon, required Color themeColor, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: themeColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  void _showPaymentReceiptBottomSheet(BuildContext context, Map<String, dynamic> data) {
    String? screenshotUrl = data['paymentProofUrl'] ?? data['paymentScreenshot'] ?? data['screenshot'] ?? data['screenshotUrl'];
    String amountPaid = data['amountPaid']?.toString() ?? data['totalAmount']?.toString() ?? '100';
    final double screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        margin: EdgeInsets.only(top: screenHeight * 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Payment Receipt", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text("Amount: RS $amountPaid", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: (screenshotUrl != null && screenshotUrl.isNotEmpty)
                      ? Image.network(
                    screenshotUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(child: Text("Error loading image")),
                  )
                      : const Center(child: Text("No screenshot attached.")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}