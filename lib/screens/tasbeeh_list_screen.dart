import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'tasbeeh_counter_screen.dart';

class TasbeehListScreen extends StatefulWidget {
  const TasbeehListScreen({super.key});

  @override
  State<TasbeehListScreen> createState() => _TasbeehListScreenState();
}

class _TasbeehListScreenState extends State<TasbeehListScreen> {
  List<Map<String, dynamic>> _zikars = [
    {"name": "SubhanAllah", "goal": 33, "count": 0},
    {"name": "Alhamdulillah", "goal": 33, "count": 0},
    {"name": "Allahu Akbar", "goal": 34, "count": 0},
  ];

  @override
  void initState() {
    super.initState();
    _loadZikars();
  }

  _loadZikars() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('zikar_list');
    if (savedData != null) {
      setState(() {
        _zikars = List<Map<String, dynamic>>.from(json.decode(savedData));
      });
    }
  }

  _saveZikars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('zikar_list', json.encode(_zikars));
  }

  void _addNewZikar() {
    String name = "";
    int goal = 33;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Add New Zikar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Zikar Name", hintText: "e.g. Astaghfirullah"),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Target/Goal"),
              keyboardType: TextInputType.number,
              onChanged: (val) => goal = int.tryParse(val) ?? 33,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                setState(() {
                  _zikars.add({"name": name, "goal": goal, "count": 0});
                });
                _saveZikars();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tasbeeh"), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _zikars.length,
        itemBuilder: (context, index) {
          final zikar = _zikars[index];
          double progress = zikar['count'] / zikar['goal'];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Icon(Icons.track_changes, color: Theme.of(context).primaryColor),
              title: Text(zikar['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: Colors.grey.shade200,
                    color: progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 4),
                  Text("${zikar['count']} / ${zikar['goal']}"),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TasbeehCounterScreen(
                      zikar: zikar,
                      index: index,
                      onUpdate: (newCount) {
                        setState(() {
                          _zikars[index]['count'] = newCount;
                        });
                        _saveZikars();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewZikar,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}