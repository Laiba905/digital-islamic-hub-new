import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserNotificationScreen extends StatelessWidget {
  const UserNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Firestore se notifications fetch kar rahe hain (latest pehle aayein ge)
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet!"));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              bool isRead = data['isRead'] ?? false;

              // Fields ko check kar rahe hain taake agar 'body' ki jagah kuch aur ho toh wo utha le
              String title = data['title'] ?? data['heading'] ?? 'No Title';
              String body = data['body'] ?? data['message'] ?? data['description'] ?? 'No Body Content';

              // Jis ne notification bheja ho (Agar Firestore mein 'sender' ya 'adminName' ka field ho)
              String sender = data['sender'] ?? data['sentBy'] ?? 'Admin / School';

              return Card(
                color: isRead ? Colors.white : Colors.blue.shade50, // Unread message highlight ho ga
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.blue),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body),
                      const SizedBox(height: 6),
                      // Bhejne wale ka naam show karne ke liye
                      Text(
                        "Sent by: $sender",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Jab user notification par click kare ga, toh isay 'read' mark kar dein
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(docId)
                        .update({'isRead': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}