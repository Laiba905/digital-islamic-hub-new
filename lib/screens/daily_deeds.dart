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

  // 🔄 Streak Validation Logic (Missed Days Check)
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

        if (differenceInDays > 1) {
          DateTime missedDay = lastUpdateMidnight.add(const Duration(days: 1));
          String missedDayStr = missedDay.toIso8601String().split('T')[0];

          // Check if admin posted deeds on that missed day either via old collection or 30-day program
          QuerySnapshot adminDeedsCheck = await FirebaseFirestore.instance
              .collection('daily_deeds')
              .where('dateStr', isEqualTo: missedDayStr)
              .get();

          if (adminDeedsCheck.docs.isNotEmpty) {
            await userRef.update({
              'streak': 0,
              'completedTodayDate': "",
            });
            debugPrint("Streak Reset to 0 because user missed a day!");
          }
        }
      }
    } catch (e) {
      debugPrint("Error validating streak: $e");
    }
  }

  // 🚀 Submit Streak & Points
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
          const SnackBar(content: Text("MashaAllah! Today's streak has been successfully updated!"), backgroundColor: Colors.green),
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
    final double horizontalPadding = MediaQuery.of(context).size.width > 800 ? 32.0 : 16.0;

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
          Timestamp? createdAt;

          if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
            final data = userSnap.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              displayStreak = data['streak'] ?? 0;
              lastDate = data['completedTodayDate'] ?? "";
              createdAt = data['createdAt'] as Timestamp?;
            }
          }

          bool alreadyDone = (lastDate == todayStr);

          // 🔥 30-Day Program Data Stream Fetching
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('app_content').doc('ramadan_or_deeds_30_days').snapshots(),
            builder: (context, thirtyDaysSnap) {
              List<Map<String, dynamic>> todayDeedsList = [];

              if (thirtyDaysSnap.hasData && thirtyDaysSnap.data != null && thirtyDaysSnap.data!.exists) {
                var data = thirtyDaysSnap.data!.data() as Map<String, dynamic>?;
                if (data != null && data['deeds_list'] != null) {
                  List list = data['deeds_list'];

                  // 🧮 Calculate which Day (1 to 30) belongs to today based on user's registration/start date
                  int currentDayNumber = 1;
                  if (createdAt != null) {
                    DateTime startDate = createdAt.toDate();
                    DateTime now = DateTime.now();
                    int diffDays = DateTime(now.year, now.month, now.day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays;
                    currentDayNumber = (diffDays % 30) + 1; // 30 days complete hone par dobara cycle shuru ho jayegi
                  }

                  // Match current day deed from the 30-day list
                  for (var item in list) {
                    if (item['day'] == currentDayNumber) {
                      todayDeedsList.add({
                        'id': 'day_$currentDayNumber',
                        'title': item['title'] ?? '',
                        'description': item['description'] ?? '',
                        'points': item['points'] ?? 5,
                      });
                    }
                  }
                }
              }

              // Fallback to old single-day collection if 30-day list is empty
              if (todayDeedsList.isEmpty) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('daily_deeds').where('dateStr', isEqualTo: todayStr).snapshots(),
                  builder: (context, fallbackSnap) {
                    if (fallbackSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
                    }
                    var deedsDocs = fallbackSnap.hasData ? fallbackSnap.data!.docs : [];
                    if (deedsDocs.isEmpty) {
                      return const Center(child: Text("No deeds available for today.", style: TextStyle(color: Colors.grey, fontSize: 16)));
                    }

                    List<Map<String, dynamic>> mappedDeeds = deedsDocs.map((doc) {
                      var d = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'title': d['title'] ?? '',
                        'description': '',
                        'points': d['points'] ?? 5,
                      };
                    }).toList();

                    return _buildDeedsContent(context, mappedDeeds, displayStreak, alreadyDone, isDark, horizontalPadding);
                  },
                );
              }

              return _buildDeedsContent(context, todayDeedsList, displayStreak, alreadyDone, isDark, horizontalPadding);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeedsContent(BuildContext context, List<Map<String, dynamic>> deeds, int displayStreak, bool alreadyDone, bool isDark, double horizontalPadding) {
    int totalCalculatedPoints = 0;
    for (var deed in deeds) {
      if (_localTicks.contains(deed['id'])) {
        totalCalculatedPoints += (deed['points'] as num).toInt();
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
                  var deed = deeds[index];
                  String title = deed['title'];
                  String description = deed['description'];
                  String id = deed['id'];
                  int pts = deed['points'];

                  bool ticked = alreadyDone || _localTicks.contains(id);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0.5,
                    color: isDark ? Colors.white.withAlpha(15) : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ticked ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(description, style: TextStyle(color: ticked ? Colors.grey : Colors.black54, fontSize: 13)),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            "+$pts Points",
                            style: TextStyle(color: ticked ? Colors.grey : Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
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