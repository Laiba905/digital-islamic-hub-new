import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 1. Scholar Questions Main Screen (Shows User List Cards)
class ScholarQuestionsScreen extends StatelessWidget {
  final String scholarId;
  const ScholarQuestionsScreen({super.key, required this.scholarId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Scholar Inquiries", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('scholarId', isEqualTo: scholarId)
            .where('status', whereIn: ['sent_to_scholar', 'answered'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No inquiries found for this scholar.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          // Group questions by userId
          Map<String, List<DocumentSnapshot>> userGroups = {};

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String userId = data['userId'] ?? 'unknown_user';
            userGroups.putIfAbsent(userId, () => []).add(doc);
          }

          var userIds = userGroups.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              String userId = userIds[index];
              var userDocs = userGroups[userId]!;

              // Sort user docs to find the latest message date & pending count
              userDocs.sort((a, b) {
                Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'];
                Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'];
                if (timeA == null || timeB == null) return 0;
                return timeB.compareTo(timeA);
              });

              int pendingCount = userDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'sent_to_scholar').length;

              var latestData = userDocs.first.data() as Map<String, dynamic>;
              String lastMessage = latestData['questionText'] ?? '';
              Timestamp? latestTimestamp = latestData['createdAt'];

              String formattedDate = 'Recent';
              if (latestTimestamp != null) {
                formattedDate = DateFormat('EEE, dd MMM yyyy, hh:mm a').format(latestTimestamp.toDate());
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  String displayName = "User";

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    var userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                    String? fetchedName = userData?['displayName'] ?? userData?['name'] ?? userData?['fullName'] ?? userData?['userName'];
                    String? fetchedEmail = userData?['email'] ?? userData?['userEmail'];

                    if (fetchedName != null && fetchedName.trim().isNotEmpty) {
                      displayName = fetchedName;
                    } else if (fetchedEmail != null && fetchedEmail.contains('@')) {
                      displayName = fetchedEmail.split('@').first;
                    } else {
                      displayName = "User ($userId)";
                    }
                  } else if (latestData['userName'] != null && latestData['userName'].toString().trim().isNotEmpty && latestData['userName'] != "User") {
                    displayName = latestData['userName'];
                  } else if (latestData['name'] != null && latestData['name'].toString().trim().isNotEmpty) {
                    displayName = latestData['name'];
                  } else {
                    displayName = "User";
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2E7D32).withAlpha(30),
                        child: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "New Query ($pendingCount)",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserChatDetailScreen(
                              userId: userId,
                              userName: displayName,
                              scholarId: scholarId,
                            ),
                          ),
                        );
                      },
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

// 2. User Detail Chat/Questions Screen (Shows specific user's questions in order)
class UserChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String scholarId;

  const UserChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.scholarId,
  });

  @override
  State<UserChatDetailScreen> createState() => _UserChatDetailScreenState();
}

class _UserChatDetailScreenState extends State<UserChatDetailScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) controller.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(String questionId, String answer, String userId, String scholarName) async {
    if (answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab likhna zaroori hai!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Update Question in Firestore
      await FirebaseFirestore.instance.collection('user_questions').doc(questionId).update({
        'scholarResponse': answer.trim(),
        'scholarName': scholarName,
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Notification for User
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'user',
        'userId': userId,
        'title': 'Jawab Agaya! ✅',
        'message': 'Scholar ($scholarName) ne aapke sawal ka jawab de diya hai.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Notification for Admin
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'admin',
        'title': 'Scholar Answered!',
        'message': 'Scholar ($scholarName) ne aik sawal ka jawab submit kar diya hai.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawab aur notifications kamyabi se bhej diye gaye hain!")));
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
        title: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_questions')
            .where('scholarId', isEqualTo: widget.scholarId)
            .where('userId', isEqualTo: widget.userId)
            .where('status', whereIn: ['sent_to_scholar', 'answered'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No queries found for this user.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          docs.sort((a, b) {
            Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'];
            Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'];
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String qId = doc.id;

              String questionText = data['questionText'] ?? "No Question Text";
              String aiAnswer = data['aiResponse'] ?? "No AI response recorded.";
              String scholarName = data['scholarName'] ?? 'Aalim';
              bool isAnswered = data['status'] == 'answered';
              String scholarShare = data['scholarShare']?.toString() ?? '50';

              String? additionalNote = data['additionalNote'];

              Timestamp? timestamp = data['createdAt'];
              String formattedDateTime = 'Recent';
              if (timestamp != null) {
                formattedDateTime = DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(timestamp.toDate());
              }

              if (!_controllers.containsKey(qId)) {
                _controllers[qId] = TextEditingController(text: data['scholarResponse'] ?? "");
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Text(
                                "User: ${widget.userName}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            ],
                          ),
                          Text(
                            formattedDateTime,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAnswered ? Colors.green.withAlpha(38) : Colors.orange.withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAnswered ? "Answered" : "New Query",
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
                              color: Colors.blue.withAlpha(38),
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
                      const Divider(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.withAlpha(20) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withAlpha(70)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "User Question",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              questionText,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (additionalNote != null && additionalNote.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.purple.withAlpha(20) : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.purple.withAlpha(70)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Additional Note / Message",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                additionalNote,
                                style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.orange.withAlpha(20) : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withAlpha(70)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "AI Answer",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              aiAnswer,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Row(
                        children: [
                          Icon(Icons.edit_note, size: 20, color: Color(0xFF2E7D32)),
                          SizedBox(width: 6),
                          Text(
                            "Scholar Answer :",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controllers[qId],
                        maxLines: 4,
                        enabled: !isAnswered,
                        decoration: InputDecoration(
                          hintText: "Enter your Answer",
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
                                : () => _submitAnswer(qId, _controllers[qId]!.text, widget.userId, scholarName),
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