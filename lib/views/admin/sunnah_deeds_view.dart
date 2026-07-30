import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 📌 REUSABLE CODE: History page ko open karne ke liye is file ko import karna lazmi hai
import 'sunnah_history_view.dart';

class SunnahDeedsView extends StatefulWidget {
  const SunnahDeedsView({super.key});

  @override
  State<SunnahDeedsView> createState() => _SunnahDeedsViewState();
}

class _SunnahDeedsViewState extends State<SunnahDeedsView> {
  // 📝 Controllers: Form ke inputs ka data track karne ke liye
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(text: '10');

  // 🔄 Loading State: Jab Firebase par data upload ho raha ho to spinner dikhane ke liye
  bool _isUploading = false;

  // 🚀 FUNCTION: Naya deed publish karne ke liye
  Future<void> _updateDailyTask() async {
    if (_taskController.text.isEmpty || _pointsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meharbani karke Title aur Points lazmi likhein!')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 📅 Aaj ki date string format mein (Jaise: 2026-07-02)
      String todayDateStr = DateTime.now().toIso8601String().split('T')[0];

      // 🔥 Firebase Firestore: 'daily_deeds' collection mein data save ho raha hai
      await FirebaseFirestore.instance.collection('daily_deeds').add({
        'title': _taskController.text.trim(),
        'points': int.parse(_pointsController.text.trim()),
        'createdAt': Timestamp.now(), // Real timestamp sorting ke liye
        'dateStr': todayDateStr, // 24 ghante baad dashboard se hide karne ke liye date check
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily Sunnah Published Successfully! 🎉')),
        );
      }

      // Upload hone ke baad input fields ko khali karna
      _taskController.clear();
      _pointsController.text = '10';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // 🗑️ FUNCTION: Active list se kisi deed ko permanent delete karne ke liye
  Future<void> _deleteDeed(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('daily_deeds').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deed Deleted Successfully! 🗑️'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String todayDateStr = DateTime.now().toIso8601String().split('T')[0];

    // 🖥️ RESPONSIVE CONFIG: Agar screen Web/Tablet jitni bari ho to zyada padding, mobile par kam padding.
    final screenWidth = MediaQuery.of(context).size.width;
    final double dynamicPadding = screenWidth > 800 ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Sunnah & Deeds Management'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dynamicPadding),
        child: Center(
          // 📐 RESPONSIVE CONSTRAINT: Web par layout ko bht zyada khinchne se rokne ke liye MaxWidth lagayi hai
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📝 FORM CARD: Naya task add karne ka panel
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(dynamicPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Publish New Daily Sunnah/Deed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _taskController,
                          decoration: const InputDecoration(labelText: 'Task Title (e.g., Smile, it\'s Sunnah.)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Points for completing this deed (e.g., 10)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 24),

                        // 🎯 BUTTON ALIGNMENT: Button ko right side par chota kar ke lagane ke liye Align widget use kiya hai
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 180, // 👈 BUTTON WIDTH: Yahan se aap button ki chorai mazeed choti ya bari kar sakte hain
                            height: 42,  // 👈 BUTTON HEIGHT: Button ko vertical chota aur sleek banaya hai
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _updateDailyTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Clean corners
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text('Publish Deed to Users', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                const Divider(thickness: 1.5),
                const SizedBox(height: 20),

                // 📋 HEADER: Today's History aur "View All History" ka button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                    TextButton.icon(
                      onPressed: () {
                        // 🚀 NAVIGATION: Click karne par alag banaye gaye history page par redirect karega
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SunnahHistoryView()));
                      },
                      icon: const Icon(Icons.history, size: 18, color: Color(0xFF004D40)),
                      label: const Text("View All History", style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔄 24-HOUR ACTIVE STREAM: Sirf aaj ke deeds live utha raha hai
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('daily_deeds').where('dateStr', isEqualTo: todayDateStr).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFF004D40))));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: const Center(child: Text("No deeds active for last 24 hours.", style: TextStyle(color: Colors.grey, fontSize: 15, fontStyle: FontStyle.italic))),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF004D40),
                              child: Text("+${data['points'] ?? 10}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            subtitle: const Text("Active for today's users", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                              onPressed: () {
                                // Deletion Confirmation Dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Sunnah/Deed?'),
                                    content: const Text('Kya aap waqai is task ko delete karna chahte hain?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteDeed(doc.id);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}