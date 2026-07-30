import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _targetIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRole = 'scholar';
  bool _isLoading = false;

  void _sendNotification() async {
    String targetId = _targetIdController.text.trim();
    String title = _titleController.text.trim();
    String message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title aur Message zaroori hain!"), backgroundColor: Colors.red),
      );
      return;
    }

    // Agar pure public ko nahi bhej rahe toh ID zaroori hai
    if (targetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Target UID likhna zaroori hai!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': _selectedRole,
        'targetId': targetId,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification successfully bhej di gayi! 🚀"), backgroundColor: Colors.green),
        );
      }

      _titleController.clear();
      _messageController.clear();
      _targetIdController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF004D40);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Broadcast", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📝 LEFT SIDE: Form (Notification Bhejne Ke Liye)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Compose Notification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'scholar', child: Text('Send to Scholar 🎓')),
                          DropdownMenuItem(value: 'user', child: Text('Send to User 📱')),
                        ],
                        onChanged: (value) => setState(() => _selectedRole = value!),
                        decoration: InputDecoration(
                          labelText: "Select Target Audience",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _targetIdController,
                        decoration: InputDecoration(
                          labelText: "Target Firebase UID",
                          hintText: "Enter specific user/scholar ID",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.fingerprint),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: "Notification Title",
                          hintText: "e.g. Document Approved!",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: "Message Body",
                          hintText: "Write your complete details here...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.message_outlined),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _sendNotification,
                          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.send_rounded),
                          label: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Send Announcement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 📜 RIGHT SIDE: Sent History (Bheji gayi notifications ki live history)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Sent History (Live Log)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No notifications sent yet.", style: TextStyle(color: Colors.grey)));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var doc = snapshot.data!.docs[index];
                            var data = doc.data() as Map<String, dynamic>;

                            bool isScholar = data['targetRole'] == 'scholar';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isScholar ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                child: Icon(
                                  isScholar ? Icons.school : Icons.person,
                                  color: isScholar ? Colors.orange : Colors.blue,
                                  size: 18,
                                ),
                              ),
                              title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(data['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                onPressed: () => FirebaseFirestore.instance.collection('notifications').doc(doc.id).delete(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}