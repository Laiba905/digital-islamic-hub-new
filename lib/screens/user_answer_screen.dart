import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class UserAnswerScreen extends StatefulWidget {
  const UserAnswerScreen({super.key});

  @override
  State<UserAnswerScreen> createState() => _UserAnswerScreenState();
}

class _UserAnswerScreenState extends State<UserAnswerScreen> {
  void _showFullDetails(BuildContext context, DocumentSnapshot doc, bool isDark) async {
    var data = doc.data() as Map<String, dynamic>;
    String docId = doc.id;

    bool isViewed = data['isViewed'] ?? false;
    if (!isViewed && data['status'] == 'answered') {
      await FirebaseFirestore.instance
          .collection('user_questions')
          .doc(docId)
          .update({'isViewed': true});
    }

    String status = data['status'] ?? 'pending_verification';

    if (status == 'rejected') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RejectionOptionsScreen(docId: docId, docData: data),
        ),
      );
      return;
    }

    String scholarAnswerText = data['scholarResponse'] ?? data['scholarAnswer'] ?? data['answer'] ?? '';
    String scholarName = data['scholarName'] ?? "Scholar";
    String aiResponseText = data['aiResponse'] ?? data['aiAnswer'] ?? '';
    String paymentScreenshot = data['paymentScreenshot'] ?? data['screenshotUrl'] ?? data['imageUrl'] ?? '';

    Timestamp? timestamp = data['createdAt'];
    String formattedDate = '';
    if (timestamp != null) {
      formattedDate = DateFormat('EEE, dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
          title: Row(
            children: [
              Icon(Icons.verified_user_rounded, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Question & Scholar Answers",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (formattedDate.isNotEmpty)
                    Text("Date & Time: $formattedDate", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Divider(height: 20),

                  Text("Your Question:", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(data['questionText'] ?? data['question'] ?? 'No text.', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 15),

                  if (aiResponseText.isNotEmpty) ...[
                    const Text("Initial AI Answer:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(aiResponseText, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 15),
                  ],

                  if (status == 'answered' && scholarAnswerText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.accentGreen.withAlpha(20) : AppTheme.primaryLight.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppTheme.accentGreen.withAlpha(50) : AppTheme.primaryLight.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_pin, size: 18, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                              const SizedBox(width: 6),
                              Text(
                                "Answer by $scholarName",
                                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scholarAnswerText,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(Icons.hourglass_top, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Scholar's answer is currently pending.", style: TextStyle(color: Colors.orange, fontSize: 13)),
                      ],
                    ),
                  ],

                  if (paymentScreenshot.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Text("Proof Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(paymentScreenshot, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close", style: TextStyle(color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Answers")),
        body: const Center(child: Text("Please login to view your answers.")),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Scholar Answers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(text: "Pending / Active", icon: Icon(Icons.hourglass_top)),
              Tab(text: "Scholar Answers", icon: Icon(Icons.question_answer)),
              Tab(text: "Rejected", icon: Icon(Icons.error_outline, color: Colors.redAccent)),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_questions')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
            }

            var allDocs = snapshot.data?.docs ?? [];

            var pendingDocs = allDocs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending_verification';
              return status == 'pending_verification' || status == 'sent_to_scholar';
            }).toList();

            var answeredDocs = allDocs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? '';
              return status == 'answered';
            }).toList();

            var rejectedDocs = allDocs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? '';
              return status == 'rejected';
            }).toList();

            return TabBarView(
              children: [
                _buildList(pendingDocs, isDark),
                _buildList(answeredDocs, isDark),
                _buildList(rejectedDocs, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs, bool isDark) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "No records found in this section.",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    docs.sort((a, b) {
      var dataA = a.data() as Map<String, dynamic>;
      var dataB = b.data() as Map<String, dynamic>;
      Timestamp? timeA = dataA['createdAt'];
      Timestamp? timeB = dataB['createdAt'];
      if (timeA == null || timeB == null) return 0;
      return timeB.compareTo(timeA);
    });

    return ListView.builder(
      itemCount: docs.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        var doc = docs[index];
        var data = doc.data() as Map<String, dynamic>;

        String status = data['status'] ?? 'pending_verification';
        String scholarName = data['scholarName'] ?? "Assigned Scholar";
        String rejectionReason = data['rejectionReason'] ?? 'Invalid details provided.';
        bool isAnswered = status == 'answered';
        bool isRejected = status == 'rejected';
        bool isViewed = data['isViewed'] ?? false;

        bool showAlertBadge = isAnswered && !isViewed;

        Color badgeColor = Colors.grey.shade700;
        Color badgeBg = Colors.grey.withValues(alpha: 0.1);
        String badgeText = "Pending Review";

        if (isRejected) {
          badgeColor = Colors.red.shade700;
          badgeBg = Colors.red.withValues(alpha: 0.15);
          badgeText = "Rejected";
        } else if (showAlertBadge) {
          badgeColor = Colors.orange.shade800;
          badgeBg = Colors.orange.withValues(alpha: 0.15);
          badgeText = "New Answer Received!";
        } else if (isAnswered) {
          badgeColor = Colors.green.shade700;
          badgeBg = Colors.green.withValues(alpha: 0.1);
          badgeText = "Viewed";
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isRejected ? Colors.red.withValues(alpha: 0.5) : (isDark ? Colors.white10 : AppTheme.primaryLight.withAlpha(30))),
          ),
          color: isDark ? Colors.white.withAlpha(12) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isRejected ? Colors.red : (isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                      child: Icon(isRejected ? Icons.error_outline : Icons.school, size: 18, color: isDark ? AppTheme.primaryDark : Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scholarName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TID: ${data['transactionId'] ?? data['tid'] ?? 'N/A'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isRejected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      "Reason: $rejectionReason",
                      style: TextStyle(color: Colors.red.shade300, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showFullDetails(context, doc, isDark),
                      icon: Icon(isRejected ? Icons.edit : Icons.visibility, size: 16, color: isDark ? AppTheme.primaryDark : Colors.white),
                      label: Text(
                        isRejected ? "View & Re-upload" : "View Full Details",
                        style: TextStyle(color: isDark ? AppTheme.primaryDark : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRejected ? Colors.red : (isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Options Screen for Rejection
class RejectionOptionsScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> docData;

  const RejectionOptionsScreen({super.key, required this.docId, required this.docData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String rejectionReason = docData['rejectionReason'] ?? 'Invalid details provided.';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
      appBar: AppBar(
        title: const Text("Fix & Resubmit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 22),
                      SizedBox(width: 8),
                      Text("Why was this rejected?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(rejectionReason, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text("Select what you want to change:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            // Option 1: Change ID Number
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.confirmation_number, color: Colors.white)),
                title: const Text("Change ID Number", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Update transaction/ID number (TID)"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SingleEditScreen(docId: docId, docData: docData, editType: EditType.tid)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Change Screenshot
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.image, color: Colors.white)),
                title: const Text("Change Screenshot", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Upload a new proof image"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SingleEditScreen(docId: docId, docData: docData, editType: EditType.screenshot)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Option 3: Change All Details
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.all_inclusive, color: Colors.white)),
                title: const Text("Change All Details", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Update ID and Screenshot together"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SingleEditScreen(docId: docId, docData: docData, editType: EditType.all)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum EditType { tid, screenshot, all }

class SingleEditScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> docData;
  final EditType editType;

  const SingleEditScreen({super.key, required this.docId, required this.docData, required this.editType});

  @override
  State<SingleEditScreen> createState() => _SingleEditScreenState();
}

class _SingleEditScreenState extends State<SingleEditScreen> {
  final TextEditingController _tidController = TextEditingController();
  bool _isUploading = false;
  String? _screenshotUrl;
  final String _cloudName = "lxuuhill";
  final String _uploadPreset = "AppPresent";

  @override
  void initState() {
    super.initState();
    _tidController.text = widget.docData['transactionId'] ?? widget.docData['tid'] ?? '';
    _screenshotUrl = widget.docData['paymentScreenshot'] ?? widget.docData['screenshotUrl'] ?? '';
  }

  @override
  void dispose() {
    _tidController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        var bytes = await pickedFile.readAsBytes();
        var uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

        var request = http.MultipartRequest("POST", uri)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
          setState(() => _screenshotUrl = jsonData['secure_url']);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Screenshot uploaded successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _resubmitField() async {
    Map<String, dynamic> updateData = {
      'status': 'pending_verification',
      'isResubmitted': true,
      'rejectionReason': FieldValue.delete(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (widget.editType == EditType.tid || widget.editType == EditType.all) {
      if (_tidController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid ID number.')));
        return;
      }
      updateData['transactionId'] = _tidController.text.trim();
      updateData['tid'] = _tidController.text.trim();
    }

    if (widget.editType == EditType.screenshot || widget.editType == EditType.all) {
      if (_screenshotUrl == null || _screenshotUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a screenshot.')));
        return;
      }
      updateData['paymentScreenshot'] = _screenshotUrl;
      updateData['screenshotUrl'] = _screenshotUrl;
    }

    setState(() => _isUploading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      // 1️⃣ Pehle user_questions document update karein
      await FirebaseFirestore.instance.collection('user_questions').doc(widget.docId).update(updateData);

      // 2️⃣ Phir admin ke liye notification generate karein ('Details Resubmitted' title ke sath)
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'admin',
        'title': 'Details Resubmitted ',
        'body': 'A user has updated their rejected details. Please verify.',
        'userId': currentUser?.uid ?? '',
        'questionId': widget.docId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully resubmitted for verification!')));
        Navigator.pop(context); // Close Edit Screen
        Navigator.pop(context); // Close Options Screen
      }
    } catch (e) {
      debugPrint("Resubmission Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String titleText = "";
    if (widget.editType == EditType.tid) titleText = "Change ID Number (TID)";
    if (widget.editType == EditType.screenshot) titleText = "Change Screenshot";
    if (widget.editType == EditType.all) titleText = "Change All Details";

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.editType == EditType.tid || widget.editType == EditType.all) ...[
              const Text("Enter New ID Number (TID):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _tidController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  hintText: 'Enter Transaction ID',
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (widget.editType == EditType.screenshot || widget.editType == EditType.all) ...[
              const Text("Screenshot Proof:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),

              if (_screenshotUrl != null && _screenshotUrl!.isNotEmpty)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.black,
                          child: Stack(
                            children: [
                              Center(
                                child: InteractiveViewer(
                                  child: Image.network(_screenshotUrl!),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_screenshotUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_screenshotUrl == null || _screenshotUrl!.isEmpty ? "Upload New Screenshot" : "Change Screenshot"),
                ),
              ),
              const SizedBox(height: 30),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _resubmitField,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Resubmit for Verification",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}