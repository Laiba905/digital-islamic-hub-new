import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isLoading = false;

  // ... (Submit logic wahi rahegi) ...
  Future<void> _submitRequest() async {
    if (_tidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Transaction ID")));
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
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request submitted successfully!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Verification"), backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
      body: SingleChildScrollView( // Scrollable banaya taake sab dikhe
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scholar: ${widget.selectedScholarName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2E7D32))),
            const Divider(),

            // --- DISPLAYING QUESTION & AI ANSWER ---
            const Text("Aapka Sawal:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.question, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text("AI Jawab:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.aiAnswer, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),

            // --- FETCHING PAYMENT DETAILS FROM FIRESTORE ---
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('scholar_applications').doc(widget.selectedScholarId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var scholarData = snapshot.data!.data() as Map<String, dynamic>;
                String paymentMethod = scholarData['paymentMethod'] ?? 'N/A';
                String phone = scholarData['phone'] ?? 'N/A';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Text("Payment Detail: $paymentMethod", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Number: $phone", style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _tidController,
              decoration: const InputDecoration(labelText: "Transaction ID", border: OutlineInputBorder(), hintText: "Enter your payment TID"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Question"),
              ),
            )
          ],
        ),
      ),
    );
  }
}