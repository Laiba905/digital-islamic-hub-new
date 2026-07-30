import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersView extends StatelessWidget {
  const ManageUsersView({super.key});

  Stream<int> getUserCount({String? statusValue}) {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String status = (data['status'] ?? 'active').toString();

        if (statusValue != null) {
          return status == statusValue;
        }
        return status != 'blocked';
      }).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Manage Users Account Control"),
        backgroundColor: const Color(0xFF003D33),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("User Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                _counterCard("Total Users", getUserCount(), Colors.blue, Icons.people_outline),
                const SizedBox(width: 16),
                _counterCard("Active", getUserCount(statusValue: 'active'), Colors.green, Icons.check_circle_outline),
                const SizedBox(width: 16),
                _counterCard("Blocked", getUserCount(statusValue: 'blocked'), Colors.red, Icons.block_outlined),
              ],
            ),
            const SizedBox(height: 40),
            const Text("Registered Users List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF003D33)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No users found in users collection.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;

            String userName = (data['displayName'] ?? data['name'] ?? '').toString().trim();
            String userEmail = (data['email'] ?? 'No Email').toString().trim();
            String status = (data['status'] ?? 'active').toString();

            if (userName.isEmpty) {
              if (userEmail != 'No Email' && userEmail.contains('@')) {
                userName = userEmail.split('@')[0];
              } else {
                userName = "User_${docId.substring(0, 5)}";
              }
            }

            bool isBlocked = status == 'blocked';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: isBlocked ? Colors.red.shade50 : Colors.teal.shade50,
                    child: Icon(isBlocked ? Icons.block : Icons.person_outline, color: isBlocked ? Colors.red : const Color(0xFF003D33)),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    userEmail,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(docId).update({
                          'status': isBlocked ? 'active' : 'blocked',
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.green : Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isBlocked ? "Unblock" : "Block Account",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _counterCard(String title, Stream<int> stream, Color color, IconData icon) {
    return Expanded(
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    snapshot.data?.toString() ?? '0',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}