import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_payment_history_view.dart';

class QueriesPaymentsView extends StatefulWidget {
  const QueriesPaymentsView({super.key});

  @override
  State<QueriesPaymentsView> createState() => _QueriesPaymentsViewState();
}

class _QueriesPaymentsViewState extends State<QueriesPaymentsView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Incoming Queries & Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, size: 24),
            tooltip: "Clear all pending queries",
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear Pending Queries"),
                  content: const Text("Are you sure you want to delete all pending verification queries? This action cannot be undone."),
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
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('user_questions')
                      .where('status', isEqualTo: 'pending_verification')
                      .get();

                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in querySnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pending queries cleared successfully.")),
                    );
                  }
                } catch (e) {
                  debugPrint("Error clearing pending queries: $e");
                }
              }
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.payments_rounded, size: 26),
            tooltip: "Payment History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPaymentHistoryView(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('status', isEqualTo: 'pending_verification')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Alhamdulillah! No pending queries to verify right now.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['createdAt'] ?? dataA['timestamp'];
            Timestamp? timeB = dataB['createdAt'] ?? dataB['timestamp'];
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktopOrWeb = constraints.maxWidth > 768;
              double horizontalPadding = isDesktopOrWeb ? 32.0 : 16.0;

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      String questionId = doc.id;

                      String userQuestion = data['questionText'] ?? data['question'] ?? 'No Question text.';
                      String aiResponse = data['aiAnswer'] ?? data['aiResponse'] ?? data['response'] ?? '';
                      String optionalText = (data['userRemarks'] ?? data['optionalNote'] ?? data['userFeedback'] ?? data['feedback'] ?? data['additionalNote'] ?? '').toString().trim();
                      String transactionId = data['transactionId'] ?? data['tid'] ?? 'N/A';

                      Timestamp? timestamp = data['createdAt'] ?? data['timestamp'];
                      String dateStr = timestamp != null
                          ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} at ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                          : 'Recent';

                      String? scholarId = data['scholarId'] ?? data['assignedScholarId'];
                      String? userId = data['userId'];

                      String amountPaid = data['amountPaid']?.toString() ?? data['feeAmount']?.toString() ?? '100';

                      return FutureBuilder<DocumentSnapshot>(
                        future: userId != null ? FirebaseFirestore.instance.collection('users').doc(userId).get() : Future.value(null),
                        builder: (context, userSnapshot) {
                          String userName = "User";
                          if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                            var uData = userSnapshot.data!.data() as Map<String, dynamic>?;
                            userName = uData?['displayName'] ?? uData?['name'] ?? uData?['fullName'] ?? data['userName'] ?? 'User';
                          } else if (data['userName'] != null) {
                            userName = data['userName'];
                          }

                          return FutureBuilder<DocumentSnapshot>(
                            future: scholarId != null ? FirebaseFirestore.instance.collection('users').doc(scholarId).get() : Future.value(null),
                            builder: (context, scholarSnapshot) {
                              String requestedScholarName = "Assigned Scholar";
                              if (scholarSnapshot.hasData && scholarSnapshot.data != null && scholarSnapshot.data!.exists) {
                                var sData = scholarSnapshot.data!.data() as Map<String, dynamic>?;
                                requestedScholarName = sData?['displayName'] ?? sData?['name'] ?? sData?['fullName'] ?? data['scholarName'] ?? 'Assigned Scholar';
                              } else if (data['scholarName'] != null) {
                                requestedScholarName = data['scholarName'];
                              }

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
                                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                                ),
                                child: ExpansionTile(
                                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                                  collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF004D40).withOpacity(0.1),
                                    child: const Icon(Icons.person, color: Color(0xFF004D40)),
                                  ),
                                  title: Text(
                                    userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "New Question",
                                            style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          "Paid: RS $amountPaid",
                                          style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          "• $dateStr",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        tooltip: "Delete Query",
                                        onPressed: () async {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('user_questions')
                                                .doc(questionId)
                                                .delete();

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Query deleted successfully"),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint("Error deleting query: $e");
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(isDesktopOrWeb ? 24.0 : 16.0),
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
                                              Text("Sent At: $dateStr", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          const Text(" Question:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text(userQuestion, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87, height: 1.4, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 16),
                                          if (aiResponse.isNotEmpty) ...[
                                            ResponseDisplayBox(title: "AI Response :", message: aiResponse, icon: Icons.auto_awesome, themeColor: Colors.blue, isDark: isDark),
                                            const SizedBox(height: 16),
                                          ],
                                          if (optionalText.isNotEmpty && optionalText != 'null') ...[
                                            ResponseDisplayBox(title: "User's Optional Note :", message: optionalText, icon: Icons.rate_review_outlined, themeColor: Colors.purple, isDark: isDark),
                                            const SizedBox(height: 16),
                                          ],
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(color: const Color(0xFF004D40).withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF004D40).withOpacity(0.15))),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person_pin_rounded, color: Color(0xFF004D40), size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                                                      children: [
                                                        const TextSpan(text: "Target Scholar Requested by User: "),
                                                        TextSpan(text: requestedScholarName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(height: 32),
                                          _buildResponsiveActionControls(
                                              isDesktopOrWeb: isDesktopOrWeb,
                                              questionId: questionId,
                                              scholarId: scholarId,
                                              scholarName: requestedScholarName,
                                              data: data
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
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResponsiveActionControls({required bool isDesktopOrWeb, required String questionId, required String? scholarId, required String scholarName, required Map<String, dynamic> data}) {
    Widget checkPaymentBtn = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: const Icon(Icons.receipt_long_outlined, size: 18),
      label: const Text("Check Receipt"),
      onPressed: () => _showPaymentReceiptBottomSheet(context, data),
    );

    Widget rejectBtn = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: const Text("Reject Payment"),
      onPressed: () => _showRejectReasonDialog(context, questionId, data),
    );

    // Yehan "Verify & Forward" ki jagah ya sath admin payment popup open karne ka flow attach kar diya hai
    Widget verifyAndForwardBtn = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: const Icon(Icons.send_rounded, size: 18),
      label: const Text("Pay to Scholar & Forward"),
      onPressed: () => _showAdminPaymentDialog(context, questionId, scholarId, scholarName, data),
    );

    if (isDesktopOrWeb) {
      return Row(children: [
        checkPaymentBtn,
        const SizedBox(width: 12),
        rejectBtn,
        const Spacer(),
        verifyAndForwardBtn,
      ]);
    } else {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          children: [
            Expanded(child: checkPaymentBtn),
            const SizedBox(width: 8),
            Expanded(child: rejectBtn),
          ],
        ),
        const SizedBox(height: 12),
        verifyAndForwardBtn,
      ]);
    }
  }

  // --- Admin Payment & Screenshot Upload Dialog ---
  void _showAdminPaymentDialog(BuildContext context, String questionId, String? scholarId, String scholarName, Map<String, dynamic> data) {
    String shareText = data['amountPaid']?.toString() ?? data['feeAmount']?.toString() ?? '100';
    final TextEditingController adminTidController = TextEditingController();
    String? adminScreenshotUrl;
    bool isUploading = false;

    // Cloudinary credentials (jese aapki baqi screens mein hain)
    const String cloudName = "lxuuhill";
    const String uploadPreset = "AppPresent";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {

            // Image picker for admin payment proof to scholar
            Future<void> pickAndUploadAdminProof() async {
              final ImagePicker picker = ImagePicker();
              final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

              if (pickedFile != null) {
                setStateModal(() => isUploading = true);
                try {
                  var bytes = await pickedFile.readAsBytes();
                  var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

                  var request = http.MultipartRequest("POST", uri)
                    ..fields['upload_preset'] = uploadPreset
                    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name));

                  var streamedResponse = await request.send();
                  var response = await http.Response.fromStream(streamedResponse);

                  if (response.statusCode == 200) {
                    var jsonData = json.decode(response.body);
                    setStateModal(() {
                      adminScreenshotUrl = jsonData['secure_url'];
                      isUploading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Screenshot uploaded successfully!')));
                  } else {
                    setStateModal(() => isUploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
                  }
                } catch (e) {
                  setStateModal(() => isUploading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Pay to Scholar", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Question & Answer Preview
                      Text("Question:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12)),
                      Text(data['questionText'] ?? data['question'] ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),

                      // Automatic Amount Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004D40).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Amount to Send:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("RS $shareText", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Transaction ID Input
                      const Text("Enter Transaction ID / Account Number:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: adminTidController,
                        decoration: InputDecoration(
                          hintText: "Enter ID Number (TID)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Screenshot Upload
                      const Text("Payment Proof Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      if (adminScreenshotUrl != null && adminScreenshotUrl!.isNotEmpty)
                        Container(
                          height: 130,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(adminScreenshotUrl!, fit: BoxFit.cover),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : pickAndUploadAdminProof,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(adminScreenshotUrl == null ? "Attach Screenshot" : "Change Screenshot"),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                      ),
                      if (isUploading) ...[
                        const SizedBox(height: 10),
                        const Center(child: CircularProgressIndicator(color: Color(0xFF004D40))),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
                  onPressed: isUploading ? null : () async {
                    if (adminTidController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter transaction ID number.')));
                      return;
                    }
                    if (adminScreenshotUrl == null || adminScreenshotUrl!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please attach payment screenshot.')));
                      return;
                    }

                    Navigator.pop(context);

                    // Process verification and forward with payment details attached for scholar
                    await _processVerificationDirectlyWithPayment(
                      questionId: questionId,
                      scholarId: scholarId,
                      scholarName: scholarName,
                      data: data,
                      adminTid: adminTidController.text.trim(),
                      adminScreenshot: adminScreenshotUrl!,
                    );
                  },
                  child: const Text("Send to Scholar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processVerificationDirectlyWithPayment({
    required String questionId,
    required String? scholarId,
    required String scholarName,
    required Map<String, dynamic> data,
    required String adminTid,
    required String adminScreenshot,
  }) async {
    double totalPaid = double.tryParse(data['amountPaid']?.toString() ?? data['feeAmount']?.toString() ?? '100') ?? 100.0;
    double adminShare = totalPaid / 2;
    double scholarShare = totalPaid / 2;

    // Firestore update: status 'sent_to_scholar' ya 'paid' sath mein admin ka TID aur screenshot save ho jayega
    await FirebaseFirestore.instance.collection('user_questions').doc(questionId).update({
      'status': 'sent_to_scholar',
      'verifiedAt': FieldValue.serverTimestamp(),
      'totalAmount': totalPaid,
      'adminShare': adminShare,
      'scholarShare': scholarShare,
      'adminTransactionId': adminTid,
      'adminPaymentScreenshot': adminScreenshot,
    });

    if (scholarId != null && scholarId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('scholar_earnings_ledger').add({
        'scholarId': scholarId,
        'scholarName': scholarName,
        'questionId': questionId,
        'amount': scholarShare,
        'adminTransactionId': adminTid,
        'adminPaymentScreenshot': adminScreenshot,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'accumulated',
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'scholarId': scholarId,
        'questionId': questionId,
        'targetRole': 'scholar',
        'title': 'New Question & Payment Received! 📩',
        'message': 'You have received a verified question along with payment proof.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (data['userId'] != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': data['userId'],
        'questionId': questionId,
        'targetRole': 'user',
        'title': 'Payment Verified ✅',
        'message': 'Your payment has been verified and forwarded to the scholar.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment details sent to scholar successfully!"))
      );
    }
  }

  // Reject Dialog & Logic with Required Validation
  void _showRejectReasonDialog(BuildContext context, String questionId, Map<String, dynamic> data) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Reject Payment", style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Please provide a reason for rejecting this payment screenshot so the user can re-upload correctly:"),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "e.g., Invalid Transaction ID or Blurry Screenshot",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                String reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason for rejection before submitting.')),
                  );
                  return;
                }

                Navigator.pop(context);

                await FirebaseFirestore.instance.collection('user_questions').doc(questionId).update({
                  'status': 'rejected',
                  'rejectionReason': reason,
                });

                if (data['userId'] != null) {
                  await FirebaseFirestore.instance.collection('notifications').add({
                    'userId': data['userId'],
                    'questionId': questionId,
                    'targetRole': 'user',
                    'title': 'Payment Rejected ❌',
                    'message': 'Your payment proof was rejected. Reason: $reason. Please re-upload.',
                    'isRead': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment rejected and user notified successfully.")),
                  );
                }
              },
              child: const Text("Confirm Reject"),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentReceiptBottomSheet(BuildContext context, Map<String, dynamic> data) {
    String? screenshotUrl = data['paymentProofUrl'] ?? data['paymentScreenshot'] ?? data['screenshot'] ?? data['screenshotUrl'];
    String amountPaid = data['amountPaid']?.toString() ?? data['feeAmount']?.toString() ?? '100';
    final double screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
          ),
          padding: const EdgeInsets.all(24),
          margin: EdgeInsets.only(top: screenHeight * 0.15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Payment Receipt", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
            const SizedBox(height: 16),
            Text("Amount Sent by User: RS $amountPaid", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
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
          ]),
        )
    );
  }
}

class ResponseDisplayBox extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color themeColor;
  final bool isDark;
  const ResponseDisplayBox({super.key, required this.title, required this.message, required this.icon, required this.themeColor, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: themeColor.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: themeColor.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: themeColor, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 13))]), const SizedBox(height: 8), Text(message, style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4))]));
  }
}