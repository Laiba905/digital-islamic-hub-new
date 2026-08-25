import 'package:flutter/material.dart';

import '../services/qaza_notification_service.dart';
import '../services/qaza_storage.dart';

class QazaRecordScreen extends StatefulWidget {
  const QazaRecordScreen({super.key});

  @override
  State<QazaRecordScreen> createState() => _QazaRecordScreenState();
}

class _QazaRecordScreenState extends State<QazaRecordScreen> {
  Map<String, int> _record = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await QazaStorage.getAllQaza();
    setState(() {
      _record = data;
      _loading = false;
    });
  }

  Future<void> _decrement(String prayer) async {
    await QazaStorage.decrementQaza(prayer);
    _load();
  }

  Future<void> _increment(String prayer) async {
    await QazaStorage.incrementQaza(prayer);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _record.values.fold(0, (sum, v) => sum + v);

    return Scaffold(
      appBar: AppBar(title: const Text('Qaza Namaz Record')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Qaza Namaz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final prayer in QazaStorage.prayers) _buildRow(prayer),
        ],
      ),
    );
  }

  Widget _buildRow(String prayer) {
    final count = _record[prayer] ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(prayer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('$count Qaza Namaz Remaining'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: count > 0 ? () => _decrement(prayer) : null,
              tooltip: 'Performed a missed prayer.',
            ),
            Text('$count', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _increment(prayer),
              tooltip: 'Add Manually',
            ),
          ],
        ),
      ),
    );
  }
}