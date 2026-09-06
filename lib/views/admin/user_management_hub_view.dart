import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class UserManagementHubView extends StatelessWidget {
  const UserManagementHubView({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBgColor = isDark ? const Color(0xFF004D40) : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User & Analytics Hub'),
        backgroundColor: isDark ? const Color(0xFF004D40) : Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HubCard(
                title: 'Manage Users',
                subtitle: 'Control user access, block or unblock accounts.',
                icon: Icons.manage_accounts_outlined,
                cardBgColor: cardBgColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageUsersListScreen()),
                  );
                },
              ),
              const SizedBox(width: 32),
              _HubCard(
                title: 'User Analytics',
                subtitle: 'View detailed charts and registration statistics.',
                icon: Icons.analytics_outlined,
                cardBgColor: cardBgColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserAnalyticsDetailScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color cardBgColor;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cardBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 420,
      height: 260,
      child: Card(
        elevation: 2,
        color: cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 50,
                  color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 📋 2. MANAGE USERS LIST SCREEN (Firebase Connection for Block/Unblock)
// =========================================================================
class ManageUsersListScreen extends StatefulWidget {
  const ManageUsersListScreen({super.key});

  @override
  State<ManageUsersListScreen> createState() => _ManageUsersListScreenState();
}

class _ManageUsersListScreenState extends State<ManageUsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _toggleUserStatus(String docId, String currentStatus) async {
    String newStatus = currentStatus == 'blocked' ? 'active' : 'blocked';
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'status': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User account is now $newStatus! 🔐"),
            backgroundColor: newStatus == 'active' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBgColor = isDark ? const Color(0xFF004D40) : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Manage Users Account Control"),
        backgroundColor: isDark ? const Color(0xFF004D40) : Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Registered Users List",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(
                  width: 300,
                  height: 45,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search user by email...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Database mein koi user nahi mila.",
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String email = (data['email'] ?? '').toString().toLowerCase();
                    return email.contains(_searchQuery);
                  }).toList();

                  return Card(
                    color: cardBgColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        String email = data['email'] ?? 'No Email';
                        String status = data['status'] ?? 'active';

                        bool isBlocked = (status == 'blocked');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isBlocked
                                ? Colors.red.shade900.withOpacity(0.3)
                                : (isDark ? Colors.white10 : Colors.green.shade100),
                            child: Icon(
                              isBlocked ? Icons.block : Icons.person_outline,
                              color: isBlocked ? Colors.redAccent : (isDark ? const Color(0xFF81C784) : const Color(0xFF004D40)),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                email,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isBlocked ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBlocked ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isBlocked ? "Blocked" : "Active",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBlocked ? Colors.redAccent : Colors.greenAccent,
                                  ),
                                ),
                              )
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBlocked ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
                            label: Text(isBlocked ? "Unblock Account" : "Block Account"),
                            onPressed: () => _toggleUserStatus(doc.id, status),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 📊 3. USER ANALYTICS SCREEN WITH LIVE BAR CHART
// =========================================================================
class UserAnalyticsDetailScreen extends StatelessWidget {
  const UserAnalyticsDetailScreen({super.key});

  Stream<Map<String, int>> getAnalyticsData() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBgColor = isDark ? const Color(0xFF004D40) : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("User Analytics & Statistics Charts"),
        backgroundColor: isDark ? const Color(0xFF004D40) : Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<Map<String, int>>(
        stream: getAnalyticsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }

          var data = snapshot.data ?? {'total': 0, 'active': 0, 'blocked': 0};

          double calculatedMaxY = (data['total'] ?? 0).toDouble() + 3.0;
          if (calculatedMaxY < 10) calculatedMaxY = 10;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User Analytics Overview",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _buildStaticCard(context, "Total Users", data['total'].toString(), Colors.blue, Icons.people_outline, cardBgColor, isDark),
                    const SizedBox(width: 16),
                    _buildStaticCard(context, "Active Users", data['active'].toString(), Colors.green, Icons.check_circle_outline, cardBgColor, isDark),
                    const SizedBox(width: 16),
                    _buildStaticCard(context, "Blocked Users", data['blocked'].toString(), Colors.red, Icons.block_outlined, cardBgColor, isDark),
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

                Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: calculatedMaxY,
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: data['total']!.toDouble(), color: Colors.blue, width: 35, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: data['active']!.toDouble(), color: Colors.green, width: 35, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: data['blocked']!.toDouble(), color: Colors.red, width: 35, borderRadius: BorderRadius.circular(6))]),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              TextStyle labelStyle = TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              );
                              switch (value.toInt()) {
                                case 0: return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('Total', style: labelStyle));
                                case 1: return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('Active', style: labelStyle));
                                case 2: return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('Blocked', style: labelStyle));
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
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

  Widget _buildStaticCard(BuildContext context, String title, String value, Color color, IconData icon, Color cardBgColor, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}