import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin/view_models/theme_provider.dart';
import 'package:admin/view_models/profile_view_model.dart';
import 'admin_information_screen.dart';
import 'admin_notification_screen.dart';
import 'scholar_management_hub_view.dart';
import 'user_management_hub_view.dart';
import 'send_book_view.dart';
import 'scholar_requests_view.dart';
import 'scholar_answer_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    int crossAxisCount = 1;
    double childAspectRatio = 2.8;

    if (screenWidth > 1400) {
      crossAxisCount = 3;
      childAspectRatio = 2.5;
    } else if (screenWidth > 950) {
      crossAxisCount = 2;
      childAspectRatio = 2.4;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.8;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF002419) : const Color(0xFFF8FAFB),
      drawer: isMobile ? const Drawer(child: _Sidebar()) : null,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            if (!isMobile) const _Sidebar(),
            Expanded(
              child: Column(
                children: [
                  _TopHeader(scaffoldKey: _scaffoldKey, isMobile: isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Admin Control Panel",
                              style: TextStyle(
                                  fontSize: isMobile ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87
                              )
                          ),
                          SizedBox(height: isMobile ? 20 : 32),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dashboardModulesConfig.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: isMobile ? 16 : 24,
                              mainAxisSpacing: isMobile ? 16 : 24,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemBuilder: (context, index) {
                              final module = dashboardModulesConfig[index];
                              return _ModuleCard(
                                title: module.title,
                                subtitle: module.subtitle,
                                icon: module.icon,
                                iconColor: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                                backgroundColor: isDark ? const Color(0xFF004D40) : const Color(0xFFE8F5E9),
                                spacingAfter: module.spacingAfter,
                                onTap: () {
                                  if (module.route == '/scholar_hub') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ScholarManagementHubView()),
                                    );
                                  } else if (module.route == '/user_hub') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const UserManagementHubView()),
                                    );
                                  } else if (module.route == '/scholar_answer') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ScholarAnswerView(),
                                      ),
                                    );
                                  } else if (module.route == '/book_send') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SendBookView(),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushNamed(context, module.route);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double spacingAfter;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.spacingAfter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacingAfter),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark ? Colors.white70 : Colors.grey,
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

class _Sidebar extends StatelessWidget {
  const _Sidebar();
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profileVM = Provider.of<ProfileViewModel>(context);
    return Container(
      width: 270,
      color: isDark ? const Color(0xFF004D40) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Panel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40))),
          const SizedBox(height: 40),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isActive: true,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _SidebarItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin Information',
              isActive: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminInformationScreen()),
                );
              }
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF002419), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 14,
                      backgroundImage: profileVM.profileImageUrl != null ? NetworkImage(profileVM.profileImageUrl!) : null,
                      child: profileVM.profileImageUrl == null ? const Icon(Icons.person, color: Colors.white, size: 14) : null
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        profileVM.adminName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        overflow: TextOverflow.ellipsis
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isActive ? (isDark ? const Color(0xFF81C784) : const Color(0xFF004D40)) : Colors.grey),
        title: Text(
            label,
            style: TextStyle(
                color: isActive ? (isDark ? const Color(0xFF81C784) : const Color(0xFF004D40)) : Colors.grey,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal
            )
        ),
        dense: true
    );
  }
}

class _TopHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isMobile;

  const _TopHeader({required this.scaffoldKey, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final profileVM = Provider.of<ProfileViewModel>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      height: 70,
      color: isDark ? const Color(0xFF004D40) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),

          const Spacer(),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('targetRole', isEqualTo: 'admin')
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final isRead = data['isRead'] ?? false;

                  if (isRead == true) return false;
                  if (title.contains('submitted successfully')) return false;
                  return true;
                }).length;
              }

              final Color bellColor = unreadCount > 0 ? Colors.red : (isDark ? const Color(0xFF81C784) : Colors.teal);

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      unreadCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                      size: 24,
                      color: bellColor,
                    ),
                    tooltip: "Notifications",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminNotificationScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),

          IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 22, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => themeProvider.toggleTheme(!isDark)
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Row(
              children: [
                if (!isMobile)
                  Text(
                      profileVM.adminName,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87)
                  ),
                const SizedBox(width: 12),
                CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF002419),
                    backgroundImage: profileVM.profileImageUrl != null ? NetworkImage(profileVM.profileImageUrl!) : null,
                    child: profileVM.profileImageUrl == null ? const Icon(Icons.person, color: Colors.white, size: 18) : null
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String route;
  final double spacingAfter;

  const DashboardModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.route,
    this.spacingAfter = 12.0,
  });
}

final List<DashboardModule> dashboardModulesConfig = [
  const DashboardModule(
    title: 'Manage User',
    subtitle: 'Monitor and manage active system users.',
    icon: Icons.people_outline,
    iconColor: Color(0xFF004D40),
    backgroundColor: Color(0xFFE8F5E9),
    route: '/user_hub',
    spacingAfter: 8.0,
  ),
  const DashboardModule(
    title: 'Manage Scholar',
    subtitle: 'Review scholar registrations and profiles.',
    icon: Icons.school_outlined,
    iconColor: Color(0xFF004D40),
    backgroundColor: Color(0xFFE8F5E9),
    route: '/scholar_hub',
    spacingAfter: 8.0,
  ),
  const DashboardModule(
    title: 'Manage Sunnah and Deeds',
    subtitle: 'Update daily Sunnah library and activities.',
    icon: Icons.auto_stories_outlined,
    iconColor: Color(0xFF004D40),
    backgroundColor: Color(0xFFE8F5E9),
    route: '/sunnah_deeds',
    spacingAfter: 8.0,
  ),
  const DashboardModule(
    title: 'Scholar Answer',
    subtitle: 'Receive a scholar answer.',
    icon: Icons.forum_outlined,
    iconColor: Color(0xFF004D40),
    backgroundColor: Color(0xFFE8F5E9),
    route: '/scholar_answer',
    spacingAfter: 8.0,
  ),
  const DashboardModule(
    title: 'Book send',
    subtitle: 'Send a book to the user.',
    icon: Icons.book_outlined,
    iconColor: Color(0xFF004D40),
    backgroundColor: Color(0xFFE8F5E9),
    route: '/book_send',
    spacingAfter: 8.0,
  ),
];