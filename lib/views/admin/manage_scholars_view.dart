import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageScholarsPage extends StatelessWidget {
  const ManageScholarsPage({Key? key}) : super(key: key);

  // 📈 Dynamic Stream: Scholars ke status ke mutabik counting
  Stream<int> getScholarCount({String? statusValue}) {
    Query query = FirebaseFirestore.instance.collection('scholars');

    if (statusValue != null) {
      query = query.where('status', isEqualTo: statusValue);
    } else {
      // Total verified scholars ke liye blocked ko nikal kar baaki sab (active ya empty status) count karein
      return FirebaseFirestore.instance
          .collection('scholars')
          .snapshots()
          .map((snapshot) => snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['status'] != 'blocked';
      }).length);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Manage Scholars"),
        backgroundColor: const Color(0xFF003D33),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Scholar Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                _counterCard("Total Scholars", getScholarCount(), Colors.blue, Icons.school_outlined),
                const SizedBox(width: 16),
                _counterCard("Active", getScholarCount(statusValue: 'active'), Colors.green, Icons.check_circle_outline),
                const SizedBox(width: 16),
                _counterCard("Blocked", getScholarCount(statusValue: 'blocked'), Colors.red, Icons.block_outlined),
              ],
            ),

            const SizedBox(height: 40),
            // 🌟 SECTION: VERIFIED SCHOLARS LIST
            const Text("Verified Scholar List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildVerifiedScholarsList(),
          ],
        ),
      ),
    );
  }

  // 🛠️ UI: Verified Scholars ki List (Fallbacks ke saath)
  Widget _buildVerifiedScholarsList() {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 FIX: Phele sirf status check ho rha tha, ab pooray scholars collection ko listen krengay
      stream: FirebaseFirestore.instance.collection('scholars').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF003D33)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No verified scholars found in scholars collection.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // Filter out blocked ones if needed, or display all who completed sign up
        var docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var scholar = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            bool isBlocked = scholar['status'] == 'blocked';

            // AAPKE FIELDS: Database ke exact keys key mutabik
            String scholarName = scholar['name'] ?? scholar['displayName'] ?? 'Verified Scholar';
            String scholarEmail = scholar['email'] ?? 'No Email';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: isBlocked ? Colors.red.shade50 : Colors.blue.shade50,
                    child: Icon(Icons.school, color: isBlocked ? Colors.red : const Color(0xFF003D33)),
                  ),
                  title: Text(
                    scholarName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    scholarEmail,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Directly update status in scholars collection
                        await FirebaseFirestore.instance.collection('scholars').doc(docId).update({
                          'status': isBlocked ? 'active' : 'blocked',
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.green : Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isBlocked ? "Unblock" : "Block",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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