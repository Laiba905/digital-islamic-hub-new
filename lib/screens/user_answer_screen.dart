import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAnswerScreen extends StatelessWidget {
  const UserAnswerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Answers")),
        body: const Center(child: Text("Please login to view your answers.")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[55],
      appBar: AppBar(
        title: const Text("My Questions & Answers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 🔍 Debugging ke liye hum query se .where hata kar saare documents check kar rahe hain
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Database mein koi document hi mojood nahi hai!"));
          }

          var allDocs = snapshot.data!.docs;

          // 🔎 Filter for current user and answered status
          var userDocs = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String docUserId = data['userId']?.toString() ?? '';

            // Yahan check hoga ke kya current user ki UID match ho rahi hai
            return docUserId == user.uid;
          }).toList();

          if (userDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Aapki UID (${user.uid}) se koi sawal match nahi ho raha!\n\nShayed database mein sawal save hotay waqt 'userId' save nahi hui.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              var data = userDocs[index].data() as Map<String, dynamic>;

              String questionText = data['questionText'] ?? "No Question";
              String answerText = data['aiResponse'] ?? data['answer'] ?? "Abhi jawab nahi diya gaya";
              String scholarName = data['scholarName'] ?? "Aalim";
              String status = data['status'] ?? "pending";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text("Status: $status", style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: status == 'answered' ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Sawal: $questionText", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 16),
                      Text("Jawab ($scholarName): $answerText", style: const TextStyle(color: Colors.green, fontSize: 14)),
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