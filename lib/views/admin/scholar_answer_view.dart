import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:admin/view_models/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class ScholarAnswerView extends StatelessWidget {
  const ScholarAnswerView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Scholar Payouts"),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt, color: Colors.teal),
            tooltip: "All Scholars Biodata",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllScholarsBiodataScreen(isDark: isDark),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user_questions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No questions are available"),
            );
          }

          var docs = snapshot.data!.docs;

          var answeredDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String scholarResp = data['scholarResponse']?.toString() ?? '';
            String answer = data['answer']?.toString() ?? '';
            return scholarResp.trim().isNotEmpty || answer.trim().isNotEmpty;
          }).toList();

          if (answeredDocs.isEmpty) {
            return const Center(
              child: Text("No answered questions found from scholars."),
            );
          }

          answeredDocs.sort((a, b) {
            Timestamp? timeA = (a.data() as Map<String, dynamic>)['answeredAt'] ?? (a.data() as Map<String, dynamic>)['createdAt'];
            Timestamp? timeB = (b.data() as Map<String, dynamic>)['answeredAt'] ?? (b.data() as Map<String, dynamic>)['createdAt'];
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          Map<String, List<Map<String, dynamic>>> scholarGroups = {};
          Map<String, String> scholarNamesMap = {};
          Map<String, String> scholarIdsMap = {};

          for (var doc in answeredDocs) {
            var data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;

            String scholarName = data['scholarName'] ?? data['name'] ?? data['userName'] ?? 'Unknown Scholar';
            String scholarId = data['scholarId'] ?? data['uid'] ?? '';

            String groupKey = scholarId.isNotEmpty ? scholarId : scholarName.trim().toLowerCase();

            if (!scholarGroups.containsKey(groupKey)) {
              scholarGroups[groupKey] = [];
            }
            scholarGroups[groupKey]!.add(data);
            scholarNamesMap[groupKey] = scholarName;
            scholarIdsMap[groupKey] = scholarId;
          }

          var scholarKeys = scholarGroups.keys.toList();

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('scholars').where('status', isEqualTo: 'approved').get(),
            builder: (context, appSnapshot) {
              Map<String, Map<String, dynamic>> scholarDataMapByUid = {};
              Map<String, Map<String, dynamic>> scholarDataMapByName = {};

              if (appSnapshot.hasData) {
                for (var appDoc in appSnapshot.data!.docs) {
                  var appData = appDoc.data() as Map<String, dynamic>;
                  scholarDataMapByUid[appDoc.id] = appData;

                  String uidField = appData['uid']?.toString() ?? '';
                  if (uidField.isNotEmpty) {
                    scholarDataMapByUid[uidField] = appData;
                  }

                  String name = (appData['name'] ?? appData['displayName'] ?? appData['fullName'] ?? appData['scholarName'] ?? '').toString().trim().toLowerCase();
                  if (name.isNotEmpty) {
                    scholarDataMapByName[name] = appData;
                  }
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: scholarKeys.length,
                itemBuilder: (context, index) {
                  String groupKey = scholarKeys[index];
                  var questionsList = scholarGroups[groupKey]!;
                  String scholarName = scholarNamesMap[groupKey] ?? 'Unknown Scholar';
                  String scholarId = scholarIdsMap[groupKey] ?? '';

                  double totalWeeklyAmount = 0;
                  for (var q in questionsList) {
                    bool isPaid = q['isPaidToScholar'] ?? false;
                    if (!isPaid) {
                      double share = double.tryParse(q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0') ?? 0;
                      totalWeeklyAmount += share;
                    }
                  }

                  Map<String, dynamic>? matchedAppData;
                  if (scholarId.isNotEmpty && scholarDataMapByUid.containsKey(scholarId)) {
                    matchedAppData = scholarDataMapByUid[scholarId];
                  } else if (scholarDataMapByName.containsKey(scholarName.trim().toLowerCase())) {
                    matchedAppData = scholarDataMapByName[scholarName.trim().toLowerCase()];
                  }

                  if (matchedAppData != null) {
                    scholarName = matchedAppData['name'] ??
                        matchedAppData['displayName'] ??
                        matchedAppData['scholarName'] ??
                        scholarName;
                  }

                  String scholarPhone = "Number not available";
                  if (matchedAppData != null) {
                    scholarPhone = matchedAppData['phone'] ??
                        matchedAppData['accountNumber'] ??
                        matchedAppData['jazzcash'] ??
                        matchedAppData['easypaisa'] ??
                        matchedAppData['bankAccount'] ??
                        "Number not available";
                  } else {
                    for (var q in questionsList) {
                      scholarPhone = q['scholarPhone'] ??
                          q['phoneNumber'] ??
                          q['accountNumber'] ??
                          q['jazzcash'] ??
                          q['easypaisa'] ??
                          q['phone'] ??
                          "Number not available";
                      if (scholarPhone != "Number not available") break;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scholarName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.tealAccent : const Color(0xFF004D40),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Account / Phone: $scholarPhone",
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: totalWeeklyAmount > 0 ? Colors.red.withAlpha(40) : Colors.green.withAlpha(40),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: totalWeeklyAmount > 0 ? Colors.red : Colors.green, width: 1.5),
                                ),
                                child: Text(
                                  "RS ${totalWeeklyAmount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: totalWeeklyAmount > 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Answer Record: ${questionsList.length}",
                                style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScholarWithdrawalFullScreen(
                                        scholarName: scholarName,
                                        scholarId: scholarId,
                                        scholarPhone: scholarPhone,
                                        questionsList: questionsList,
                                        isDark: isDark,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text("View Full Details", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ALL SCHOLARS BIODATA SCREEN (NAME, EMAIL, PHONE)
// -----------------------------------------------------------------------------
class AllScholarsBiodataScreen extends StatelessWidget {
  final bool isDark;

  const AllScholarsBiodataScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text("All Scholars Biodata"),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scholars').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No scholars biodata found."),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              String name = data['name'] ?? data['displayName'] ?? data['fullName'] ?? data['scholarName'] ?? 'No Name';
              String email = data['email'] ?? 'No Email';
              String phone = data['phone'] ??
                  data['phoneNumber'] ??
                  data['accountNumber'] ??
                  data['jazzcash'] ??
                  data['easypaisa'] ??
                  'No Phone Number';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.tealAccent : const Color(0xFF004D40),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            phone,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                        ],
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

// -----------------------------------------------------------------------------
// Helper Function: Full Screen Image Preview Dialog
// -----------------------------------------------------------------------------
void _showFullScreenImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black.withOpacity(0.9),
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text("Failed to load image", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// ScholarWithdrawalFullScreen
// -----------------------------------------------------------------------------
class ScholarWithdrawalFullScreen extends StatelessWidget {
  final String scholarName;
  final String scholarId;
  final String scholarPhone;
  final List<Map<String, dynamic>> questionsList;
  final bool isDark;

  const ScholarWithdrawalFullScreen({
    super.key,
    required this.scholarName,
    required this.scholarId,
    required this.scholarPhone,
    required this.questionsList,
    required this.isDark,
  });

  String _getRemainingDaysText(Timestamp? answeredAt) {
    if (answeredAt == null) return "7 Days Left";
    DateTime answerDate = answeredAt.toDate();
    DateTime eligibleDate = answerDate.add(const Duration(days: 7));
    int daysLeft = eligibleDate.difference(DateTime.now()).inDays;

    if (daysLeft > 0) {
      return "$daysLeft ${daysLeft == 1 ? 'Day' : 'Days'} Left";
    } else {
      return "Ready to Pay";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text("$scholarName - Details"),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questionsList.length,
        itemBuilder: (context, index) {
          var q = questionsList[index];
          String questionText = q['question'] ?? q['questionText'] ?? 'No Question';
          String answerText = q['answer'] ?? q['scholarResponse'] ?? 'No Answer';
          bool isPaid = q['isPaidToScholar'] ?? false;
          double share = double.tryParse(q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0') ?? 0;
          String recordId = q['docId'] ?? '';
          Timestamp? answeredAt = q['answeredAt'] ?? q['createdAt'];

          String daysLeftText = _getRemainingDaysText(answeredAt);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Share: RS ${share.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.orange,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          if (!isPaid) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.withAlpha(100)),
                              ),
                              child: Text(
                                daysLeftText,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showPayScholarDialog(context, recordId, share),
                              icon: const Icon(Icons.payment, size: 14),
                              label: const Text("Pay Scholar", style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Chip(
                            label: Text(isPaid ? "Paid" : "Unpaid"),
                            backgroundColor: isPaid ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
                            labelStyle: TextStyle(
                              color: isPaid ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text("Question:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(questionText, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  const Text("Answer:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(answerText, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPaid) ...[
                        OutlinedButton.icon(
                          onPressed: () => _showPaidDetailsDialog(context, q),
                          icon: const Icon(Icons.receipt, size: 16),
                          label: const Text("View Proof"),
                        ),
                        const SizedBox(width: 8),
                      ],
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('admin_complaints')
                            .where('recordId', isEqualTo: recordId)
                            .snapshots(),
                        builder: (context, complaintSnapshot) {
                          if (!complaintSnapshot.hasData || complaintSnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          var complaints = complaintSnapshot.data!.docs;
                          bool hasPending = false;
                          bool hasResolved = false;

                          for (var doc in complaints) {
                            var data = doc.data() as Map<String, dynamic>;
                            String status = (data['status'] ?? '').toString().toLowerCase();
                            if (status == 'resolved') {
                              hasResolved = true;
                            } else {
                              hasPending = true;
                            }
                          }

                          if (hasPending) {
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showAdminComplaintsDialog(context, recordId, q),
                              icon: const Icon(Icons.warning, size: 16),
                              label: const Text("Complaints"),
                            );
                          }

                          if (hasResolved) {
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showAdminComplaintsDialog(context, recordId, q),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text("Resolved"),
                            );
                          }

                          return const SizedBox.shrink();
                        },
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

  void _showPayScholarDialog(BuildContext context, String recordId, double amount) {
    final TextEditingController tidController = TextEditingController();
    String? paymentScreenshotUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text("Pay RS ${amount.toStringAsFixed(0)} to Scholar", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Enter Transaction ID (TID) or Account Ref:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: tidController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "e.g., TID123456789",
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("Upload Payment Proof Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      paymentScreenshotUrl != null
                          ? GestureDetector(
                        onTap: () => _showFullScreenImage(context, paymentScreenshotUrl!),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(paymentScreenshotUrl!, fit: BoxFit.cover),
                          ),
                        ),
                      )
                          : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                        onPressed: isUploading
                            ? null
                            : () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setStateDialog(() => isUploading = true);
                            String? url = await CloudinaryService.uploadImage(pickedFile);
                            setStateDialog(() {
                              paymentScreenshotUrl = url;
                              isUploading = false;
                            });
                          }
                        },
                        icon: isUploading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file),
                        label: Text(isUploading ? "Uploading..." : "Select Screenshot"),
                      ),
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
                  onPressed: () async {
                    if (tidController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter Transaction ID (TID).")),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    // 1. Mark status as Paid in Firestore
                    await FirebaseFirestore.instance.collection('user_questions').doc(recordId).update({
                      'isPaidToScholar': true,
                      'adminTransactionId': tidController.text.trim(),
                      'adminPaymentScreenshot': paymentScreenshotUrl ?? '',
                      'paidAt': FieldValue.serverTimestamp(),
                    });

                    // 2. Send automated notification to Scholar
                    if (scholarId.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'scholarId': scholarId,
                        'recordId': recordId,
                        'targetRole': 'scholar',
                        'title': 'Payment Received! 💰',
                        'message': 'Aapko RS ${amount.toStringAsFixed(0)} ki payment transfer kar di gayi hai. TID: ${tidController.text.trim()}',
                        'isPaidNotification': true,
                        'isRead': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Payment marked as Paid and notification sent to scholar successfully!")),
                      );
                    }
                  },
                  child: const Text("Confirm Payment"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPaidDetailsDialog(BuildContext context, Map<String, dynamic> qData) {
    String tid = qData['adminTransactionId'] ?? 'N/A';
    String? screenshotUrl = qData['adminPaymentScreenshot'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Text("Payment Proof & History", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Transaction ID (TID) / Account Number:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withAlpha(50)),
                    ),
                    child: Text(tid, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Uploaded Payment Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (screenshotUrl != null && screenshotUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, screenshotUrl),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.withAlpha(100)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(screenshotUrl, fit: BoxFit.cover),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text("Click to view full", style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Text("No screenshot found.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // --- ADMIN COMPLAINTS DIALOG WITH RESOLVE BUTTON ---
  void _showAdminComplaintsDialog(BuildContext context, String recordId, Map<String, dynamic> qData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text("Scholar Complaints / Issues", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_complaints')
                  .where('recordId', isEqualTo: recordId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No complaints found for this record.");
                }

                var complaints = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    var compDoc = complaints[index];
                    var compData = compDoc.data() as Map<String, dynamic>;
                    String issueMessage = compData['issueMessage'] ?? 'No message';
                    String status = compData['status'] ?? 'pending';
                    double complaintAmount = double.tryParse(compData['amount']?.toString() ?? '0') ?? 0;
                    String sName = compData['scholarName'] ?? scholarName;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == 'resolved' ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: status == 'resolved' ? Colors.green.withAlpha(50) : Colors.orange.withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Scholar: $sName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                          const SizedBox(height: 2),
                          Text("Amount: RS ${complaintAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text("Issue: $issueMessage", style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 4),
                          Text("Status: $status", style: TextStyle(fontSize: 12, color: status == 'resolved' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: status == 'pending'
                                ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showResolveOptionsDialog(context, compDoc.id, recordId, qData);
                              },
                              icon: const Icon(Icons.build_circle, size: 16),
                              label: const Text("Resolve Issue", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                                : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showPaidDetailsDialog(context, qData);
                              },
                              icon: const Icon(Icons.check_circle, size: 14),
                              label: const Text("Resolved (View Proof)", style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // --- RESOLVE OPTIONS DIALOG (Select: TID / Screenshot / Both) ---
  void _showResolveOptionsDialog(BuildContext context, String complaintId, String recordId, Map<String, dynamic> qData) {
    String selectedOption = 'id'; // Options: 'id', 'screenshot', 'both'
    final TextEditingController updateTidController = TextEditingController(text: qData['adminTransactionId'] ?? '');
    String? updatedScreenshotUrl = qData['adminPaymentScreenshot'];
    bool isUploadingImg = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: const Text("Resolve Complaint", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Select what you want to update:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedOption,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'id', child: Text("Change Transaction ID Number")),
                          DropdownMenuItem(value: 'screenshot', child: Text("Attach/Change Screenshot")),
                          DropdownMenuItem(value: 'both', child: Text("Update Both (TID & Screenshot)")),
                        ],
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => selectedOption = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Show TID field if selected 'id' or 'both'
                      if (selectedOption == 'id' || selectedOption == 'both') ...[
                        const Text("Transaction ID (TID):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: updateTidController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Enter updated Transaction ID",
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Show Screenshot field if selected 'screenshot' or 'both'
                      if (selectedOption == 'screenshot' || selectedOption == 'both') ...[
                        const Text("Payment Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),

                        if (updatedScreenshotUrl != null && updatedScreenshotUrl!.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => _showFullScreenImage(context, updatedScreenshotUrl!),
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.teal),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(updatedScreenshotUrl!, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                            onPressed: isUploadingImg
                                ? null
                                : () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setStateDialog(() => isUploadingImg = true);
                                String? url = await CloudinaryService.uploadImage(pickedFile);
                                setStateDialog(() {
                                  updatedScreenshotUrl = url;
                                  isUploadingImg = false;
                                });
                              }
                            },
                            icon: isUploadingImg
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh, size: 16),
                            label: Text(isUploadingImg ? "Uploading..." : "Change Screenshot"),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                            onPressed: isUploadingImg
                                ? null
                                : () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setStateDialog(() => isUploadingImg = true);
                                String? url = await CloudinaryService.uploadImage(pickedFile);
                                setStateDialog(() {
                                  updatedScreenshotUrl = url;
                                  isUploadingImg = false;
                                });
                              }
                            },
                            icon: isUploadingImg
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_file),
                            label: Text(isUploadingImg ? "Uploading..." : "Select Screenshot"),
                          ),
                        ],
                      ],
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    Map<String, dynamic> recordUpdates = {};

                    if (selectedOption == 'id' || selectedOption == 'both') {
                      if (updateTidController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter Transaction ID.")),
                        );
                        return;
                      }
                      recordUpdates['adminTransactionId'] = updateTidController.text.trim();
                    }

                    if (selectedOption == 'screenshot' || selectedOption == 'both') {
                      if (updatedScreenshotUrl == null || updatedScreenshotUrl!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please upload a screenshot.")),
                        );
                        return;
                      }
                      recordUpdates['adminPaymentScreenshot'] = updatedScreenshotUrl;
                    }

                    Navigator.pop(context);

                    // 1. Update Complaint Status to Resolved
                    await FirebaseFirestore.instance.collection('admin_complaints').doc(complaintId).update({
                      'status': 'resolved',
                      'resolvedAt': FieldValue.serverTimestamp(),
                    });

                    // 2. Update Question Record details if needed
                    if (recordUpdates.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('user_questions').doc(recordId).update(recordUpdates);
                    }

                    // 3. Send Notification to Scholar
                    if (scholarId.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'scholarId': scholarId,
                        'recordId': recordId,
                        'targetRole': 'scholar',
                        'title': 'Complaint Resolved! ✅',
                        'message': 'Your payment complaint has been resolved. Please check the updated details.',
                        'isRead': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Complaint resolved and scholar notified successfully!")),
                      );
                    }
                  },
                  child: const Text("Confirm & Resolve"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}