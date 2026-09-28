import 'package:flutter/material.dart';
import 'queries_payments_view.dart';
import 'scholar_requests_view.dart';
import 'manage_scholars_view.dart';
import 'scholar_analytics_view.dart';

class ScholarManagementHubView extends StatelessWidget {
  const ScholarManagementHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholar Hub'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
          child: Center(
            child: Wrap(
              spacing: 32,
              runSpacing: 32,
              alignment: WrapAlignment.center,
              children: [
                _HubCard(
                  title: 'Manage Scholars',
                  subtitle: 'Verify, Block, or Unblock Scholar accounts.',
                  icon: Icons.school_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageScholarsPage(),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Scholar Requests',
                  subtitle: 'New registration requests from scholars.',
                  icon: Icons.person_add_alt_1_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScholarRequestsView(),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Scholar Analytics',
                  subtitle: 'View registration trends and active counts.',
                  icon: Icons.analytics_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScholarAnalyticsView(),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Queries & Payments',
                  subtitle: 'Verify user payments and assign to scholars.',
                  icon: Icons.payments_outlined,
                  iconColor: Colors.amber.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QueriesPaymentsView(),
                      ),
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

class _HubCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth < 500 ? double.infinity : 300,
      height: 250,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  size: 60, 
                  color: iconColor ?? (isDark ? theme.colorScheme.primary : theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  title, 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle, 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
