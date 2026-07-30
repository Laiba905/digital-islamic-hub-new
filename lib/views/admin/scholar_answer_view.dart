import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:admin/view_models/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io' show File; // Safe import for mobile (ignored on web automatically)

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('status', isEqualTo: 'answered')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Abhi tak koi answered sawal mojood nahi hai."),
            );
          }

          var docs = snapshot.data!.docs;

          docs.sort((a, b) {
            Timestamp? timeA = (a.data() as Map<String, dynamic>)['answeredAt'] ?? (a.data() as Map<String, dynamic>)['createdAt'];
            Timestamp? timeB = (b.data() as Map<String, dynamic>)['answeredAt'] ?? (b.data() as Map<String, dynamic>)['createdAt'];
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          Map<String, List<Map<String, dynamic>>> scholarGroups = {};
          Map<String, String> scholarPhones = {};

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;

            String scholarName = data['scholarName'] ?? 'Unknown Scholar';
            String scholarPhone = data['scholarPhone'] ?? 'Number mojood nahi';
            bool isPaid = data['isPaidToScholar'] ?? false;

            if (!isPaid) {
              if (!scholarGroups.containsKey(scholarName)) {
                scholarGroups[scholarName] = [];
              }
              scholarGroups[scholarName]!.add(data);
              scholarPhones[scholarName] = scholarPhone;
            }
          }

          if (scholarGroups.isEmpty) {
            return const Center(
              child: Text(
                "Tamam scholars ke haftawar paise ada kiye ja chuke hain!",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            );
          }

          var scholarKeys = scholarGroups.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scholarKeys.length,
            itemBuilder: (context, index) {
              String scholarName = scholarKeys[index];
              var questionsList = scholarGroups[scholarName]!;
              String scholarPhone = scholarPhones[scholarName] ?? '';

              double totalWeeklyAmount = 0;
              for (var q in questionsList) {
                double share = double.tryParse(q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0') ?? 0;
                totalWeeklyAmount += share;
              }

              bool isWeekCompleted = false;
              for (var q in questionsList) {
                Timestamp? t = q['answeredAt'] ?? q['createdAt'];
                if (t != null) {
                  DateTime date = t.toDate();
                  if (DateTime.now().difference(date).inDays >= 7) {
                    isWeekCompleted = true;
                    break;
                  }
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
                                "Account / Number: $scholarPhone",
                                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red, width: 1.5),
                            ),
                            child: Text(
                              "RS ${totalWeeklyAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
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
                            "Total Haftawar Jawabat: ${questionsList.length}",
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isWeekCompleted ? Colors.red : Colors.green,
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
      ),
    );
  }
}

// 📱 FULL SCREEN DETAILS PAGE
class ScholarWithdrawalFullScreen extends StatefulWidget {
  final String scholarName;
  final List<Map<String, dynamic>> questionsList;
  final bool isDark;

  const ScholarWithdrawalFullScreen({
    super.key,
    required this.scholarName,
    required this.questionsList,
    required this.isDark,
  });

  @override
  State<ScholarWithdrawalFullScreen> createState() => _ScholarWithdrawalFullScreenState();
}

class _ScholarWithdrawalFullScreenState extends State<ScholarWithdrawalFullScreen> {

  @override
  Widget build(BuildContext context) {
    double completedWeekAmount = 0;
    double runningWeekAmount = 0;
    List<Map<String, dynamic>> completedQuestions = [];

    for (var q in widget.questionsList) {
      double share = double.tryParse(q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0') ?? 0;
      Timestamp? t = q['answeredAt'] ?? q['createdAt'];

      if (t != null) {
        DateTime date = t.toDate();
        int differenceDays = DateTime.now().difference(date).inDays;

        if (differenceDays >= 7) {
          completedWeekAmount += share;
          completedQuestions.add(q);
        } else {
          runningWeekAmount += share;
        }
      } else {
        runningWeekAmount += share;
      }
    }

    bool isWeekCompleted = completedWeekAmount > 0;
    double displayAmount = isWeekCompleted ? completedWeekAmount : runningWeekAmount;
    List<Map<String, dynamic>> targetQuestions = isWeekCompleted ? completedQuestions : widget.questionsList;

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
                        isWeekCompleted ? "Completed Week Payout:" : "Running Week Balance:",
                        style: TextStyle(
                          fontSize: 12,
                          color: isWeekCompleted ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "RS ${displayAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isWeekCompleted ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWeekCompleted ? "Hafta poora ho chuka hai!" : "Running week (Click to process payout screen)",
                        style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWeekCompleted ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentSubmitFullScreen(
                            scholarName: widget.scholarName,
                            totalAmount: displayAmount,
                            questionsList: targetQuestions.isNotEmpty ? targetQuestions : widget.questionsList,
                            isDark: widget.isDark,
                          ),
                        ),
                      );
                    },
                    icon: Icon(isWeekCompleted ? Icons.payment : Icons.lock_open, size: 18),
                    label: Text(
                      isWeekCompleted ? "Withdraw / Pay" : "Process Payout",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
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
                String questionText = q['questionText'] ?? q['question'] ?? 'No Question';

                String additionalNote = q['Additional Note / Message'] ??
                    q['additionalNote'] ??
                    q['userAdditionalNote'] ??
                    q['additional_note'] ??
                    q['user_note'] ??
                    q['note'] ?? '';

                String aiAnswerText = q['aiResponse'] ?? q['aiAnswer'] ?? 'No AI Answer';
                String scholarAnswerText = q['scholarResponse'] ?? q['answer'] ?? 'No Scholar Answer Yet';
                String amount = q['scholarShare']?.toString() ?? q['amount']?.toString() ?? '0';

                Timestamp? answeredAt = q['answeredAt'] as Timestamp?;
                String formattedDate = "N/A";
                if (answeredAt != null) {
                  DateTime dateTime = answeredAt.toDate();
                  formattedDate = DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(dateTime);
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
                            Text("RS $amount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                          ],
                        ),
                        const Divider(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.blue.withAlpha(20) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withAlpha(70)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("User Question", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text(questionText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (additionalNote.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.isDark ? Colors.purple.withAlpha(20) : Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.withAlpha(70)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Additional Note / Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
                                const SizedBox(height: 4),
                                Text(additionalNote, style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black87)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.orange.withAlpha(20) : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withAlpha(70)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("AI Answer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                              const SizedBox(height: 4),
                              Text(aiAnswerText, style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black87)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.green.withAlpha(20) : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Scholar Answer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                    const SizedBox(height: 4),
                                    Text(scholarAnswerText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: widget.isDark ? Colors.greenAccent : const Color(0xFF2E7D32))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentSubmitFullScreen(
                                        scholarName: widget.scholarName,
                                        totalAmount: double.tryParse(amount) ?? 50.0,
                                        questionsList: [q],
                                        isDark: widget.isDark,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send, size: 14),
                                label: const Text("Pay", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
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

// 🌐 SPLIT SCREEN LAYOUT WITH CLOUDINARY UPLOAD
class PaymentSubmitFullScreen extends StatefulWidget {
  final String scholarName;
  final double totalAmount;
  final List<Map<String, dynamic>> questionsList;
  final bool isDark;

  const PaymentSubmitFullScreen({
    super.key,
    required this.scholarName,
    required this.totalAmount,
    required this.questionsList,
    required this.isDark,
  });

  @override
  State<PaymentSubmitFullScreen> createState() => _PaymentSubmitFullScreenState();
}

class _PaymentSubmitFullScreenState extends State<PaymentSubmitFullScreen> {
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isSubmitting = false;
  XFile? _pickedImageFile;
  Uint8List? _webImageBytes;
  String? _uploadedImageUrl;
  String _liveTimeText = "Not sent yet";

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(0);
    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _pickedImageFile = image;
        _liveTimeText = DateFormat('dd MMM yyyy, hh:mm:ss a').format(DateTime.now());
      });

      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        setState(() { _webImageBytes = bytes; });
      }

      await _uploadToCloudinary();
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_pickedImageFile == null) return;

    setState(() => _isSubmitting = true);
    try {
      CloudinaryResponse response;
      if (kIsWeb) {
        response = await CloudinaryService.cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            _webImageBytes!,
            resourceType: CloudinaryResourceType.Image,
            identifier: 'payment_screenshot_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      } else {
        response = await CloudinaryService.cloudinary.uploadFile(
          CloudinaryFile.fromFile(_pickedImageFile!.path, resourceType: CloudinaryResourceType.Image),
        );
      }

      setState(() {
        _uploadedImageUrl = response.secureUrl;
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Screenshot successfully Cloudinary par upload ho gaya hai!")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cloudinary upload fail ho gaya: $e")),
        );
      }
    }
  }

  Future<void> _submitPaymentRecord() async {
    if (_transactionIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction ID likhna lazmi hai!")));
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Amount likhna lazmi hai!")));
      return;
    }

    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment screenshot upload karna lazmi hai!")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      double finalPaidAmount = double.tryParse(_amountController.text.trim()) ?? widget.totalAmount;

      for (var q in widget.questionsList) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('user_questions').doc(q['docId']);
        batch.update(docRef, {
          'isPaidToScholar': true,
          'transactionId': _transactionIdController.text.trim(),
          'paidAmount': finalPaidAmount,
          'paymentScreenshot': _uploadedImageUrl ?? '',
          'paidAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment record successfully save ho gaya hai!")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text("Submit Payment: ${widget.scholarName}"),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👈 LEFT SIDE: Form & Amount Entry Controls
            Expanded(
              flex: 1,
              child: Card(
                color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Payment Details Entry",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: "Amount to Send (RS)",
                          hintText: "Enter amount",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: widget.isDark ? Colors.black26 : Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _transactionIdController,
                        style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Transaction ID / Receipt Number",
                          hintText: "Enter transaction ID",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: widget.isDark ? Colors.black26 : Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 20),

                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(_pickedImageFile != null ? "Change Screenshot" : "Upload Payment Screenshot"),
                      ),
                      if (_uploadedImageUrl != null) ...[
                        const SizedBox(height: 8),
                        const Text("Uploaded to Cloudinary Successfully!", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: _isSubmitting ? null : _submitPaymentRecord,
                            child: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Submit & Save Payment"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // 👉 RIGHT SIDE: Real-time Live Summary Preview
            Expanded(
              flex: 1,
              child: Card(
                color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Live Payment Summary",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87)),
                          const Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
                        ],
                      ),
                      const Divider(height: 24),

                      Text("Scholar Name:", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      Text(widget.scholarName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.tealAccent : const Color(0xFF004D40))),
                      const SizedBox(height: 12),

                      Text("Total Amount to be Paid:", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      Text("RS ${_amountController.text}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 12),

                      Text("Transaction ID:", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      Text(_transactionIdController.text.isEmpty ? "Not entered yet" : _transactionIdController.text,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: widget.isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 12),

                      Text("Timestamp:", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      Text(_liveTimeText, style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 20),

                      const Text("Payment Screenshot Preview:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.black26 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withAlpha(80)),
                        ),
                        child: _pickedImageFile == null
                            ? const Center(child: Text("No screenshot selected yet", style: TextStyle(color: Colors.grey)))
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                              : Image.file(File(_pickedImageFile!.path), fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}