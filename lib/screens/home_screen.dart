import 'dart:convert';
import 'dart:io';
import 'dart:math'; // 🚀 Added for Daily Deeds Shuffling Logic
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import 'prayer_times_screen.dart';
import 'surah_list_screen.dart';
import 'ai_chat_screen.dart';
import 'tasbeeh_list_screen.dart';
import 'profile_screen.dart';
import 'safar_dua_screen.dart';

// Nayi Files Ki Imports
import 'hadith_books_screen.dart';
import 'bookmarks_screen.dart';

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
    _fetchDailyAyah();
    _checkAndResetStreak(); // Initializing Streak Logic
  }

  // --- STREAK & DEEDS RESET LOGIC ---

  Future<void> _checkAndResetStreak() async {
    if (user == null) return;

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

      // Strict calendar day comparison to catch exact midnight transitions
      bool isNewDay = now.year != lastUpdate.year ||
          now.month != lastUpdate.month ||
          now.day != lastUpdate.day;

      if (isNewDay) {
        DateTime yesterday = now.subtract(const Duration(days: 1));
        bool missedADay = lastUpdate.year != yesterday.year ||
            lastUpdate.month != yesterday.month ||
            lastUpdate.day != yesterday.day;

        Map<String, dynamic> updates = {
          'completedToday': [], // Uncheck all deeds for the brand new day
        };

        if (missedADay) {
          updates['streak'] = 0; // Reset streak if an entire calendar day was skipped
        }

        await userRef.update(updates);
        _fetchDailyAyah(); // Force update the Ayah of the day as well
      }
    }
  }

  void _handleDeedToggled(String docId, int points, bool isChecked) async {
    if (user == null) return;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);

    if (isChecked) {
      await userRef.update({
        'totalPoints': FieldValue.increment(points),
        'completedToday': FieldValue.arrayUnion([docId]),
        'lastUpdate': Timestamp.now(),
      });

      var snap = await userRef.get();
      List completed = (snap.data() as Map)['completedToday'] ?? [];
      if (completed.length == 1) {
        await userRef.update({'streak': FieldValue.increment(1)});
      }
    } else {
      await userRef.update({
        'totalPoints': FieldValue.increment(-points),
        'completedToday': FieldValue.arrayRemove([docId]),
      });
    }
  }

  // --- QURAN DATABASE LOGIC ---

  Future<void> _fetchDailyAyah() async {
    try {
      var databasesPath = await getDatabasesPath();
      var path = p.join(databasesPath, "quran_final_authentic_v2.db");
      var exists = await databaseExists(path);

      if (!exists) {
        ByteData data = await rootBundle.load(p.join("assets/database", "quran_final_authentic_v2.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      }

      Database db = await openDatabase(path, readOnly: true);
      int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      int ayahId = (dayOfYear % 6236) + 1;

      List<Map> list = await db.rawQuery(
          'SELECT arabic_text, urdu_trans, surah_no, ayah_no FROM quran_data WHERE id = ?',
          [ayahId]);

      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            dailyAyah = list[0]['arabic_text'];
            dailyUrdu = list[0]['urdu_trans'];
            ayahRef = "Surah ${list[0]['surah_no']}:${list[0]['ayah_no']}";
            isAyahLoading = false;
          });
        }
      }
      await db.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          dailyAyah = "Could not load Ayah";
          isAyahLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🚀 Declared inside the build shell to prevent premature InheritedWidget context crash
    final List<Widget> tabs = [
      _buildHomeDashboardView(),
      const SurahListScreen(),
      const HadithBooksScreen(),
      const BookmarksScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // --- SPLIT INTERACTIVE HOME BODY VIEW ---
  Widget _buildHomeDashboardView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String userName = user?.displayName ?? "User";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF003D33), AppTheme.primaryDark]
              : [const Color(0xFFF1F8E9), Colors.white],
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

  // --- UI COMPONENTS ---

  Widget _buildDeedsModule(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox();

        var userData = userSnap.data!.data() as Map<String, dynamic>;
        List completedToday = userData['completedToday'] ?? [];
        int currentStreak = userData['streak'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(13) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
            boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text("Daily Sunnah & Deeds",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("🔥 $currentStreak Days",
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('daily_deeds').snapshots(),
                builder: (context, deedsSnap) {
                  if (!deedsSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));

                  var allDocs = deedsSnap.data!.docs;
                  if (allDocs.isEmpty) return const SizedBox();

                  // 🎯 RANDOMIZATION SEED LOGIC FOR UNIQUE DAILY ITEMS
                  int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
                  Random random = Random(dayOfYear); // Uses stable daily counter as a seed

                  List<QueryDocumentSnapshot> shuffledDeeds = List.from(allDocs);
                  shuffledDeeds.shuffle(random); // Shuffles identically all day long

                  var displayDeeds = shuffledDeeds.take(3).toList(); // Picks top 3 filtered documents safely

                  return Column(
                    children: displayDeeds.map((doc) {
                      bool isDone = completedToday.contains(doc.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(doc['title'], style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                        subtitle: Text("${doc['points']} Points", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        value: isDone,
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (val) => _handleDeedToggled(doc.id, doc['points'], val!),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
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
        boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF81C784), size: 18),
                  const SizedBox(width: 8),
                  Text("Ayah of the Day", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
              if (!isAyahLoading)
                Text(ayahRef, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          if (isAyahLoading)
            const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)))
          else
            Column(
              children: [
                Text(
                  dailyAyah,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF003D33), height: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  dailyUrdu,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54, height: 1.4),
                ),
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
        if (!snapshot.hasData) return const SizedBox(height: 150);
        final pt = snapshot.data!;
        Prayer current = pt.currentPrayer();
        Prayer next = pt.nextPrayer();
        if (next == Prayer.none) next = Prayer.fajr;
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
                  _prayerCol("CURRENT", current.name.toUpperCase(), pt.timeForPrayer(current), isCurrent: true),
                  _prayerCol("NEXT", next.name.toUpperCase(), pt.timeForPrayer(next), isCurrent: false),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _prayerCol(String label, String name, DateTime? time, {required bool isCurrent}) {
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
      onTap: (i) {
        setState(() {
          _selectedIndex = i;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF001A12) : Colors.white,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: isDark ? Colors.white38 : Colors.grey.shade400,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Quran"),
        BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: "Hadith"),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: "Bookmarks"),
      ],
    );
  }
}