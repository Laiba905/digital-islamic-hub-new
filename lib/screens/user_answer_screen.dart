import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserAnswerScreen extends StatelessWidget {
  const UserAnswerScreen({super.key});

  // 🌟 Detail Dialog aur Read Status Update Logic
  void _showFullDetails(BuildContext context, DocumentSnapshot doc, bool isDark) async {
    var data = doc.data() as Map<String, dynamic>;
    String docId = doc.id;

    // Agar user ne abhi tak nahi dekha, toh Firestore mein isViewed true kar do taake badge khatam ho jaye
    bool isViewed = data['isViewed'] ?? false;
    if (!isViewed && data['status'] == 'answered') {
      await FirebaseFirestore.instance
          .collection('user_questions')
          .doc(docId)
          .update({'isViewed': true});
    }

    String status = data['status'] ?? 'pending_verification';
    String scholarAnswerText = data['scholarResponse'] ?? data['scholarAnswer'] ?? data['answer'] ?? '';
    String scholarName = data['scholarName'] ?? "Scholar";
    String aiResponseText = data['aiResponse'] ?? data['aiAnswer'] ?? '';
    String paymentScreenshot = data['paymentScreenshot'] ?? data['screenshotUrl'] ?? data['imageUrl'] ?? '';

    Timestamp? timestamp = data['createdAt'];
    String formattedDate = '';
    if (timestamp != null) {
      formattedDate = DateFormat('EEE, dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1A332E) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Question & Scholar Answers",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF003D33),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (formattedDate.isNotEmpty)
                    Text("Date & Time: $formattedDate", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Divider(height: 20),

                  // User Question
                  const Text("Your Question:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(data['questionText'] ?? data['question'] ?? 'No text.', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 15),

                  // AI Answer
                  if (aiResponseText.isNotEmpty) ...[
                    const Text("Initial AI Answer:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(aiResponseText, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 15),
                  ],

                  // Scholar Answer Section
                  if (status == 'answered' && scholarAnswerText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin, size: 18, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Text(
                                "Answer by $scholarName",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scholarAnswerText,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(Icons.hourglass_top, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Scholar ka jawab abhi pending hai.", style: TextStyle(color: Colors.orange, fontSize: 13)),
                      ],
                    ),
                  ],

                  // Payment Screenshot
                  if (paymentScreenshot.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Text("Payment Screenshot:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(paymentScreenshot, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(" Scholar Answers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF003D33) : const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          var historyDocs = snapshot.data?.docs ?? [];

          if (historyDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.question_answer_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "No scholar verifications requested yet.",
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // 🕒 Newest / Recently updated questions ko sab se upar lane ke liye sorting
          historyDocs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;

            Timestamp? timeA = dataA['createdAt'];
            Timestamp? timeB = dataB['createdAt'];

            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA); // Latest upar aayega
          });

          return ListView.builder(
            itemCount: historyDocs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var doc = historyDocs[index];
              var data = doc.data() as Map<String, dynamic>;

              String status = data['status'] ?? 'pending_verification';
              String scholarName = data['scholarName'] ?? "Assigned Scholar";
              bool isAnswered = status == 'answered';
              bool isViewed = data['isViewed'] ?? false;

              // Badge sirf tab show hoga jab jawab aa chuka ho aur user ne click karke na dekha ho
              bool showAlertBadge = isAnswered && !isViewed;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.green.shade100),
                ),
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF1B5E20),
                                child: Icon(Icons.school, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scholarName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'TID: ${data['transactionId'] ?? data['tid'] ?? 'N/A'}',
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: showAlertBadge
                                  ? Colors.orange.withOpacity(0.15)
                                  : (isAnswered ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              showAlertBadge
                                  ? "New Answer Aagya Hai!"
                                  : (isAnswered ? "Viewed" : "Pending Review"),
                              style: TextStyle(
                                color: showAlertBadge
                                    ? Colors.orange.shade800
                                    : (isAnswered ? Colors.green.shade700 : Colors.grey.shade700),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showFullDetails(context, doc, isDark),
                            icon: const Icon(Icons.visibility, size: 16, color: Colors.white),
                            label: const Text(
                              "View Full Details",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
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