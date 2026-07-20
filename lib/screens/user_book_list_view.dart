import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../theme/app_theme.dart';

class ScholarQuestionsScreen extends StatefulWidget {
  const ScholarQuestionsScreen({super.key});

  @override
  State<ScholarQuestionsScreen> createState() => _ScholarQuestionsScreenState();
}

class _ScholarQuestionsScreenState extends State<ScholarQuestionsScreen> {
  final cloudinary = CloudinaryPublic('your_cloud_name', 'your_upload_preset', cache: false);

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _tidControllers = {};
  final User? user = FirebaseAuth.instance.currentUser;
  File? _selectedScreenshot;

  @override
  void dispose() {
    for (var controller in _controllers.values) controller.dispose();
    for (var controller in _tidControllers.values) controller.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _selectedScreenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitAnswer(String questionId, String answer) async {
    if (answer.trim().isEmpty) return;

    try {
      String? screenshotUrl;
      String transactionId = _tidControllers[questionId]?.text.trim() ?? "";

      if (_selectedScreenshot != null) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedScreenshot!.path,
            resourceType: CloudinaryResourceType.Image,
            publicId: 'question_${questionId}_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        screenshotUrl = response.secureUrl;
      }

      Map<String, dynamic> updateData = {
        'answer': answer.trim(),
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      };

      if (screenshotUrl != null) updateData['receiptScreenshotUrl'] = screenshotUrl;
      if (transactionId.isNotEmpty) updateData['transactionId'] = transactionId;

      await FirebaseFirestore.instance.collection('scholar_questions').doc(questionId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab submit ho gaya hai!")));
        setState(() => _selectedScreenshot = null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yahan aapka wahi purana UI code aayega jo aapne pehle likha tha
    // Main ne yahan basic structure de diya hai taake error hat jaye
    return Scaffold(
      appBar: AppBar(title: const Text("Questions")),
      body: const Center(child: Text("Scholar Questions Screen")),
    );
  }
}