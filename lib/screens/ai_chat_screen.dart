import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'scholar_list_screen.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "content": "Assalamu Alaikum! How can I help you with your Islamic queries today?"
    }
  ];

  Future<void> _saveChatToHistory(String userMsg, String aiMsg) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('ai_chat_history').add({
        'userId': currentUser!.uid,
        'userMessage': userMsg,
        'aiResponse': aiMsg,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error handling
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    final aiText = "This is a sample AI response. You can integrate your generative AI API here.";

    setState(() {
      _messages.add({"role": "user", "content": userText});
      _messages.add({"role": "assistant", "content": aiText});
      _controller.clear();
    });

    _saveChatToHistory(userText, aiText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Islamic AI Chat"),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? (isDark ? AppTheme.accentGreen : AppTheme.primaryLight)
                              : (isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 16),
                          ),
                        ),
                        child: Text(
                          msg["content"]!,
                          style: TextStyle(
                            color: isUser
                                ? (isDark ? AppTheme.primaryDark : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),

                      if (!isUser && index > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 2),
                          child: InkWell(
                            onTap: () {
                              final userQuestion =
                                  _messages[index - 1]["content"] ?? "";
                              final aiAnswer = msg["content"] ?? "";

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScholarListScreen(
                                    questionData: {
                                      'questionText': userQuestion,
                                      'aiAnswer': aiAnswer,
                                    },
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 16,
                                    color: isDark
                                        ? AppTheme.accentGreen
                                        : AppTheme.primaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Verify with Scholar",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (isUser || index == 0) const SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildInputArea(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A332E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Ask something...",
                hintStyle:
                TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: InputBorder.none,
                filled: false,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
            child: IconButton(
              icon: Icon(Icons.send, color: isDark ? AppTheme.primaryDark : Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}