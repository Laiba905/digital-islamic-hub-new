import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarDashboardView extends StatefulWidget {
  final String scholarId; // Pass current authenticated scholar's ID

  const ScholarDashboardView({super.key, required this.scholarId});

  @override
  State<ScholarDashboardView> createState() => _ScholarDashboardViewState();
}

class _ScholarDashboardViewState extends State<ScholarDashboardView> {
  final TextEditingController _answerController = TextEditingController();
  DocumentSnapshot? _activeQueryDoc;

  void _submitAnswer() async {
    if (_activeQueryDoc == null || _answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please write your answer before submitting.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // Submitting answer and changing status to completed/answered
      await FirebaseFirestore.instance.collection('payments').doc(_activeQueryDoc!.id).update({
        'status': 'answered',
        'scholarAnswer': _answerController.text.trim(),
        'answeredAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Jawab kamyabi se user ko bhej diya gaya hai!'), backgroundColor: Colors.green),
      );

      setState(() {
        _activeQueryDoc = null;
        _answerController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Submission Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Scholar Assignment Desk'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('status', isEqualTo: 'sent_to_scholar')
            .where('assignedScholarId', isEqualTo: widget.scholarId) // Filters questions specific to this scholar
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('🎉 No new assigned questions from Admin.'));
          }

          var assignedQuestions = snapshot.data!.docs;

          return Row(
            children: [
              // Left Section: Assigned Questions Queue
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assignedQuestions.length,
                    itemBuilder: (context, index) {
                      var data = assignedQuestions[index].data() as Map<String, dynamic>;
                      bool isSelected = _activeQueryDoc?.id == assignedQuestions[index].id;

                      return Card(
                        color: isSelected ? const Color(0xFFE0F2F1) : const Color(0xFFF5F7F8),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text('Task from: ${data['userName'] ?? 'Anonymous'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Status: Paid & Unanswered', style: TextStyle(color: Colors.orange, fontSize: 12)),
                          onTap: () {
                            setState(() {
                              _activeQueryDoc = assignedQuestions[index];
                              _answerController.clear();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Right Section: Workspace to write fatwa/answer
              Expanded(
                flex: 6,
                child: _activeQueryDoc == null
                    ? const Center(child: Text('Sawal padhne aur jawab likhne ke liye item select karein.'))
                    : Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Question Text:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                        child: Text(
                          (_activeQueryDoc!.data() as Map<String, dynamic>?)?['questionText'] ?? '',
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Write Your Authentic Answer:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _answerController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Yahan apna mukammal jawab/fatwa type karein...',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), padding: const EdgeInsets.symmetric(vertical: 16)),
                          icon: const Icon(Icons.done_all, color: Colors.white),
                          label: const Text('Submit & Send Answer to User', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}