import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarAnalyticsView extends StatelessWidget {
  const ScholarAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Approved Scholar Analytics'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear all approved scholars",
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
      // Yahan .where('status', isEqualTo: 'approved') add kar diya gaya hai
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scholars').where('status', isEqualTo: 'approved').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No approved scholars found yet.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          final scholars = snapshot.data!.docs;

          // 📊 Approved Scholars Metrics Calculation
          int totalApprovedScholars = scholars.length;

          int blockedScholars = scholars.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // Agar aapka account blocking field 'accountStatus' ya 'status' hai uske mutabiq check karein
            return data['accountStatus'] == 'blocked';
          }).length;

          // Active approved scholars woh hain jo block nahi hain
          int activeScholars = totalApprovedScholars - blockedScholars;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Approved System Analytics Insights",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 📈 Top Counters Summary Blocks
                Row(
                  children: [
                    _buildAnalyticsCard("Total Approved", totalApprovedScholars.toString(), Colors.blue, Icons.analytics),
                    const SizedBox(width: 12),
                    _buildAnalyticsCard("Active Scholars", activeScholars.toString(), Colors.green, Icons.verified_user_outlined),
                    const SizedBox(width: 12),
                    _buildAnalyticsCard("Blocked Scholars", blockedScholars.toString(), Colors.red, Icons.gpp_bad_outlined),
                  ],
                ),

                const SizedBox(height: 28),

                // 📊 🌟 VISUAL STATISTICS BAR CHART SECTION
                const Text(
                  "Visual Statistics (Bar Chart)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildMediumBarChart(totalApprovedScholars, activeScholars, blockedScholars),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🛠️ Custom Premium Medium Sized Bar Chart Builder
  Widget _buildMediumBarChart(int total, int active, int blocked) {
    int maxVal = [total, active, blocked].reduce((curr, next) => curr > next ? curr : next);
    double chartHeight = 180.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSingleBar("Approved", total, Colors.blue, chartHeight, maxVal),
              _buildSingleBar("Active", active, Colors.green, chartHeight, maxVal),
              _buildSingleBar("Blocked", blocked, Colors.red, chartHeight, maxVal),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1, color: Colors.black12),
          const SizedBox(height: 4),
          // Chart Legends
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendCircle(Colors.blue, "Total Approved"),
              const SizedBox(width: 16),
              _buildLegendCircle(Colors.green, "Active"),
              const SizedBox(width: 16),
              _buildLegendCircle(Colors.red, "Blocked"),
            ],
          )
        ],
      ),
    );
  }

  // Helper inside chart to render unique status item bar dynamically
  Widget _buildSingleBar(String label, int value, Color barColor, double maxChartHeight, int maximumValue) {
    double factor = maximumValue == 0 ? 0 : (value / maximumValue);
    double calculatedBarHeight = (factor * (maxChartHeight - 40)).clamp(10.0, maxChartHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: barColor),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          height: calculatedBarHeight,
          width: 28,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
      ],
    );
  }

  // Small circle visual label indicators code logic
  Widget _buildLegendCircle(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  // Reusable Helper for Quick Analytics Summary Blocks
  Widget _buildAnalyticsCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}