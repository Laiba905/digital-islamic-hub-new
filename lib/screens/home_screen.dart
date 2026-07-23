import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // 🚀 Added for kIsWeb check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
// 🚀 FIXED: Removed dart:io import entirely to prevent Web crashes

import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import 'prayer_times_screen.dart';
import 'surah_list_screen.dart';
import 'ai_chat_screen.dart';
import 'tasbeeh_list_screen.dart';
import 'profile_screen.dart';
import 'safar_dua_screen.dart';
import 'hadith_books_screen.dart';
import 'bookmarks_screen.dart';
import 'daily_deeds.dart'; // 🚀 DailyDeeds link navigation
// TODO: Create or verify 'books_screen.dart' file exists inside your screens directory
// import 'books_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  // Ayah of the Day States
  String dailyAyah = "Loading Ayah...";
  String dailyUrdu = "";
  String ayahRef = "";
  bool isAyahLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _fetchDailyAyah();
        _checkAndResetStreak();
        _listenForScholarAnswers();
      }
    });
  }

  // 🔥 Live Scholar Answer Listener
  void _listenForScholarAnswers() {
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('targetRole', isEqualTo: 'user')
        .where('targetId', isEqualTo: user!.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((QuerySnapshot snapshot) {

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          String notificationId = change.doc.id;

          String title = data['title'] ?? 'Jawab Alert! ✅';
          String message = data['message'] ?? 'Scholar ne aapke sawal ka jawab de diya hai.';

          _showUserAnswerPopup(title, message, notificationId);
        }
      }
    });
  }

  // 🔥 Khoobsurat PopUp Dialog Box
  void _showUserAnswerPopup(String title, String message, String notificationId) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1A332E) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Color(0xFF2E7D32), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF003D33)
                    )
                ),
              ),
            ],
          ),
          content: Text(
              message,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
                  'isRead': true,
                });
              },
              child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndResetStreak() async {
    if (user == null) return;
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      var snapshot = await userRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['lastUpdate'] == null) {
          await userRef.update({
            'streak': 0,
            'totalPoints': 0,
            'lastUpdate': Timestamp.now(),
            'completedToday': [],
          });
          return;
        }

        DateTime lastUpdate = (data['lastUpdate'] as Timestamp).toDate();
        DateTime now = DateTime.now();
        bool isNewDay = now.year != lastUpdate.year || now.month != lastUpdate.month || now.day != lastUpdate.day;

        if (isNewDay) {
          DateTime yesterday = now.subtract(const Duration(days: 1));
          bool missedADay = lastUpdate.year != yesterday.year || lastUpdate.month != yesterday.month || lastUpdate.day != yesterday.day;
          Map<String, dynamic> updates = {'completedToday': []};
          if (missedADay) updates['streak'] = 0;
          await userRef.update(updates);
          _fetchDailyAyah();
        }
      }
    } catch (e) {
      debugPrint("Streak Error: $e");
    }
  }

  Future<void> _fetchDailyAyah() async {
    if (kIsWeb) {
      setState(() {
        dailyAyah = "إِنَّ مَعَ الْعُسْرِ يُسْرًا";
        dailyUrdu = "Beshak mushkil ke saath asaani hai.";
        ayahRef = "Surah Ash-Sharh 94:6";
        isAyahLoading = false;
      });
      return;
    }

    try {
      var databasesPath = await getDatabasesPath();
      var path = p.join(databasesPath, "quran_final_authentic_v2.db");

      Database db = await openDatabase(path, readOnly: true);
      int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      int ayahId = (dayOfYear % 6236) + 1;

      List<Map> list = await db.rawQuery(
          'SELECT arabic_text, urdu_trans, surah_no, ayah_no FROM quran_data WHERE id = ?',
          [ayahId]);

      if (list.isNotEmpty && mounted) {
        setState(() {
          dailyAyah = list[0]['arabic_text'];
          dailyUrdu = list[0]['urdu_trans'];
          ayahRef = "Surah ${list[0]['surah_no']}:${list[0]['heading_no'] ?? list[0]['ayah_no']}";
          isAyahLoading = false;
        });
      }
      await db.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          dailyAyah = "إِنَّ مَعَ الْعُسْرِ يُسْرًا";
          dailyUrdu = "Beshak mushkil ke saath asaani hai.";
          ayahRef = "Surah Ash-Sharh 94:6";
          isAyahLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabs = [
      _buildHomeDashboardView(),
      const SurahListScreen(),
      const HadithBooksScreen(),
      const BookmarksScreen(),
      const Center(
        child: Text(
            "Islamic Books Hub Coming Soon! 📚",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHomeDashboardView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String userName = user?.displayName ?? "User";
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? [const Color(0xFF003D33), AppTheme.primaryDark] : [const Color(0xFFF1F8E9), Colors.white],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(userName, isDark),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrayerTimesScreen())),
                    child: _buildPrayerCard(isDark),
                  ),
                  const SizedBox(height: 10),
                  _buildGridMenu(isDark),
                  const SizedBox(height: 20),
                  _buildAyahModule(isDark),
                  const SizedBox(height: 12),
                  _buildDeedsModule(isDark),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeedsModule(bool isDark) {
    if (user == null) return const SizedBox();

    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin = screenWidth > 800 ? 32.0 : 15.0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox();
        var userData = userSnap.data!.data() as Map<String, dynamic>;
        int currentStreak = userData['streak'] ?? 0;

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.green.shade50),
              ),
              color: isDark ? Colors.white.withAlpha(13) : Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyDeeds(userId: user!.uid),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Daily Deeds",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white70 : Colors.black87
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "🔥 Streak: $currentStreak",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, size: 13, color: isDark ? Colors.white54 : Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyahModule(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(13) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ayah of the Day", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
              if (!isAyahLoading) Text(ayahRef, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          if (isAyahLoading) const Center(child: CircularProgressIndicator(color: Colors.green))
          else Column(
            children: [
              Text(dailyAyah, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF003D33), height: 1.5)),
              const SizedBox(height: 10),
              Text(dailyUrdu, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54, height: 1.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Assalamu Alaikum,", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
              Text(name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 24)),
            ]),
            _buildAvatar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String? img;
        if (snapshot.hasData && snapshot.data!.exists) {
          img = (snapshot.data!.data() as Map<String, dynamic>?)?['profileImage'];
        }
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: isDark ? Colors.white10 : Colors.green.shade50,
            backgroundImage: (img != null && img.isNotEmpty) ? MemoryImage(base64Decode(img)) : null,
            child: (img == null || img.isEmpty) ? Icon(Icons.person, color: isDark ? Colors.white : Colors.green.shade700) : null,
          ),
        );
      },
    );
  }

  Widget _buildPrayerCard(bool isDark) {
    var hijri = HijriCalendar.now();
    return FutureBuilder<PrayerTimes?>(
      future: PrayerService.getPrayerTimes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        final pt = snapshot.data!;
        Prayer current = pt.currentPrayer();
        Prayer next = pt.nextPrayer() == Prayer.none ? Prayer.fajr : pt.nextPrayer();
        return Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isDark ? [const Color(0xFF004D40), const Color(0xFF002921)] : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text("${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _prayerCol("CURRENT", current.name.toUpperCase(), pt.timeForPrayer(current)),
                  _prayerCol("NEXT", next.name.toUpperCase(), pt.timeForPrayer(next)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _prayerCol(String label, String name, DateTime? time) {
    String formattedTime = time != null ? DateFormat.jm().format(time) : "--:--";
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(formattedTime, style: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 12)),
    ]);
  }

  Widget _buildGridMenu(bool isDark) {
    Color bg = isDark ? Colors.white.withAlpha(13) : Colors.white;
    Color border = isDark ? Colors.white10 : Colors.green.shade50;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _actionBtn("Islamic AI", Icons.smart_toy_rounded, Colors.cyan, isDark, bg, border, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatScreen()))),
          _actionBtn("Tasbeeh", Icons.track_changes, Colors.blueAccent, isDark, bg, border, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TasbeehListScreen()))),
          _actionBtn("Safar Dua", Icons.travel_explore_rounded, Colors.teal, isDark, bg, border, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafarDuaScreen()))),
          // 🌟 Yahan "User Answers" ka card add kar diya gaya hai Safar Dua ke sath
          _actionBtn("User Answers", Icons.question_answer_rounded, Colors.orange, isDark, bg, border, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAnswerScreen()))),
        ],
      ),
    );
  }

  Widget _actionBtn(String t, IconData i, Color c, bool isDark, Color bg, Color b, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: b)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: c, size: 26),
            const SizedBox(height: 6),
            Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF001A12) : Colors.white,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: isDark ? Colors.white38 : Colors.grey.shade400,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Quran"),
        BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: "Hadith"),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: "Bookmarks"),
        BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark_rounded), label: "Books"),
      ],
    );
  }
}

// 🌟 Khali Screen (User Answer Screen)
class UserAnswerScreen extends StatelessWidget {
  const UserAnswerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001A12) : Colors.white,
      appBar: AppBar(
        title: const Text("User Answers"),
        backgroundColor: isDark ? const Color(0xFF003D33) : const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          "",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}