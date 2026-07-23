import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ScholarQuestionsScreen extends StatefulWidget {
  final String scholarId;
  const ScholarQuestionsScreen({super.key, required this.scholarId});

  @override
  State<ScholarQuestionsScreen> createState() => _ScholarQuestionsScreenState();
}

class _ScholarQuestionsScreenState extends State<ScholarQuestionsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) controller.dispose();
    super.dispose();
  }

  // 🚀 Submit Function with Notifications for User & Admin
  Future<void> _submitAnswer(String questionId, String answer, String userId, String scholarName) async {
    if (answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab likhna zaroori hai!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Answer ko update ya save karein
      await FirebaseFirestore.instance.collection('user_questions').doc(questionId).update({
        'aiResponse': answer.trim(),
        'scholarName': scholarName,
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });

      // 2. User ke liye Notification bhejein
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'user',
        'targetId': userId,
        'title': 'Jawab Agaya! ✅',
        'message': 'Scholar ($scholarName) ne aapke sawal ka jawab de diya hai.',
        'isRead': false,
        'timestamp': Timestamp.now(),
      });

      // 3. Admin ke liye Notification bhejein
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'admin',
        'targetId': 'admin_id_yahan_aaye_gi',
        'title': 'New Answer Submitted 📝',
        'message': 'Scholar ($scholarName) ne aik sawal ka jawab submit kar diya hai.',
        'isRead': false,
        'timestamp': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab aur Notifications kamyabi se bhej di gayi hain!")));
        setState(() => _isLoading = false);
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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Scholar Questions", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('scholarId', isEqualTo: widget.scholarId)
            .where('status', whereIn: ['sent_to_scholar', 'answered'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No questions found for this scholar.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String qId = doc.id;
              String questionText = data['questionText'] ?? "No Question Text";
              String userId = data['userId'] ?? '';
              String scholarName = data['scholarName'] ?? 'Aalim';
              bool isAnswered = data['status'] == 'answered';
              String scholarShare = data['scholarShare']?.toString() ?? '50';

              if (!_controllers.containsKey(qId)) {
                _controllers[qId] = TextEditingController(text: data['aiResponse'] ?? "");
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAnswered ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAnswered ? "Answered" : "Pending",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAnswered ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Your Share: RS $scholarShare",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text("Question from User:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        questionText,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      const Divider(height: 24),
                      const Row(
                        children: [
                          Icon(Icons.edit_note, size: 20, color: Color(0xFF2E7D32)),
                          SizedBox(width: 6),
                          Text(
                            "Write Your Answer / Jawab Dein:",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controllers[qId],
                        maxLines: 4,
                        enabled: !isAnswered,
                        decoration: InputDecoration(
                          hintText: "Apna fatwa ya tafseeli jawab yahan type karein...",
                          filled: true,
                          fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isAnswered) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _submitAnswer(qId, _controllers[qId]!.text, userId, scholarName),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Submit Answer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Answer has been submitted successfully.",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
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