import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SunnahDeedsView extends StatefulWidget {
  const SunnahDeedsView({super.key});

  @override
  State<SunnahDeedsView> createState() => _SunnahDeedsViewState();
}

class _SunnahDeedsViewState extends State<SunnahDeedsView> {
  final List<TextEditingController> _taskControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _pointsControllers = List.generate(3, (_) => TextEditingController(text: '2'));

  bool _isUploading = false;

  Future<void> _updateDailyTasks() async {
    bool hasEmpty = false;
    for (int i = 0; i < 3; i++) {
      if (_taskControllers[i].text.trim().isEmpty || _pointsControllers[i].text.trim().isEmpty) {
        hasEmpty = true;
        break;
      }
    }

    if (hasEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make sure to include the titles and points of all 3 deeds!')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      String todayDateStr = DateTime.now().toIso8601String().split('T')[0];

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      for (int i = 0; i < 3; i++) {
        DocumentReference docRef = firestore.collection('daily_deeds').doc();
        batch.set(docRef, {
          'title': _taskControllers[i].text.trim(),
          'points': int.tryParse(_pointsControllers[i].text.trim()) ?? 2,
          'createdAt': Timestamp.now(),
          'dateStr': todayDateStr,
          'deedIndex': i + 1,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily Deeds Successfully Published! 🎉'), backgroundColor: Colors.green),
        );
      }

      for (int i = 0; i < 3; i++) {
        _taskControllers[i].clear();
        _pointsControllers[i].text = '2';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
  void dispose() {
    for (var c in _taskControllers) c.dispose();
    for (var c in _pointsControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String todayDateStr = DateTime.now().toIso8601String().split('T')[0];
    final screenWidth = MediaQuery.of(context).size.width;
    final double dynamicPadding = screenWidth > 800 ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Sunnah & Deeds Management'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Manage30DaysDeedsView()),
                );
              },
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('Manage 30-Day Program', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(dynamicPadding),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(dynamicPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Publish 3 Daily Sunnah/Deeds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                        const SizedBox(height: 8),
                        const Text('Set up 3 daily tasks with 2 points each (or customize as needed).', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 24),
                        for (int i = 0; i < 3; i++) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _taskControllers[i],
                                  decoration: InputDecoration(
                                    labelText: 'Deed ${i + 1} Title',
                                    hintText: 'e.g., Istighfar 10 times',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _pointsControllers[i],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Points',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (i < 2) const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _updateDailyTasks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text('Publish All 3 Deeds', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SunnahHistoryView()));
                      },
                      icon: const Icon(Icons.history, size: 18, color: Color(0xFF004D40)),
                      label: const Text("View All History", style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('daily_deeds')
                      .where('dateStr', isEqualTo: todayDateStr)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFF004D40))));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: const Center(child: Text("No deeds active for today.", style: TextStyle(color: Colors.grey, fontSize: 15, fontStyle: FontStyle.italic))),
                      );
                    }

                    var validDocs = snapshot.data!.docs.where((doc) => doc.id != 'program_config').toList();

                    if (validDocs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: const Center(child: Text("No deeds active for today.", style: TextStyle(color: Colors.grey, fontSize: 15, fontStyle: FontStyle.italic))),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: validDocs.length,
                      itemBuilder: (context, index) {
                        var doc = validDocs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF004D40),
                              child: Text("+${data['points'] ?? 2}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            subtitle: const Text("Active for today's users", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                              onPressed: () => _deleteDeed(doc.id),
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

// 🗓️ 30 DAYS PROGRAM MANAGEMENT SCREEN (Using 'daily_deeds' collection & day_1 to day_30 IDs)
class Manage30DaysDeedsView extends StatefulWidget {
  const Manage30DaysDeedsView({super.key});

  @override
  State<Manage30DaysDeedsView> createState() => _Manage30DaysDeedsViewState();
}

class _Manage30DaysDeedsViewState extends State<Manage30DaysDeedsView> {
  final List<List<TextEditingController>> _titleControllers = List.generate(
    30,
        (_) => List.generate(3, (_) => TextEditingController()),
  );

  final List<List<TextEditingController>> _pointsControllers = List.generate(
    30,
        (_) => List.generate(3, (_) => TextEditingController(text: '2')),
  );

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchExisting30DaysData();
  }

  Future<void> _fetchExisting30DaysData() async {
    try {
      for (int day = 1; day <= 30; day++) {
        var doc = await FirebaseFirestore.instance.collection('daily_deeds').doc('day_$day').get();
        if (doc.exists && doc.data() != null) {
          List tasks = doc.data()!['tasks'] ?? [];
          int index = day - 1;
          for (int t = 0; t < tasks.length && t < 3; t++) {
            _titleControllers[index][t].text = tasks[t]['title'] ?? '';
            _pointsControllers[index][t].text = (tasks[t]['points'] ?? 2).toString();
          }
        }
      }
    } catch (e) {
      print("Error fetching 30 days data: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveAll30Days() async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (int day = 1; day <= 30; day++) {
        int index = day - 1;
        // Yahan DocumentReference type use ki gayi hai
        DocumentReference docRef = FirebaseFirestore.instance.collection('daily_deeds').doc('day_$day');

        List<Map<String, dynamic>> dayTasks = [];
        for (int t = 0; t < 3; t++) {
          dayTasks.add({
            'title': _titleControllers[index][t].text.trim(),
            'points': int.tryParse(_pointsControllers[index][t].text.trim()) ?? 2,
          });
        }

        batch.set(docRef, {
          'dayNumber': day,
          'tasks': dayTasks,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('30 Days Program Saved Successfully! 🌟', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage 30-Day Program '),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveAll30Days,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save All 30 Days', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent.shade700, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 30,
        itemBuilder: (context, index) {
          int day = index + 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day $day Program', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                  const Divider(),
                  const SizedBox(height: 8),
                  for (int t = 0; t < 3; t++) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _titleControllers[index][t],
                            decoration: InputDecoration(
                              labelText: 'Task ${t + 1} Title',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _pointsControllers[index][t],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Points',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (t < 2) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SunnahHistoryView extends StatelessWidget {
  const SunnahHistoryView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History'), backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
      body: const Center(child: Text('History View')),
    );
  }
}