import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ScholarPaymentsScreen extends StatefulWidget {
  final String scholarId;
  final String scholarName;

  const ScholarPaymentsScreen({super.key, required this.scholarId, this.scholarName = "Scholar"});

  @override
  State<ScholarPaymentsScreen> createState() => _ScholarPaymentsScreenState();
}

class _ScholarPaymentsScreenState extends State<ScholarPaymentsScreen> {

  void _processItemWithdrawal(BuildContext context, String docId, double amount, String scholarName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
        title: Text("Confirm Subscription Payout", style: TextStyle(color: isDark ? Colors.white : AppTheme.primaryLight)),
        content: Text("Do you want to request withdrawal for Rs. ${amount.toStringAsFixed(0)}?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                await FirebaseFirestore.instance
                    .collection('user_questions')
                    .doc(docId)
                    .update({'status': 'processing'});

                await FirebaseFirestore.instance.collection('notifications').add({
                  'targetRole': 'admin',
                  'title': 'Subscription Withdrawal Request',
                  'message': 'Scholar requested a withdrawal of Rs. ${amount.toStringAsFixed(0)}.',
                  'createdAt': FieldValue.serverTimestamp(),
                  'isRead': false,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Withdrawal request sent to Admin successfully!"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text("Confirm", style: TextStyle(color: isDark ? AppTheme.primaryDark : Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context, String recordId, double amount) {
    final TextEditingController issueController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
          title: Text(
            "Report Payment Issue",
            style: TextStyle(color: isDark ? Colors.white : AppTheme.primaryLight, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Amount: RS ${amount.toStringAsFixed(0)}",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: issueController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Explain the issue (e.g., wrong ID, less amount, screenshot unclear)...",
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              onPressed: () async {
                String issueText = issueController.text.trim();
                if (issueText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please write your issue description.")),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('admin_complaints').add({
                  'scholarId': widget.scholarId,
                  'scholarName': widget.scholarName,
                  'recordId': recordId,
                  'amount': amount,
                  'issueMessage': issueText,
                  'status': 'pending',
                  'isViewed': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Issue reported to admin successfully!")),
                );
              },
              child: const Text("Submit Issue", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withAlpha(230),
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text("Failed to load full image.", style: TextStyle(color: Colors.white)),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
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

  void _showSingleReceiptPopup(BuildContext context, String docId, Map<String, dynamic> data, bool isDark) {
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
        backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Subscription Receipt & Proof", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryLight)),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.black54),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Amount: RS ${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : Colors.green, fontSize: 15)),
                const SizedBox(height: 8),
                Text("Transaction ID: $transactionId", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight)),
                const SizedBox(height: 4),
                Text("Date & Time: $formattedDayTime", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Payment Screenshot Proof:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    if (imageUrl.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _showFullImageDialog(context, imageUrl),
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: const Text("View Full Screen", style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                imageUrl.isNotEmpty
                    ? InkWell(
                  onTap: () => _showFullImageDialog(context, imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 320),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(10),
                        border: Border.all(color: Colors.grey.withAlpha(50)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Failed to load image.", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("No screenshot attached.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showReportIssueDialog(context, docId, amount);
                    },
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: const Text("Report Issue", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Scholar Earnings & Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_complaints')
                .where('scholarId', isEqualTo: widget.scholarId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
                    tooltip: "My Reports & Complaints",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScholarMyComplaintsScreen(
                            scholarId: widget.scholarId,
                            isDark: isDark,
                          ),
                        ),
                      );
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('scholarId', isEqualTo: widget.scholarId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No subscription earnings found.",
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.grey),
              ),
            );
          }

          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String status = (data['status'] ?? 'answered').toString().toLowerCase();
            return status == 'answered' || status == 'processing' || status == 'paid';
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No earnings history found.",
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.grey),
              ),
            );
          }

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
                  gradient: LinearGradient(
                    colors: isDark ? [AppTheme.primaryLight, AppTheme.primaryDark] : [AppTheme.primaryLight, const Color(0xFF00695C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Total Consultation Earnings",
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
                        backgroundColor: isDark ? AppTheme.accentGreen : Colors.white,
                        foregroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
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
                        "Check History",
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
                    String docId = docs[index].id;
                    double amount = double.tryParse(data['scholarShare']?.toString() ?? '50') ?? 50.0;
                    String userId = data['userId'] ?? 'unknown_user';
                    String itemStatus = (data['status'] ?? 'answered').toString().toLowerCase();

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
                          if (fetchedName != null && fetchedName.isNotEmpty) {
                            displayName = fetchedName;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 14, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['questionText'] ?? "Subscription Inquiry",
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
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            "Rs. ${amount.toStringAsFixed(0)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                                            ),
                                          ),
                                          if (isPaid) ...[
                                            const SizedBox(width: 10),
                                            InkWell(
                                              onTap: () => _showSingleReceiptPopup(context, docId, data, isDark),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isDark ? AppTheme.accentGreen.withAlpha(20) : Colors.green.withAlpha(38),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: isDark ? AppTheme.accentGreen : Colors.green),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.receipt, size: 12, color: isDark ? AppTheme.accentGreen : Colors.green),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      transactionId.isNotEmpty ? "ID: $transactionId" : "Transfered",
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : Colors.green),
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
                                isPaid
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.accentGreen.withAlpha(20) : Colors.green.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? AppTheme.accentGreen : Colors.green),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 14, color: isDark ? AppTheme.accentGreen : Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Paid",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : Colors.green),
                                      ),
                                    ],
                                  ),
                                )
                                    : itemStatus == 'processing'
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(38),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: const Text(
                                    "Processing",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                )
                                    : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isUnlocked ? AppTheme.accentGreen : Colors.grey.shade400,
                                    foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: isUnlocked ? () => _processItemWithdrawal(context, docId, amount, displayName) : null,
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

// =============================================================================
// ScholarMyComplaintsScreen (With Full Screen Screenshot Preview)
// =============================================================================
class ScholarMyComplaintsScreen extends StatelessWidget {
  final String scholarId;
  final bool isDark;

  const ScholarMyComplaintsScreen({super.key, required this.scholarId, required this.isDark});

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withAlpha(230),
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text("Failed to load full image.", style: TextStyle(color: Colors.white)),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
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

  void _showComplaintDetailsDialog(BuildContext context, Map<String, dynamic> complaintData, String recordId) {
    String issue = complaintData['issueMessage'] ?? 'N/A';
    String status = complaintData['status'] ?? 'pending';
    double amount = double.tryParse(complaintData['amount']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Complaint Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.primaryLight)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Amount: Rs. ${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppTheme.accentGreen : Colors.green)),
                  const SizedBox(height: 8),
                  Text("Your Issue: $issue", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 8),
                  Text("Status: ${status.toUpperCase()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: status == 'resolved' ? Colors.green : Colors.orange)),
                  const Divider(height: 20),
                  const Text("Admin Resolution & Updated Proof:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 10),

                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('user_questions').doc(recordId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text("Loading admin updates...", style: TextStyle(color: Colors.grey, fontSize: 12));
                      }

                      var qData = snapshot.data!.data() as Map<String, dynamic>;
                      String adminTid = qData['adminTransactionId'] ?? qData['transactionId'] ?? 'N/A';
                      String adminScreenshot = qData['adminPaymentScreenshot'] ?? qData['paymentScreenshot'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.withAlpha(50)),
                            ),
                            child: Text("Updated Transaction ID: $adminTid", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                          ),
                          const SizedBox(height: 12),
                          if (adminScreenshot.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Updated Payment Screenshot:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                TextButton.icon(
                                  onPressed: () => _showFullImageDialog(context, adminScreenshot),
                                  icon: const Icon(Icons.fullscreen, size: 16),
                                  label: const Text("View Full Screen", style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _showFullImageDialog(context, adminScreenshot),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.withAlpha(50)), borderRadius: BorderRadius.circular(8)),
                                  child: Image.network(adminScreenshot, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ] else
                            const Text("No new screenshot provided by admin.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Reports & Complaints", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_complaints')
            .where('scholarId', isEqualTo: scholarId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No reports or complaints found.",
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.grey),
              ),
            );
          }

          var docs = snapshot.data!.docs.toList();

          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['createdAt'] as Timestamp?;
            Timestamp? timeB = dataB['createdAt'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              String recordId = data['recordId'] ?? '';

              double amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
              String issueMessage = data['issueMessage'] ?? 'No message';
              String status = (data['status'] ?? 'pending').toString().toLowerCase();
              bool isViewed = data['isViewed'] ?? false;

              Timestamp? timestamp = data['createdAt'] as Timestamp?;
              String formattedDate = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                  : 'N/A';

              Color statusColor = Colors.orange;
              String statusText = "PENDING";

              if (status == 'resolved') {
                if (!isViewed) {
                  statusColor = Colors.red;
                  statusText = "RESOLVED (NEW)";
                } else {
                  statusColor = Colors.green;
                  statusText = "RESOLVED";
                }
              }

              return InkWell(
                onTap: () async {
                  if (status == 'resolved' && !isViewed) {
                    await FirebaseFirestore.instance
                        .collection('admin_complaints')
                        .doc(docId)
                        .update({'isViewed': true});
                  }
                  _showComplaintDetailsDialog(context, data, recordId);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Amount: Rs. ${amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppTheme.primaryLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Issue: $issueMessage",
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Date: $formattedDate",
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
                      ),
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

// =============================================================================
// ScholarPaymentDetailsScreen (Cashout History Screen)
// =============================================================================
class ScholarPaymentDetailsScreen extends StatelessWidget {
  final String scholarId;
  final List<Map<String, dynamic>> paidQuestions;
  get isDark => null;

  const ScholarPaymentDetailsScreen({
    super.key,
    required this.scholarId,
    required this.paidQuestions,
    required bool isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Cashout History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: paidQuestions.isEmpty
          ? Center(
        child: Text(
          "No cashout history available.",
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paidQuestions.length,
        itemBuilder: (context, index) {
          var q = paidQuestions[index];
          double amount = double.tryParse(q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '50') ?? 50.0;
          String questionText = q['questionText'] ?? q['question'] ?? 'Subscription Inquiry';
          String transactionId = q['transactionId'] ?? 'N/A';
          bool isPaid = q['isPaidToScholar'] ?? false;

          Timestamp? t = q['paidAt'] as Timestamp? ?? q['answeredAt'] as Timestamp?;
          String dateStr = t != null ? DateFormat('dd MMM yyyy, hh:mm a').format(t.toDate()) : 'N/A';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rs. ${amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPaid ? "PAID" : "UNPAID",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  questionText,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Transaction ID: $transactionId",
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[700], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Date: $dateStr",
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}