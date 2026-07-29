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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cloudinary Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _submitRequest() async {
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

      // 🔥 User ka naam ya email fetch karna taake scholar aur admin ke paas proper show ho
      String userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';

      // 1. User ka question aur payment details Firestore mein save karein
      await FirebaseFirestore.instance.collection('user_questions').add({
        'userId': user?.uid,
        'userName': userName, // 🔥 Added user name here
        'userEmail': user?.email, // 🔥 Added user email here
        'questionText': widget.question,
        'aiResponse': widget.aiAnswer,
        'scholarId': widget.selectedScholarId,
        'scholarName': widget.selectedScholarName,
        'transactionId': _tidController.text.trim(),
        'paymentProofUrl': _paymentProofUrl,
        'additionalNote': _suggestionController.text.trim(),
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. 🔔 Admin ke liye notifications collection mein entry
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'New Question Verification',
        'message': '$userName ne ${widget.selectedScholarName} ke liye sawal bheja hai.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request submitted successfully!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
            // Top Row: Scholar Info on Left, Payment Details Card on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Scholar: ${widget.selectedScholarName}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(width: 10),
                // 💳 Payment Details Card on Top Right
                FutureBuilder<DocumentSnapshot>(
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

                    return Container(
                      width: 240,
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
                          Text("EasyPaisa: ${paymentData['easyPaisaName'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          Text("${paymentData['easyPaisaNumber'] ?? 'N/A'}", style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text("JazzCash: ${paymentData['jazzCashName'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          Text("${paymentData['jazzCashNumber'] ?? 'N/A'}", style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  },
                ),
              ],
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