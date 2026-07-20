import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

// =========================================================================
// 🚀 MAIN REUSABLE WIDGET: DailyDeeds (Cross-Platform & Responsive)
// =========================================================================

class DailyDeeds extends StatefulWidget {
  final String userId;
  const DailyDeeds({super.key, required this.userId});

  @override
  State<DailyDeeds> createState() => _DailyDeedsState();
}

class _DailyDeedsState extends State<DailyDeeds> {
  bool _isSubmitting = false; // 🔄 Double-tap database lock mechanism
  final Set<String> _localTicks = {}; // 🗂️ Local ticks tracker

  @override
  void initState() {
    super.initState();
    // 🚀 NEW: Screen open hote hi check karo ke user ne kal ka din miss to nahi kiya?
    _validateAndResetMissedStreak();
  }

  // 🔥 NEW FUNCTION: Agar user rozana click nahi karega to streak 0 karne ka logic
  Future<void> _validateAndResetMissedStreak() async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentSnapshot snap = await userRef.get();

      if (snap.exists && snap.data() != null) {
        var data = snap.data() as Map<String, dynamic>;

        // Agar pehle kabhi update hi nahi hua to reset ki zaroorat nahi
        if (data['lastUpdate'] == null) return;

        DateTime lastUpdate = (data['lastUpdate'] as Timestamp).toDate();
        DateTime now = DateTime.now();

        // Aaj aur last update ke darmiyan dino ka farq nikalen
        DateTime todayMidnight = DateTime(now.year, now.month, now.day);
        DateTime lastUpdateMidnight = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
        int differenceInDays = todayMidnight.difference(lastUpdateMidnight).inDays;

        // 🚨 CRITICAL: Agar farq 1 din se zyada hai (yaani kal ka poora din miss ho gaya)
        if (differenceInDays > 1) {
          await userRef.update({
            'streak': 0, // Streak toot gayi, 0 kar do!
            'completedTodayDate': "", // Ticks reset karne ke liye date clear
          });
          debugPrint("Streak Reset to 0 because user missed a day!");
        }
      }
    } catch (e) {
      debugPrint("Error validating streak: $e");
    }
  }

  // 🚀 STREAK METHOD: Atomic update sequence
  void _submitStreak(int pointsCalculated) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      DocumentSnapshot snap = await userRef.get();
      int currentStreak = 0;
      if (snap.exists) {
        currentStreak = (snap.data() as Map<String, dynamic>)['streak'] ?? 0;
      }

      // 🔥 Firestore Atomic Update
      await userRef.update({
        'totalPoints': FieldValue.increment(pointsCalculated),
        'streak': currentStreak + 1,
        'lastUpdate': Timestamp.now(),
        'completedTodayDate': today, // 24-Hour lock stamp
      });

      // Clear local selection after data submission
      setState(() {
        _localTicks.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mashallah! Aaj ki streak update ho gayi! 🔥"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Firebase Write Error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String todayStr = DateTime.now().toIso8601String().split('T')[0];

    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth > 800 ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text("Daily Sunnah & Deeds"),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
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

          bool alreadyDone = (lastDate == todayStr); // 24-Hour system lock active checking

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('daily_deeds').snapshots(),
            builder: (context, deedsSnap) {
              var deeds = deedsSnap.hasData ? deedsSnap.data!.docs : [];
              int listLength = deeds.length > 5 ? deeds.length : 5;

              int totalCalculatedPoints = 0;
              for (var doc in deeds) {
                if (_localTicks.contains(doc.id)) {
                  int pts = (doc.data() as Map<String, dynamic>)['points'] ?? 10;
                  totalCalculatedPoints += pts;
                }
              }

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // 🔥 STREAK BANNER CARD
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 1,
                        color: isDark ? Colors.white10 : Colors.white,
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

                      // 📋 DEEDS LIST VIEW CONTAINER
                      Expanded(
                        child: ListView.builder(
                          itemCount: listLength,
                          itemBuilder: (context, index) {
                            String title = "Daily Sunnah/Deed ${index + 1}";
                            String id = "id_$index";
                            int pts = 10;

                            if (index < deeds.length) {
                              var doc = deeds[index];
                              var data = doc.data() as Map<String, dynamic>;
                              title = data['title'] ?? "Untitled";
                              id = doc.id;
                              pts = (data['points'] as num? ?? 10).toInt();
                            }

                            // 🔄 Dynamic check style trigger: Naye din automatic uncheck ho jayega
                            bool ticked = alreadyDone || _localTicks.contains(id);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0.5,
                              color: isDark ? Colors.white.withAlpha(15) : Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: ticked ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                    decoration: ticked ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "+$pts Points",
                                    style: TextStyle(color: ticked ? Colors.grey : Colors.green, fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ),
                                trailing: GestureDetector(
                                  onTap: alreadyDone ? null : () {
                                    setState(() {
                                      if (_localTicks.contains(id)) {
                                        _localTicks.remove(id);
                                      } else {
                                        _localTicks.add(id);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: ticked ? Colors.green : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: ticked ? Colors.green : Colors.grey, width: 2),
                                    ),
                                    child: ticked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 🔘 SUBMIT BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: alreadyDone ? Colors.grey : const Color(0xFF004D40),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              elevation: 2,
                            ),
                            onPressed: (alreadyDone || _localTicks.isEmpty || _isSubmitting)
                                ? null
                                : () => _submitStreak(totalCalculatedPoints),
                            child: _isSubmitting
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(
                              alreadyDone ? "Streak Updated ✔" : "Update My Streak (Earn +$totalCalculatedPoints Pts)",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}