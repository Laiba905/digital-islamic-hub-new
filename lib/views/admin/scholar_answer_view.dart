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

                  bool isWeekCompleted = false;
                  for (var q in questionsList) {
                    bool isPaid = q['isPaidToScholar'] ?? false;
                    if (!isPaid) {
                      Timestamp? t = q['answeredAt'] ?? q['createdAt'];
                      if (t != null) {
                        DateTime date = t.toDate();
                        if (DateTime.now().difference(date).inDays >= 7) {
                          isWeekCompleted = true;
                          break;
                        }
                      }
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
                                  backgroundColor: totalWeeklyAmount == 0 ? Colors.grey : (isWeekCompleted ? Colors.red : Colors.green),
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
                      // StreamBuilder to check if complaint exists and is resolved
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('admin_complaints')
                            .where('recordId', isEqualTo: recordId)
                            .snapshots(),
                        builder: (context, complaintSnapshot) {
                          bool hasResolvedComplaint = false;
                          if (complaintSnapshot.hasData && complaintSnapshot.data!.docs.isNotEmpty) {
                            for (var doc in complaintSnapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              if ((data['status'] ?? '').toString().toLowerCase() == 'resolved') {
                                hasResolvedComplaint = true;
                                break;
                              }
                            }
                          }

                          if (hasResolvedComplaint) {
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

                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showAdminComplaintsDialog(context, recordId, q),
                            icon: const Icon(Icons.warning, size: 16),
                            label: const Text("Complaints"),
                          );
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

  // Admin Complaints Dialog
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: status == 'pending'
                                ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showResolveOptionsDialog(context, compDoc.id, recordId, qData);
                              },
                              child: const Text("Resolve & Update", style: TextStyle(fontSize: 11)),
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

  // Resolve Options Dialog with 3 Options & Full Screen Image Preview
  void _showResolveOptionsDialog(BuildContext context, String complaintId, String recordId, Map<String, dynamic> qData) {
    String selectedOption = 'id';
    final TextEditingController updateTidController = TextEditingController();
    String? updatedScreenshotUrl;
    bool isUploadingImg = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> pickImageForUpdate() async {
              final ImagePicker picker = ImagePicker();
              final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

              if (pickedFile != null) {
                setStateModal(() => isUploadingImg = true);
                try {
                  dynamic uploadResult = await CloudinaryService.uploadImage(pickedFile);
                  setStateModal(() {
                    updatedScreenshotUrl = uploadResult?.toString();
                    isUploadingImg = false;
                  });
                } catch (e) {
                  setStateModal(() => isUploadingImg = false);
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: const Text("Select Update Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Choose what you want to update/correct for this payment:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedOption,
                        dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'id', child: Text("ID Number (TID)")),
                          DropdownMenuItem(value: 'screenshot', child: Text("Screenshot Attached")),
                          DropdownMenuItem(value: 'both', child: Text("Both (ID & Screenshot)")),
                        ],
                        onChanged: (val) {
                          if (val != null) setStateModal(() => selectedOption = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedOption == 'id' || selectedOption == 'both') ...[
                        const Text("Enter Correct ID Number (TID):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: updateTidController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Enter updated Transaction ID",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (selectedOption == 'screenshot' || selectedOption == 'both') ...[
                        const Text("Upload New Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        if (updatedScreenshotUrl != null && updatedScreenshotUrl!.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showFullScreenImage(context, updatedScreenshotUrl!),
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.teal),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(updatedScreenshotUrl!, fit: BoxFit.cover),
                                    const Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: isUploadingImg ? null : pickImageForUpdate,
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(updatedScreenshotUrl == null ? "Pick Screenshot" : "Change Screenshot"),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                        ),
                        if (isUploadingImg) const LinearProgressIndicator(color: Colors.teal),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    String newTid = updateTidController.text.trim();

                    if ((selectedOption == 'id' || selectedOption == 'both') && newTid.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter updated Transaction ID.')));
                      return;
                    }
                    if ((selectedOption == 'screenshot' || selectedOption == 'both') && (updatedScreenshotUrl == null || updatedScreenshotUrl!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload the new screenshot.')));
                      return;
                    }

                    Map<String, dynamic> updateData = {};
                    if (selectedOption == 'id' || selectedOption == 'both') {
                      updateData['adminTransactionId'] = newTid;
                    }
                    if (selectedOption == 'screenshot' || selectedOption == 'both') {
                      updateData['adminPaymentScreenshot'] = updatedScreenshotUrl;
                    }

                    // 1. Update user_questions record
                    await FirebaseFirestore.instance.collection('user_questions').doc(recordId).update(updateData);

                    // 2. Mark complaint as resolved
                    await FirebaseFirestore.instance.collection('admin_complaints').doc(complaintId).update({
                      'status': 'resolved',
                      'resolvedAt': FieldValue.serverTimestamp(),
                    });

                    // 3. Send Notification Strictly to Scholar
                    if (scholarId.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'scholarId': scholarId,
                        'targetRole': 'scholar', // <-- Strictly set to scholar so it won't show in admin panel
                        'title': 'Payment Issue Resolved ',
                        'message': 'The admin has resolved your issue and updated the details.',
                        'isRead': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue resolved & notification sent to scholar successfully!')));
                    }
                  },
                  child: const Text("Update & Resolve"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// AllScholarsBiodataScreen Class
// -----------------------------------------------------------------------------
class AllScholarsBiodataScreen extends StatelessWidget {
  final bool isDark;
  const AllScholarsBiodataScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        title: const Text("All Scholars Biodata"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text(
          "All Scholars Biodata Screen",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}