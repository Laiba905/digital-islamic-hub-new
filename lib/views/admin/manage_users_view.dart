import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  // 🚫 FUNCTION: User ko Block ya Unblock karne ke liye
  Future<void> _toggleBlockStatus(String userId, bool currentBlockStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBlocked': !currentBlockStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentBlockStatus ? 'User Unblocked Successfully!' : 'User Blocked Successfully!'),
            backgroundColor: currentBlockStatus ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dynamicPadding = screenWidth > 800 ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No users found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          var userDocs = snapshot.data!.docs;

          int totalUsers = userDocs.length;
          int blockedUsers = userDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['isBlocked'] == true;
          }).length;
          int activeUsers = totalUsers - blockedUsers;

          return SingleChildScrollView(
            padding: EdgeInsets.all(dynamicPadding),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard("Total Users", totalUsers.toString(), Colors.blue, Icons.people),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard("Active Users", activeUsers.toString(), Colors.green, Icons.person_add),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard("Blocked Users", blockedUsers.toString(), Colors.red, Icons.block),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "All Registered Users",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userDocs.length,
                      itemBuilder: (context, index) {
                        var doc = userDocs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        String userId = doc.id;

                        // 🌟 SCHOLARS CODE KI TARAH EXACT FALLBACK LOGIC
                        String name = data['name'] ?? data['displayName'] ?? data['fullName'] ?? '';
                        if (name.isEmpty && data['email'] != null) {
                          String emailStr = data['email'];
                          name = emailStr.split('@')[0];
                          if (name.isNotEmpty) {
                            name = name[0].toUpperCase() + name.substring(1);
                          }
                        }
                        if (name.isEmpty) {
                          name = 'User';
                        }

                        String email = data['email'] ?? 'No Email';
                        bool isBlocked = data['isBlocked'] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isBlocked ? Colors.red.shade100 : const Color(0xFF004D40),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: isBlocked ? Colors.red : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isBlocked ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              email,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _toggleBlockStatus(userId, isBlocked),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBlocked ? Colors.green : Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                isBlocked ? 'Unblock' : 'Block',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}