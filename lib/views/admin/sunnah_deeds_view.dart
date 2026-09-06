import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SunnahDeedsView extends StatefulWidget {
  const SunnahDeedsView({super.key});

  @override
  State<SunnahDeedsView> createState() => _SunnahDeedsViewState();
}

class _SunnahDeedsViewState extends State<SunnahDeedsView> {
  final List<TextEditingController> _taskControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _pointsControllers = List.generate(3, (_) => TextEditingController(text: '10'));

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
        const SnackBar(content: Text('Please make sure to include the titles and points of all deeds!')),
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
          'points': int.tryParse(_pointsControllers[i].text.trim()) ?? 10,
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
        _pointsControllers[i].text = '10';
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
                        const Text('You can set and publish up to deeds and their points all at once here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                                    hintText: 'e.g., Smile, it\'s Sunnah.',
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
                              child: Text("+${data['points'] ?? 10}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            subtitle: const Text("Active for today's users", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Sunnah/Deed?'),
                                    content: const Text('Do you really want to delete this task?'),
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

// 📜 SUNNAH HISTORY VIEW (With Multi-Select & Bulk Delete Option Added)
class SunnahHistoryView extends StatefulWidget {
  final String appBarTitle;
  final String emptyMessage;

  const SunnahHistoryView({
    super.key,
    this.appBarTitle = 'All Published Deeds History',
    this.emptyMessage = 'No data found in history..',
  });

  @override
  State<SunnahHistoryView> createState() => _SunnahHistoryViewState();
}

class _SunnahHistoryViewState extends State<SunnahHistoryView> {
  final Set<String> _selectedDocIds = {};
  bool _isDeleting = false;

  String _parseFirebaseTimestamp(dynamic firestoreTimestamp) {
    if (firestoreTimestamp == null) return 'N/A';
    DateTime dateTime = (firestoreTimestamp as Timestamp).toDate();
    String year = dateTime.year.toString();
    String month = _getMonthName(dateTime.month);
    String day = dateTime.day.toString().padLeft(2, '0');
    int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "$day $month $year, $hour:$minute $amPm";
  }

  String _getMonthName(int monthNum) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[monthNum - 1];
  }

  Future<void> _deleteHistoryItem(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('daily_deeds').doc(docId).delete();
      setState(() {
        _selectedDocIds.remove(docId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History item deleted successfully! 🗑️'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting history item: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSelectedItems(List<QueryDocumentSnapshot> allDocs) async {
    if (_selectedDocIds.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Deeds?'),
        content: Text('Are you sure you want to delete ${_selectedDocIds.length} selected history items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (String docId in _selectedDocIds) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('daily_deeds').doc(docId);
        batch.delete(docRef);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }

      setState(() {
        _selectedDocIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected history items deleted successfully! 🗑️', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting selected items: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth > 800 ? 40.0 : 16.0;
    final double verticalPadding = screenWidth > 800 ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_deeds')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              var validDocs = snapshot.data!.docs.where((doc) => doc.id != 'program_config').toList();
              if (validDocs.isEmpty) return const SizedBox.shrink();

              bool allSelected = _selectedDocIds.length == validDocs.length;

              return Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          _selectedDocIds.clear();
                        } else {
                          _selectedDocIds.clear();
                          for (var doc in validDocs) {
                            _selectedDocIds.add(doc.id);
                          }
                        }
                      });
                    },
                    icon: Icon(allSelected ? Icons.deselect : Icons.select_all, color: Colors.white, size: 18),
                    label: Text(
                      allSelected ? 'Deselect All' : 'Select All',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_selectedDocIds.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isDeleting ? null : () => _deleteSelectedItems(validDocs),
                      icon: _isDeleting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                          : const Icon(Icons.delete, color: Colors.white, size: 18),
                      label: Text('Delete (${_selectedDocIds.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('daily_deeds')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF004D40)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      widget.emptyMessage,
                      style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                var validDocs = snapshot.data!.docs.where((doc) => doc.id != 'program_config').toList();

                if (validDocs.isEmpty) {
                  return Center(
                    child: Text(
                      widget.emptyMessage,
                      style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: validDocs.length,
                  itemBuilder: (context, index) {
                    var doc = validDocs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isSelected = _selectedDocIds.contains(doc.id);

                    String formattedDateTime = _parseFirebaseTimestamp(data['createdAt']);
                    int points = data['points'] ?? 10;
                    String title = data['title'] ?? 'No Title';
                    int deedIndex = data['deedIndex'] ?? (index % 3) + 1;
                    int? dayNumber = data['dayNumber'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF004D40) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      color: isSelected ? Colors.teal.shade50 : Colors.white,
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDocIds.remove(doc.id);
                            } else {
                              _selectedDocIds.add(doc.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF004D40),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedDocIds.add(doc.id);
                                    } else {
                                      _selectedDocIds.remove(doc.id);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              CircleAvatar(
                                backgroundColor: const Color(0xFF004D40),
                                radius: 18,
                                child: Text(
                                  "$deedIndex",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                        ),
                                        if (dayNumber != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.teal.shade200),
                                            ),
                                            child: Text(
                                              "Day $dayNumber",
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_filled, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Published on: $formattedDateTime",
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.shade200),
                                ),
                                child: Text(
                                  "+$points pts",
                                  style: const TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                                tooltip: 'Delete History Deed',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete History Deed?'),
                                      content: const Text('Are you sure you want to delete this deed from history?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteHistoryItem(context, doc.id);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// 🗓️ 30 DAYS PROGRAM MANAGEMENT SCREEN
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
        (_) => List.generate(3, (_) => TextEditingController(text: '10')),
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
      var doc = await FirebaseFirestore.instance.collection('daily_deeds').doc('program_config').get();
      if (doc.exists && doc.data() != null) {
        List list = doc.data()!['deeds_list'] ?? [];
        for (int i = 0; i < list.length && i < 30; i++) {
          var dayData = list[i];
          if (dayData['deeds'] != null && dayData['deeds'] is List) {
            List dayDeeds = dayData['deeds'];
            for (int j = 0; j < dayDeeds.length && j < 3; j++) {
              _titleControllers[i][j].text = dayDeeds[j]['title'] ?? '';
              _pointsControllers[i][j].text = (dayDeeds[j]['points'] ?? 10).toString();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading 30 days data: $e");
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _saveAndAutoPublishAll30Days() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> thirtyDaysList = [];

      for (int i = 0; i < 30; i++) {
        List<Map<String, dynamic>> dayDeedsList = [];
        for (int j = 0; j < 3; j++) {
          dayDeedsList.add({
            'deed_index': j + 1,
            'title': _titleControllers[i][j].text.trim(),
            'points': int.tryParse(_pointsControllers[i][j].text.trim()) ?? 10,
          });
        }

        thirtyDaysList.add({
          'day': i + 1,
          'deeds': dayDeedsList,
        });
      }

      await FirebaseFirestore.instance.collection('daily_deeds').doc('program_config').set({
        'total_days': 30,
        'deeds_list': thirtyDaysList,
        'startDate': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      DateTime today = DateTime.now();
      String todayDateStr = today.toIso8601String().split('T')[0];

      var futureDeeds = await FirebaseFirestore.instance
          .collection('daily_deeds')
          .where('dateStr', isGreaterThanOrEqualTo: todayDateStr)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int operationCount = 0;

      for (var doc in futureDeeds.docs) {
        if (doc.id != 'program_config') {
          batch.delete(doc.reference);
          operationCount++;
          if (operationCount >= 400) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            operationCount = 0;
          }
        }
      }

      for (int i = 0; i < 30; i++) {
        String futureDateStr = today.add(Duration(days: i)).toIso8601String().split('T')[0];

        for (int j = 0; j < 3; j++) {
          DocumentReference newDeedRef = FirebaseFirestore.instance.collection('daily_deeds').doc();
          batch.set(newDeedRef, {
            'title': _titleControllers[i][j].text.trim(),
            'points': int.tryParse(_pointsControllers[i][j].text.trim()) ?? 10,
            'createdAt': Timestamp.now(),
            'dateStr': futureDateStr,
            'deedIndex': j + 1,
            'dayNumber': i + 1,
          });
          operationCount++;

          if (operationCount >= 400) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            operationCount = 0;
          }
        }
      }

      await batch.commit();
      await _fetchExisting30DaysData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All 30 Days Saved & Auto-Published Successfully! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearDayDeeds(int dayIndex) async {
    setState(() => _isLoading = true);
    try {
      for (int j = 0; j < 3; j++) {
        _titleControllers[dayIndex][j].clear();
        _pointsControllers[dayIndex][j].text = '10';
      }

      List<Map<String, dynamic>> thirtyDaysList = [];
      for (int i = 0; i < 30; i++) {
        List<Map<String, dynamic>> dayDeedsList = [];
        for (int j = 0; j < 3; j++) {
          dayDeedsList.add({
            'deed_index': j + 1,
            'title': _titleControllers[i][j].text.trim(),
            'points': int.tryParse(_pointsControllers[i][j].text.trim()) ?? 10,
          });
        }
        thirtyDaysList.add({
          'day': i + 1,
          'deeds': dayDeedsList,
        });
      }

      await FirebaseFirestore.instance.collection('daily_deeds').doc('program_config').update({
        'deeds_list': thirtyDaysList,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      int targetDayNumber = dayIndex + 1;
      var matchingDeeds = await FirebaseFirestore.instance
          .collection('daily_deeds')
          .where('dayNumber', isEqualTo: targetDayNumber)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in matchingDeeds.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Day $targetDayNumber cleared & removed successfully! 🗑️'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing day: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < 30; i++) {
      for (int j = 0; j < 3; j++) {
        _titleControllers[i][j].dispose();
        _pointsControllers[i][j].dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Manage 30-Day Program (3 Deeds/Day)'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SunnahHistoryView(
                    appBarTitle: '30-Day Program History',
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveAndAutoPublishAll30Days,
              icon: const Icon(Icons.cloud_upload, size: 18),
              label: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Publish All 30 Days', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Day ${index + 1}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 24),
                        tooltip: 'Clear Day ${index + 1} Deeds',
                        onPressed: _isLoading
                            ? null
                            : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Clear Day ${index + 1} Deeds?'),
                              content: Text('Are you sure you want to delete and reset all deeds for Day ${index + 1}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearDayDeeds(index);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int j = 0; j < 3; j++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _titleControllers[index][j],
                            decoration: InputDecoration(
                              labelText: 'Day ${index + 1} - Deed ${j + 1} Title',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _pointsControllers[index][j],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Points',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (j < 2) const SizedBox(height: 12),
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