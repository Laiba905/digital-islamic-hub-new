import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UserAnalyticsView extends StatelessWidget {
  const UserAnalyticsView({super.key});

  Stream<Map<String, int>> getAnalyticsData() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
      int active = 0;
      int blocked = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'blocked') {
          blocked++;
        } else {
          active++;
        }
      }

      return {'total': snapshot.docs.length, 'active': active, 'blocked': blocked};
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Analytics"),
      ),
      body: StreamBuilder<Map<String, int>>(
        stream: getAnalyticsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var data = snapshot.data ?? {'total': 0, 'active': 0, 'blocked': 0};

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User Analytics Overview", 
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  )
                ),
                const SizedBox(height: 20),
                
                if (isMobile)
                  Column(
                    children: [
                      _buildStaticCard(context, "Total Users", data['total'].toString(), Colors.blue, Icons.people_outline),
                      const SizedBox(height: 16),
                      _buildStaticCard(context, "Active Users", data['active'].toString(), Colors.green, Icons.check_circle_outline),
                      const SizedBox(height: 16),
                      _buildStaticCard(context, "Blocked Users", data['blocked'].toString(), Colors.red, Icons.block_outlined),
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildStaticCard(context, "Total Users", data['total'].toString(), Colors.blue, Icons.people_outline),
                      const SizedBox(width: 16),
                      _buildStaticCard(context, "Active Users", data['active'].toString(), Colors.green, Icons.check_circle_outline),
                      const SizedBox(width: 16),
                      _buildStaticCard(context, "Blocked Users", data['blocked'].toString(), Colors.red, Icons.block_outlined),
                    ],
                  ),

                const SizedBox(height: 40),
                Text(
                  "Visual Statistics (Bar Chart)", 
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  )
                ),
                const SizedBox(height: 20),

                Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)],
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (data['total']! + 5).toDouble(),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: data['total']!.toDouble(), color: Colors.blue, width: 30, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: data['active']!.toDouble(), color: Colors.green, width: 30, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: data['blocked']!.toDouble(), color: Colors.red, width: 30, borderRadius: BorderRadius.circular(6))]),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final style = TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              );
                              switch (value.toInt()) {
                                case 0: return Text('Total', style: style);
                                case 1: return Text('Active', style: style);
                                case 2: return Text('Blocked', style: style);
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true, 
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 10),
                            ),
                          )
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticCard(BuildContext context, String title, String value, Color color, IconData icon) {
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
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 12)),
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  )
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
