import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class UserQuestionScreen extends StatefulWidget {
  final String question;
  final String aiAnswer;
  final String selectedScholarId;
  final String selectedScholarName;

  const UserQuestionScreen({
    super.key,
    required this.question,
    required this.aiAnswer,
    required this.selectedScholarId,
    required this.selectedScholarName,
  });

  @override
  State<UserQuestionScreen> createState() => _UserQuestionScreenState();
}

class _UserQuestionScreenState extends State<UserQuestionScreen> {
  final _tidController = TextEditingController();
  final _amountController = TextEditingController();
  final _suggestionController = TextEditingController();
  bool _isLoading = false;

  XFile? _selectedImage;
  String? _paymentProofUrl;
  bool _isUploadingImage = false;

  // Pick Image from Gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
        await _uploadToCloudinary(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image Picker Error: $e")));
      }
    }
  }

  // Upload Image using CloudinaryService
  Future<void> _uploadToCloudinary(XFile imageFile) async {
    setState(() => _isUploadingImage = true);
    try {
      CloudinaryResponse response;

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        response = await CloudinaryService.cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            bytes.buffer.asByteData(),
            identifier: imageFile.name,
            resourceType: CloudinaryResourceType.Image,
            folder: 'payment_proofs',
          ),
        );
      } else {
        response = await CloudinaryService.cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'payment_proofs',
          ),
        );
      }

      if (response.secureUrl.isNotEmpty) {
        setState(() {
          _paymentProofUrl = response.secureUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment screenshot uploaded successfully!")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(" Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter paid amount")));
      return;
    }
    if (_tidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Transaction ID")));
      return;
    }
    if (_paymentProofUrl == null || _paymentProofUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload payment screenshot")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String userName = 'User';

      // 🚀 Firestore se user ka asal naam fetch kar rahe hain
      if (user != null) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            userName = userData['name'] ?? userData['fullName'] ?? user.displayName ?? user.email?.split('@').first ?? 'User';
          } else {
            userName = user.displayName ?? user.email?.split('@').first ?? 'User';
          }
        } catch (e) {
          userName = user.displayName ?? user.email?.split('@').first ?? 'User';
        }
      }

      String enteredAmount = _amountController.text.trim();

      // 1. User ka question aur payment details Firestore mein save karein
      DocumentReference questionDoc = await FirebaseFirestore.instance.collection('user_questions').add({
        'userId': user?.uid ?? 'anonymous',
        'userName': userName,
        'userEmail': user?.email ?? '',
        'questionText': widget.question,
        'aiResponse': widget.aiAnswer,
        'scholarId': widget.selectedScholarId,
        'scholarName': widget.selectedScholarName,
        'amountPaid': enteredAmount,
        'transactionId': _tidController.text.trim(),
        'paymentProofUrl': _paymentProofUrl,
        'additionalNote': _suggestionController.text.trim(),
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. 🔔 Admin ke liye 'notifications' collection mein entry bhejna (Real Name ke sath)
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'admin',
        'questionId': questionDoc.id,
        'userName': userName,
        'amountPaid': enteredAmount,
        'title': 'New Payment & Question!',
        'message': '$userName sent a question with a payment of Rs $enteredAmount.',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request submitted successfully!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      print("CRITICAL SUBMISSION ERROR: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Submission Error"),
            content: Text("Masla aa raha hai: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Verification"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Right: Payment Details Card
            Align(
              alignment: Alignment.centerRight,
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('app_settings').doc('payment_details').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(width: 150, child: LinearProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Text("No payment info", style: TextStyle(fontSize: 12)),
                    );
                  }

                  var paymentData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

                  String epName = paymentData['easyPaisaName'] ?? '';
                  String epNumber = paymentData['easyPaisaNumber'] ?? '';
                  String jpName = paymentData['jazzCashName'] ?? '';
                  String jpNumber = paymentData['jazzCashNumber'] ?? '';

                  return Container(
                    width: 260,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fee Amount: ${paymentData['feeAmount'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                        const Divider(height: 8),

                        if (epName.isNotEmpty || epNumber.isNotEmpty) ...[
                          Text("EasyPaisa: $epName - $epNumber", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                        ],

                        if (jpName.isNotEmpty || jpNumber.isNotEmpty) ...[
                          Text("JazzCash: $jpName - $jpNumber", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 30),
            const Text("User Question:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.question, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text("Answer:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.aiAnswer, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),

            TextField(
              controller: _suggestionController,
              decoration: const InputDecoration(
                labelText: "Additional Note / Question (Optional)",
                hintText: "Could I share an extra thought with you regarding this topic?",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Paid Amount (e.g., 300)",
                border: OutlineInputBorder(),
                hintText: "Enter exact amount you paid",
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _tidController,
              decoration: const InputDecoration(labelText: "Transaction ID", border: OutlineInputBorder(), hintText: "Enter your payment TID"),
            ),
            const SizedBox(height: 20),

            const Text("Upload Payment Screenshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                ),
                child: _isUploadingImage
                    ? const Center(child: CircularProgressIndicator())
                    : _paymentProofUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.network(_paymentProofUrl!, fit: BoxFit.cover)
                      : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF2E7D32)),
                    SizedBox(height: 8),
                    Text("Click here to upload payment screenshot", style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Question", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}