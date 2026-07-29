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
  final Set<String> _localTicks = {};

  @override
  void initState() {
    super.initState();
    _validateAndResetMissedStreak();
  }

  Future<void> _validateAndResetMissedStreak() async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentSnapshot snap = await userRef.get();

      if (snap.exists && snap.data() != null) {
        var data = snap.data() as Map<String, dynamic>;
        if (data['lastUpdate'] == null) return;

        Timestamp lastUpdateTimestamp = data['lastUpdate'] as Timestamp;
        DateTime lastUpdate = lastUpdateTimestamp.toDate();
        DateTime now = DateTime.now();

        DateTime todayMidnight = DateTime(now.year, now.month, now.day);
        DateTime lastUpdateMidnight = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
        int differenceInDays = todayMidnight.difference(lastUpdateMidnight).inDays;

        // Agar 1 din ya us se zyada ka gap hai, toh check karo ke kya us guzre hue din mein admin ne deeds banaye thay ya nahi
        if (differenceInDays > 1) {
          // Pichle din ki date string nikalte hain jis din user ne miss kiya
          DateTime missedDay = lastUpdateMidnight.add(const Duration(days: 1));
          String missedDayStr = missedDay.toIso8601String().split('T')[0];

          // Check karte hain ke kya us din admin ne koi deeds publish kiye thay
          QuerySnapshot adminDeedsCheck = await FirebaseFirestore.instance
              .collection('daily_deeds')
              .where('dateStr', isEqualTo: missedDayStr)
              .get();

          // Sirf tab streak 0 hogi jab admin ne deeds banaye thay lekin user ne miss kar diye
          if (adminDeedsCheck.docs.isNotEmpty) {
            await userRef.update({
              'streak': 0,
              'completedTodayDate': "",
            });
            debugPrint("Streak Reset to 0 because admin posted deeds, but user missed them!");
          } else {
            debugPrint("Streak Safe! Admin didn't post any deeds on that day.");
          }
        }
      }
    } catch (e) {
      debugPrint("Error validating streak: $e");
    }
  }

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

      await userRef.update({
        'totalPoints': FieldValue.increment(pointsCalculated),
        'streak': currentStreak + 1,
        'lastUpdate': Timestamp.now(),
        'completedTodayDate': today,
      });

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

          bool alreadyDone = (lastDate == todayStr);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_deeds')
                .where('dateStr', isEqualTo: todayStr)
                .snapshots(),
            builder: (context, deedsSnap) {
              if ((!deedsSnap.hasData || deedsSnap.data!.docs.isEmpty)) {
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('daily_deeds')
                      .orderBy('createdAt', descending: true)
                      .limit(10)
                      .get(),
                  builder: (context, fallbackSnap) {
                    if (fallbackSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
                    }

                    var deeds = fallbackSnap.hasData ? fallbackSnap.data!.docs : [];

                    if (deeds.isEmpty) {
                      return const Center(
                        child: Text("No deeds available right now.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      );
                    }

                    String latestDateStr = deeds.first['dateStr'] ?? '';
                    var filteredDeeds = deeds
                        .where((doc) => (doc.data() as Map<String, dynamic>)['dateStr'] == latestDateStr)
                        .toList()
                        .cast<QueryDocumentSnapshot<Object?>>();

                    return _buildDeedsContent(context, filteredDeeds, displayStreak, alreadyDone, isDark, horizontalPadding);
                  },
                );
              }

              var deeds = deedsSnap.data!.docs;
              return _buildDeedsContent(context, deeds, displayStreak, alreadyDone, isDark, horizontalPadding);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeedsContent(BuildContext context, List<QueryDocumentSnapshot<Object?>> deeds, int displayStreak, bool alreadyDone, bool isDark, double horizontalPadding) {
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
            Expanded(
              child: ListView.builder(
                itemCount: deeds.length,
                itemBuilder: (context, index) {
                  var doc = deeds[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String title = data['title'] ?? "Untitled";
                  String id = doc.id;
                  int pts = (data['points'] as num? ?? 10).toInt();

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
  }
}