import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarAnalyticsView extends StatelessWidget {
  const ScholarAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholar Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear All Approved",
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear All Scholars"),
                  content: const Text("Are you sure you want to delete all approved scholars? This action cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete All", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('scholars')
                      .where('status', isEqualTo: 'approved')
                      .get();

                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in querySnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All approved scholars cleared successfully.")),
                    );
                  }
                } catch (e) {
                  debugPrint("Error clearing scholars: $e");
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scholars').where('status', isEqualTo: 'approved').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No approved scholars found.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          final scholars = snapshot.data!.docs;
          int totalApprovedScholars = scholars.length;
          int blockedScholars = scholars.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['accountStatus'] == 'blocked';
          }).length;
          int activeScholars = totalApprovedScholars - blockedScholars;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Scholar Analytics Overview",
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                if (isMobile)
                  Column(
                    children: [
                      _renderAnalyticsCard(context, "Total Approved", totalApprovedScholars.toString(), Colors.blue, Icons.analytics),
                      const SizedBox(height: 12),
                      _renderAnalyticsCard(context, "Active Scholars", activeScholars.toString(), Colors.green, Icons.verified_user_outlined),
                      const SizedBox(height: 12),
                      _renderAnalyticsCard(context, "Blocked Scholars", blockedScholars.toString(), Colors.red, Icons.gpp_bad_outlined),
                    ],
                  )
                else
                  Row(
                    children: [
                      _renderAnalyticsCard(context, "Total Approved", totalApprovedScholars.toString(), Colors.blue, Icons.analytics),
                      const SizedBox(width: 12),
                      _renderAnalyticsCard(context, "Active Scholars", activeScholars.toString(), Colors.green, Icons.verified_user_outlined),
                      const SizedBox(width: 12),
                      _renderAnalyticsCard(context, "Blocked Scholars", blockedScholars.toString(), Colors.red, Icons.gpp_bad_outlined),
                    ],
                  ),

                const SizedBox(height: 40),
                Text(
                  "Visual Statistics (Bar Chart)",
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildBarChartContainer(context, totalApprovedScholars, activeScholars, blockedScholars),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChartContainer(BuildContext context, int total, int active, int blocked) {
    final int maxVal = [total, active, blocked].reduce((curr, next) => curr > next ? curr : next);
    const double chartHeight = 250.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildBar(String label, int value, Color color) {
      final double factor = maxVal == 0 ? 0 : (value / maxVal);
      final double barHeight = (factor * (chartHeight - 60)).clamp(10.0, chartHeight);
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            height: barHeight,
            width: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildBar("Approved", total, Colors.blue),
              buildBar("Active", active, Colors.green),
              buildBar("Blocked", blocked, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Divider(thickness: 1, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _renderLegend(Colors.blue, "Total Approved"),
              _renderLegend(Colors.green, "Active"),
              _renderLegend(Colors.red, "Blocked"),
            ],
          )
        ],
      ),
    );
  }

  Widget _renderLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _renderAnalyticsCard(BuildContext context, String title, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: MediaQuery.of(context).size.width < 800 ? 0 : 1,
      child: Container(
        margin: MediaQuery.of(context).size.width < 800 ? const EdgeInsets.only(bottom: 12) : EdgeInsets.zero,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value, 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              )
            ),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
