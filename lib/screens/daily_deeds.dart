import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class DailyDeeds extends StatefulWidget {
  const DailyDeeds({super.key});

  @override
  State<DailyDeeds> createState() => _DailyDeedsState();
}

class _DailyDeedsState extends State<DailyDeeds> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> _fetchTodayDeeds() async {
    try {
      var configDoc = await FirebaseFirestore.instance
          .collection('daily_deeds')
          .doc('program_config')
          .get();

      if (!configDoc.exists || configDoc.data() == null) {
        return _defaultDeedsData();
      }

      var configData = configDoc.data()!;
      Timestamp? startDateTs = configData['startDate'];
      List deedsList = configData['deeds_list'] ?? [];

      if (startDateTs == null || deedsList.isEmpty) {
        return _defaultDeedsData();
      }

      DateTime startDate = startDateTs.toDate();
      DateTime today = DateTime.now();
      int differenceDays = DateTime(today.year, today.month, today.day)
          .difference(DateTime(startDate.year, startDate.month, startDate.day))
          .inDays;

      int currentDayIndex = differenceDays % 30;
      int currentDayNumber = currentDayIndex + 1;

      List dayDeeds = [];
      if (currentDayIndex < deedsList.length) {
        var todayData = deedsList[currentDayIndex];
        dayDeeds = todayData['deeds'] ?? [];
      }

      return {
        'dayNumber': currentDayNumber,
        'deeds': dayDeeds.isNotEmpty ? dayDeeds : _defaultDeedsData()['deeds'],
      };
    } catch (e) {
      return _defaultDeedsData();
    }
  }

  Map<String, dynamic> _defaultDeedsData() {
    return {
      'dayNumber': 1,
      'deeds': [
        {'title': 'Subah ki Sunnah ada karein', 'points': 10},
        {'title': 'Quran ki tilawat karein', 'points': 15},
        {'title': 'Durood Shareef parhein', 'points': 10},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin = screenWidth > 800 ? 32.0 : 15.0;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchTodayDeeds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading deeds", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)));
        }

        var data = snapshot.data ?? {};
        int dayNumber = data['dayNumber'] ?? 1;
        List deeds = data['deeds'] ?? [];

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
              : null,
          builder: (context, userSnap) {
            int currentStreak = 0;
            List completedToday = [];

            if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
              var uData = userSnap.data!.data() as Map<String, dynamic>;
              currentStreak = uData['streak'] ?? 0;
              completedToday = uData['completedToday'] ?? [];
            }

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Daily Sunnah & Deeds (Day $dayNumber)",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black87),
                              ),
                            ],
                          ),
                          Text(
                            "🔥 Streak: $currentStreak",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deeds.length,
                      itemBuilder: (context, index) {
                        var deed = deeds[index];
                        String deedId = "day_${dayNumber}_deed_${index + 1}";
                        String title = deed['title'] ?? 'Deed';
                        int points = deed['points'] ?? 10;
                        bool isCompleted = completedToday.contains(deedId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(13) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted
                                  ? AppTheme.accentGreen.withAlpha(150)
                                  : (isDark ? Colors.white10 : Colors.green.shade50),
                            ),
                          ),
                          child: CheckboxListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: Colors.orange.withAlpha(30),
                              child: Text("+$points",
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)),
                            ),
                            value: isCompleted,
                            activeColor: AppTheme.accentGreen,
                            onChanged: user == null ? null : (bool? value) async {
                              // Sirf local state ya temporary list update karne ke liye (Abhi streak increase nahi hogi)
                              DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
                              var snap = await userRef.get();
                              if (!snap.exists) return;
                              var uData = snap.data() as Map<String, dynamic>;
                              List compToday = List.from(uData['completedToday'] ?? []);

                              if (value == true) {
                                if (!compToday.contains(deedId)) {
                                  compToday.add(deedId);
                                }
                              } else {
                                if (compToday.contains(deedId)) {
                                  compToday.remove(deedId);
                                }
                              }

                              // Sirf checkbox tick hone ka record save hoga, streak button dabane par barhegi
                              await userRef.update({
                                'completedToday': compToday,
                                'lastUpdate': Timestamp.now(),
                              });
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Neechay Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.styleFrom != null ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: user == null ? null : () async {
                          DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
                          var snap = await userRef.get();
                          if (!snap.exists) return;
                          var uData = snap.data() as Map<String, dynamic>;
                          List compToday = List.from(uData['completedToday'] ?? []);
                          int existingStreak = uData['streak'] ?? 0;
                          int currentPoints = uData['totalPoints'] ?? 0;

                          // Check karein ke kya saare tasks pure ho chuke hain?
                          bool allDeedsCompleted = true;
                          int calculatedPoints = 0;

                          for (int i = 0; i < deeds.length; i++) {
                            String dId = "day_${dayNumber}_deed_${i + 1}";
                            int pts = deeds[i]['points'] ?? 10;
                            if (compToday.contains(dId)) {
                              calculatedPoints += pts;
                            } else {
                              allDeedsCompleted = false;
                            }
                          }

                          if (!allDeedsCompleted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please complete all three tasks for today first.!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Agar saare tasks pure hain, tab hi streak barhayen aur points save karein
                          int newStreak = existingStreak == 0 ? 1 : existingStreak + 1;

                          await userRef.update({
                            'totalPoints': currentPoints + 50, // Bonus ya total points calculation
                            'streak': newStreak,
                            'lastUpdate': Timestamp.now(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Congratulations! All of today's deeds have been completed and your streak has increased! 🎉"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text(
                          "Complete Today's Deeds & Boost Streak",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ) : Container(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}