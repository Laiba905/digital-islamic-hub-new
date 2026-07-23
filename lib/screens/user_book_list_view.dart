import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../theme/app_theme.dart'; // Apna theme path check kar lein

class ScholarQuestionsScreen extends StatefulWidget {
  const ScholarQuestionsScreen({super.key});

  @override
  State<ScholarQuestionsScreen> createState() => _ScholarQuestionsScreenState();
}

class _ScholarQuestionsScreenState extends State<ScholarQuestionsScreen> {
  // 📌 Cloudinary Initialization
  final cloudinary = CloudinaryPublic('lxuuhill', 'AppPresent', cache: false);

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

  Future<void> _submitAnswer(String questionId) async {
    String answer = _controllers[questionId]?.text ?? "";
    if (answer.trim().isEmpty) return;

    try {
      String? screenshotUrl;
      String transactionId = _tidControllers[questionId]?.text.trim() ?? "";

      // 1. Cloudinary Upload Logic
      if (_selectedScreenshot != null) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedScreenshot!.path,
            resourceType: CloudinaryResourceType.Image,
            publicId: 'ans_${questionId}_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        screenshotUrl = response.secureUrl;
      }

      // 2. Firestore Update
      Map<String, dynamic> updateData = {
        'answer': answer.trim(),
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      };

      if (screenshotUrl != null) updateData['receiptScreenshotUrl'] = screenshotUrl;
      if (transactionId.isNotEmpty) updateData['transactionId'] = transactionId;

      await FirebaseFirestore.instance.collection('scholar_questions').doc(questionId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab submit ho gaya hai! 🎉")));
        setState(() => _selectedScreenshot = null);
        _controllers[questionId]?.clear();
        _tidControllers[questionId]?.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Questions")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scholar_questions').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              String qId = doc.id;
              _controllers.putIfAbsent(qId, () => TextEditingController());
              _tidControllers.putIfAbsent(qId, () => TextEditingController());

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Q: ${doc['questionText']}"),
                      TextField(controller: _controllers[qId], decoration: const InputDecoration(labelText: "Jawab likhein")),
                      TextField(controller: _tidControllers[qId], decoration: const InputDecoration(labelText: "Transaction ID")),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _pickScreenshot,
                        icon: const Icon(Icons.image),
                        label: Text(_selectedScreenshot != null ? "Screenshot attached" : "Attach Screenshot"),
                      ),
                      ElevatedButton(
                        onPressed: () => _submitAnswer(qId),
                        child: const Text("Submit Answer"),
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