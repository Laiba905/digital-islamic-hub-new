import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../theme/app_theme.dart';
import 'cloudinary_service.dart'; // Apna service file import karein

class ScholarQuestionsScreen extends StatefulWidget {
  final String scholarId; // 🌟 Naya parameter
  const ScholarQuestionsScreen({super.key, required this.scholarId});

  @override
  State<ScholarQuestionsScreen> createState() => _ScholarQuestionsScreenState();
}

class _ScholarQuestionsScreenState extends State<ScholarQuestionsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _tidControllers = {};
  XFile? _selectedScreenshot;
  bool _isLoading = false;

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
      setState(() => _selectedScreenshot = pickedFile);
    }
  }

  Future<void> _submitAnswer(String questionId, String answer) async {
    if (answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab likhna zaroori hai!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? screenshotUrl;
      String transactionId = _tidControllers[questionId]?.text.trim() ?? "";

      // 🔄 CloudinaryService ka use
      if (_selectedScreenshot != null) {
        CloudinaryResponse response;
        if (kIsWeb) {
          final bytes = await _selectedScreenshot!.readAsBytes();
          response = await CloudinaryService.cloudinary.uploadFile(
            CloudinaryFile.fromByteData(
              bytes.buffer.asByteData(),
              identifier: _selectedScreenshot!.name,
              resourceType: CloudinaryResourceType.Image,
              folder: 'scholar_responses',
            ),
          );
        } else {
          response = await CloudinaryService.cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              _selectedScreenshot!.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'scholar_responses',
            ),
          );
        }
        screenshotUrl = response.secureUrl;
      }

      await FirebaseFirestore.instance.collection('scholar_questions').doc(questionId).update({
        'answer': answer.trim(),
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
        if (screenshotUrl != null) 'receiptScreenshotUrl': screenshotUrl,
        if (transactionId.isNotEmpty) 'transactionId': transactionId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab submit ho gaya hai!")));
        setState(() {
          _selectedScreenshot = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Scholar Questions"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🌟 Yahan widget.scholarId ka use ho raha hai
        stream: FirebaseFirestore.instance
            .collection('scholar_questions')
            .where('scholarId', isEqualTo: widget.scholarId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No questions found for this scholar."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String qId = doc.id;
              bool isAnswered = data['status'] == 'answered';

              if (!_controllers.containsKey(qId)) _controllers[qId] = TextEditingController(text: data['answer'] ?? "");
              if (!_tidControllers.containsKey(qId)) _tidControllers[qId] = TextEditingController(text: data['transactionId'] ?? "");

              return Container(
                // ... (Aapka UI code wahi rahega)
                // Bas make sure karein ke 'isAnswered' logic yahan sahi chal rahi hai
                child: Column(children: [ /* ... UI Code ... */ ]),
              );
            },
          );
        },
      ),
    );
  }
}