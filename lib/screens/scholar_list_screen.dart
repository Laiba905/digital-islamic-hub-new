import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_question_screen.dart'; // UserQuestionScreen yahan import ho gaya

class ScholarListScreen extends StatelessWidget {
  final Map<String, dynamic> questionData;

  const ScholarListScreen({super.key, required this.questionData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Scholar"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scholars')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading scholars."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var scholars = snapshot.data!.docs;

          if (scholars.isEmpty) {
            return const Center(child: Text("No Approved scholars found."));
          }

          return ListView.builder(
            itemCount: scholars.length,
            itemBuilder: (context, index) {
              var scholarDoc = scholars[index].data() as Map<String, dynamic>;
              String scholarId = scholars[index].id; // Ye ID har scholar ki unique hai

              String scholarName = scholarDoc['displayName'] ?? scholarDoc['email'] ?? 'Unknown Scholar';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(scholarName, style: const TextStyle(fontWeight: FontWeight.bold)),
                // 🚀 Yahan se subtitle (matric / Expert Scholar) ko remove kar diya gaya hai
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserQuestionScreen(
                        question: questionData['questionText'] ?? "",
                        aiAnswer: questionData['aiAnswer'] ?? "",
                        selectedScholarId: scholarId,
                        selectedScholarName: scholarName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}