import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart'; // Apna service file yahan import karein (agar alag file mein hai)
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

  // Upload Image using CloudinaryService (Clean & Error-free)
  Future<void> _uploadToCloudinary(XFile imageFile) async {
    setState(() => _isUploadingImage = true);
    try {
      CloudinaryResponse response;

      if (kIsWeb) {
        // 🌟 FIXED: Changed 'fromBytesBytes' to 'fromByteData' and provided ByteData
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
        // Mobile (Android/iOS) ke liye file path use hota hai
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
      await FirebaseFirestore.instance.collection('user_questions').add({
        'userId': user?.uid,
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
      appBar: AppBar(title: const Text("Confirm Verification"), backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scholar: ${widget.selectedScholarName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2E7D32))),
            const Divider(),
            const Text("User Question:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.question, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text("Answer:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.aiAnswer, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),

            // Payment Details
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('app_settings').doc('payment_details').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Text("Payment details configuration not found."),
                  );
                }

                var paymentData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fee Amount: ${paymentData['feeAmount'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                      const Divider(),
                      Text("EasyPaisa Name: ${paymentData['easyPaisaName'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("EasyPaisa Number: ${paymentData['easyPaisaNumber'] ?? 'N/A'}", style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 8),
                      Text("JazzCash Name: ${paymentData['jazzCashName'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("JazzCash Number: ${paymentData['jazzCashNumber'] ?? 'N/A'}", style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                );
              },
            ),

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
