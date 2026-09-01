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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Scholar Weekly Payouts"),
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
                                  color: totalWeeklyAmount > 0 ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
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

class AllScholarsBiodataScreen extends StatelessWidget {
  final bool isDark;

  const AllScholarsBiodataScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Approved Scholars Biodata"),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scholars')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No approved scholars found."));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              String email = data['email'] ?? 'N/A';
              String derivedNameFromEmail = email != 'N/A' && email.contains('@') ? email.split('@')[0] : 'Unknown Name';

              String name = data['name'] ??
                  data['displayName'] ??
                  data['fullName'] ??
                  derivedNameFromEmail;

              String phone = data['phone'] ?? data['accountNumber'] ?? data['jazzcash'] ?? data['easypaisa'] ?? 'N/A';
              String paymentMethod = data['payment_method'] ?? data['paymentMethod'] ?? data['accountType'] ?? 'N/A';
              String status = data['status'] ?? 'approved';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.tealAccent : const Color(0xFF004D40),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text("Email: $email", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 4),
                      Text("Account / Phone Number: $phone", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 4),
                      Text("Payment Method: $paymentMethod", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
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

class ScholarWithdrawalFullScreen extends StatefulWidget {
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
  State<ScholarWithdrawalFullScreen> createState() => _ScholarWithdrawalFullScreenState();
}

class _ScholarWithdrawalFullScreenState extends State<ScholarWithdrawalFullScreen> {
  void _openPaymentDialog(BuildContext context, Map<String, dynamic> questionData) {
    final TextEditingController amountController = TextEditingController(
      text: questionData['scholarShare']?.toString() ?? questionData['amount']?.toString() ?? '0',
    );
    final TextEditingController trxController = TextEditingController();
    String? screenshotUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text("Pay Scholar: ${widget.scholarName}", style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Account / Phone: ${widget.scholarPhone}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter Amount (RS)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: trxController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction ID / Reference No',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() => isUploading = true);
                          try {
                            dynamic uploadResult = await CloudinaryService.uploadImage(pickedFile);
                            String? url = uploadResult?.toString();

                            setStateDialog(() {
                              screenshotUrl = url;
                              isUploading = false;
                            });
                          } catch (e) {
                            setStateDialog(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        }
                      },
                      icon: isUploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(screenshotUrl == null ? "Upload Payment Screenshot" : "Screenshot Uploaded ✅"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: isUploading
                      ? null
                      : () async {
                    String docId = questionData['docId'];
                    String amountVal = amountController.text;
                    String trxVal = trxController.text;

                    // 1. Update question payment status
                    await FirebaseFirestore.instance.collection('user_questions').doc(docId).update({
                      'isPaidToScholar': true,
                      'paidAmount': amountVal,
                      'transactionId': trxVal,
                      'paymentScreenshot': screenshotUrl ?? '',
                      'paidAt': FieldValue.serverTimestamp(),
                    });

                    // 2. Add notification with the exact title/message format that matches previous working notifications
                    await FirebaseFirestore.instance.collection('notifications').add({
                      'scholarId': widget.scholarId,
                      'scholarName': widget.scholarName,
                      'targetRole': 'scholar',
                      'title': 'New Earning Added! 💰',
                      'message': 'RS $amountVal added to your pending earnings ledger. TrxID: $trxVal',
                      'isRead': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    setState(() {
                      questionData['isPaidToScholar'] = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment marked as PAID & notification sent!')),
                    );
                  },
                  child: const Text("Submit Payment"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double completedWeekAmount = 0;
    double runningWeekAmount = 0;

    for (var q in widget.questionsList) {
      bool isPaid = q['isPaidToScholar'] ?? false;
      if (isPaid) continue;

      double share = double.tryParse(q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0') ?? 0;
      Timestamp? t = q['answeredAt'] ?? q['createdAt'];

      if (t != null) {
        DateTime date = t.toDate();
        int differenceDays = DateTime.now().difference(date).inDays;

        if (differenceDays >= 7) {
          completedWeekAmount += share;
        } else {
          runningWeekAmount += share;
        }
      } else {
        runningWeekAmount += share;
      }
    }

    bool isWeekCompleted = completedWeekAmount > 0;
    double displayAmount = isWeekCompleted ? completedWeekAmount : runningWeekAmount;

    return Scaffold(
      backgroundColor: widget.isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text("Payout Details: ${widget.scholarName}"),
        backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayAmount == 0 ? "All Cleared:" : (isWeekCompleted ? "Completed Week Payout:" : "Running Week Balance:"),
                        style: TextStyle(
                          fontSize: 12,
                          color: displayAmount == 0 ? Colors.grey : (isWeekCompleted ? Colors.red : Colors.green),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "RS ${displayAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: displayAmount == 0 ? Colors.grey : (isWeekCompleted ? Colors.red : Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Scholar Answers & Questions Record:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.questionsList.length,
              itemBuilder: (context, index) {
                var q = widget.questionsList[index];

                String questionText = q['questionText'] ?? q['question'] ?? q['question_text'] ?? 'No Question';
                String additionalNote = q['Additional Note / Message'] ?? q['additionalNote'] ?? q['userAdditionalNote'] ?? '';
                String aiAnswerText = q['aiResponse'] ?? q['aiAnswer'] ?? 'No AI Answer';
                String scholarAnswerText = q['scholarResponse'] ?? q['answer'] ?? 'No Scholar Answer Yet';
                String amount = q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0';
                bool isPaid = q['isPaidToScholar'] ?? false;

                Timestamp? answeredAt = q['answeredAt'] as Timestamp?;
                String formattedDate = "N/A";
                String countdownText = "";
                Color countdownColor = Colors.grey;

                if (answeredAt != null) {
                  DateTime dateTime = answeredAt.toDate();
                  formattedDate = DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(dateTime);

                  int diffDays = DateTime.now().difference(dateTime).inDays;
                  if (isPaid) {
                    countdownText = "PAID";
                    countdownColor = Colors.green;
                  } else if (diffDays < 7) {
                    int daysLeft = 7 - diffDays;
                    countdownText = "$daysLeft day${daysLeft > 1 ? 's' : ''} left";
                    countdownColor = Colors.orange;
                  } else {
                    countdownText = "Ready to Pay ✅";
                    countdownColor = Colors.green;
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  countdownText,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: countdownColor),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text("RS $amount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                                const SizedBox(width: 10),
                                isPaid
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text("PAID", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                                    : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _openPaymentDialog(context, q),
                                  child: const Text("Pay Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text("Question: $questionText", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87)),
                        if (additionalNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text("Note: $additionalNote", style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.amber[300] : Colors.amber[800])),
                        ],
                        const SizedBox(height: 8),
                        Text("Scholar Answer: $scholarAnswerText", style: TextStyle(color: widget.isDark ? Colors.tealAccent : Colors.teal[800])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}