import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class DailyDeeds extends StatefulWidget {
  final String userId;
  const DailyDeeds({super.key, required this.userId});

  @override
  State<DailyDeeds> createState() => _DailyDeedsState();
}

class _DailyDeedsState extends State<DailyDeeds> {
  bool _isSubmitting = false;

  // 🔄 30-Day Loop Day Calculator
  Future<int> _getCurrentDayNumber() async {
    try {
      var configDoc = await FirebaseFirestore.instance.collection('daily_deeds').doc('program_config').get();
      if (configDoc.exists && configDoc.data() != null && configDoc.data()!['startDate'] != null) {
        Timestamp startTimestamp = configDoc.data()!['startDate'];
        DateTime startDate = startTimestamp.toDate();
        DateTime now = DateTime.now();

        int differenceInDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(startDate.year, startDate.month, startDate.day))
            .inDays;

        if (differenceInDays < 0) return 1;
        int currentDay = (differenceInDays % 30) + 1;
        return currentDay;
      }
    } catch (e) {
      debugPrint("Error calculating loop day: $e");
    }
    return 1;
  }

  // 📉 Streak Reset Check if user missed a day
  Future<void> _checkAndResetStreakIfNeeded(String todayStr) async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentSnapshot snap = await userRef.get();

      if (snap.exists && snap.data() != null) {
        Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
        String lastUpdateDate = data['completedTodayDate'] ?? "";

        if (lastUpdateDate.isNotEmpty && lastUpdateDate != todayStr) {
          DateTime lastDate = DateTime.parse(lastUpdateDate);
          DateTime today = DateTime.parse(todayStr);
          int diffDays = today.difference(lastDate).inDays;

          if (diffDays > 1) {
            await userRef.update({
              'streak': 0,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error resetting streak: $e");
    }
  }

  // ✅ Fixed Toggle Deed Logic - Streak will ONLY increase when ALL deeds in the list are checked
  Future<void> _toggleDeed(String deedId, bool currentStatus, String todayStr, List<Map<String, dynamic>> deeds, Map<String, dynamic> savedProgress, int currentStreak, bool alreadyDone) async {
    if (alreadyDone || _isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      // Temporary map to calculate progress including current click
      Map<String, dynamic> tempProgress = Map.from(savedProgress);
      bool newDeedStatus = !currentStatus;
      tempProgress[deedId] = newDeedStatus;

      if (deeds.isEmpty) {
        setState(() => _isSubmitting = false);
        return;
      }

      bool allCompletedNow = true;
      int pointsCalculated = 0;

      for (var deed in deeds) {
        String id = deed['id'];
        // Check current clicked status properly against saved progress
        bool isChecked = (id == deedId) ? newDeedStatus : (tempProgress[id] == true);

        if (!isChecked) {
          allCompletedNow = false; // Agar aik bhi deed unchecked hai toh false rahega
        }
        pointsCalculated += (deed['points'] as num).toInt();
      }

      // Save individual deed progress to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('daily_progress')
          .doc(todayStr)
          .set({
        deedId: newDeedStatus,
      }, SetOptions(merge: true));

      // 🚀 Streak barhe gi SIRF TAB jab 'allCompletedNow' true ho (Yani saari deeds tick hon)
      if (allCompletedNow) {
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
        DocumentSnapshot snap = await userRef.get();

        String lastDate = snap.exists ? (snap.data() as Map<String, dynamic>)['completedTodayDate'] ?? "" : "";

        if (lastDate != todayStr) {
          await userRef.update({
            'totalPoints': FieldValue.increment(pointsCalculated),
            'streak': currentStreak + 1,
            'lastUpdate': Timestamp.now(),
            'completedTodayDate': todayStr,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("MashaAllah! All deeds completed, streak increased! 🎉"),
                backgroundColor: AppTheme.primaryLight,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error saving deed status: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double horizontalPadding = MediaQuery.of(context).size.width > 800 ? 32.0 : 16.0;
    String todayDateStr = DateTime.now().toIso8601String().split('T')[0];

    _checkAndResetStreakIfNeeded(todayDateStr);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text("Daily Sunnah & Deeds"),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<int>(
        future: _getCurrentDayNumber(),
        builder: (context, daySnapshot) {
          if (daySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
          }

          int currentDayNumber = daySnapshot.data ?? 1;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
            builder: (context, userSnap) {
              int displayStreak = 0;
              String lastDate = "";

              if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                final data = userSnap.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  displayStreak = data['streak'] ?? 0;
                  lastDate = data['completedTodayDate'] ?? "";
                }
              }

              bool alreadyDone = (lastDate == todayDateStr);

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('daily_progress')
                    .doc(todayDateStr)
                    .snapshots(),
                builder: (context, progressSnap) {
                  Map<String, dynamic> savedProgress = {};
                  if (progressSnap.hasData && progressSnap.data != null && progressSnap.data!.exists) {
                    savedProgress = progressSnap.data!.data() as Map<String, dynamic>? ?? {};
                  }

                  // 🔍 UPDATED QUERY: Fetching deeds matching today's dateStr directly
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('daily_deeds')
                        .where('dateStr', isEqualTo: todayDateStr)
                        .snapshots(),
                    builder: (context, deedsSnap) {
                      if (deedsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
                      }

                      var docs = deedsSnap.hasData ? deedsSnap.data!.docs : [];
                      List<Map<String, dynamic>> todayDeedsList = [];

                      for (var doc in docs) {
                        var d = doc.data() as Map<String, dynamic>;
                        if (doc.id != 'program_config') {
                          todayDeedsList.add({
                            'id': doc.id,
                            'title': d['title'] ?? '',
                            'points': d['points'] ?? 10,
                          });
                        }
                      }

                      if (todayDeedsList.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "No deeds available for today ($todayDateStr). Please publish from admin panel.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              children: [
                                // Program Day Badge
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    "Program Day $currentDayNumber of 30 (Loop Active)",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentGreen),
                                  ),
                                ),
                                // Streak Card
                                Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 1,
                                  color: isDark ? Colors.grey[850] : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 32),
                                        const SizedBox(width: 10),
                                        Text(
                                          "$displayStreak Days Streak",
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: todayDeedsList.length,
                                  itemBuilder: (context, index) {
                                    var deed = todayDeedsList[index];
                                    String title = deed['title'];
                                    String id = deed['id'];
                                    int pts = deed['points'];

                                    bool ticked = alreadyDone || (savedProgress[id] == true);

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0.5,
                                      color: isDark ? Colors.grey[850] : Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentGreen.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "+$pts",
                                                style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: alreadyDone ? null : () {
                                                bool currentStatus = (savedProgress[id] == true);
                                                _toggleDeed(id, currentStatus, todayDateStr, todayDeedsList, savedProgress, displayStreak, alreadyDone);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: ticked ? AppTheme.accentGreen : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: ticked ? AppTheme.accentGreen : Colors.grey, width: 2),
                                                ),
                                                child: ticked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}