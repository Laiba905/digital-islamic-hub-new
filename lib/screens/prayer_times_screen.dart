import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';
import 'qaza_namaz_tracker.dart';

class PrayerTime {
  final String name;
  final DateTime time;
  final IconData icon;
  bool notificationOn;

  PrayerTime({
    required this.name,
    required this.time,
    required this.icon,
    this.notificationOn = true,
  });
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Map<String, bool> notificationsActive = {
    "Fajr": false,
    "Dhuhr": false,
    "Asr": false,
    "Maghrib": false,
    "Isha": false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 🚀 FIX: App/Screen open hone par SharedPreferences se saved status sync hoga
  }

  // SharedPreferences se Persistent Notification States Load karna
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      notificationsActive = {
        "Fajr": prefs.getBool("Fajr") ?? false,
        "Dhuhr": prefs.getBool("Dhuhr") ?? false,
        "Asr": prefs.getBool("Asr") ?? false,
        "Maghrib": prefs.getBool("Maghrib") ?? false,
        "Isha": prefs.getBool("Isha") ?? false,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : Colors.white,
      appBar: AppBar(
        title: const Text("Prayer Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF001F1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () => NotificationService.testInstant(),
          )
        ],
      ),
      body: FutureBuilder<PrayerTimes?>(
        future: PrayerService.getPrayerTimes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Connection Error or Location Disabled"));
          }

          final pt = snapshot.data!;
          final zawal = pt.dhuhr.subtract(const Duration(minutes: 10));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildExtraTimesCard(pt.sunrise, zawal, pt.maghrib, isDark),
                const SizedBox(height: 20),
                _prayerTile("Fajr", pt.fajr, Icons.wb_twilight, isDark),
                _prayerTile("Dhuhr", pt.dhuhr, Icons.wb_sunny, isDark),
                _prayerTile("Asr", pt.asr, Icons.cloud_queue, isDark),
                _prayerTile("Maghrib", pt.maghrib, Icons.nightlight_round, isDark),
                _prayerTile("Isha", pt.isha, Icons.dark_mode, isDark),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Qaza Namaz Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QazaRecordScreen()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraTimesCard(DateTime sunrise, DateTime zawal, DateTime sunset, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white24 : Colors.orange.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _extraItem("Sunrise", sunrise, Icons.wb_sunny_outlined, Colors.orange, isDark),
          _extraItem("Zawal", zawal, Icons.warning_amber_rounded, Colors.redAccent, isDark),
          _extraItem("Sunset", sunset, Icons.nights_stay_outlined, Colors.blueGrey, isDark),
        ],
      ),
    );
  }

  Widget _extraItem(String l, DateTime t, IconData i, Color c, bool isDark) {
    return Column(
      children: [
        Icon(i, color: c, size: 20),
        const SizedBox(height: 6),
        Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        Text(DateFormat.jm().format(t), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
      ],
    );
  }

  Widget _prayerTile(String name, DateTime time, IconData icon, bool isDark) {
    bool isNotify = notificationsActive[name] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isNotify ? const Color(0xFF2E7D32) : Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(icon, color: isNotify ? const Color(0xFF2E7D32) : Colors.grey),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(DateFormat.jm().format(time), style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
        trailing: Switch(
          value: isNotify,
          activeColor: const Color(0xFF2E7D32),
          onChanged: (v) async {
            final prefs = await SharedPreferences.getInstance();

            // Local state update aur SharedPreferences save
            setState(() {
              notificationsActive[name] = v;
            });
            await prefs.setBool(name, v);

            // Notification Schedule / Cancel Logic
            if (v) {
              final DateTime now = DateTime.now();
              final DateTime exactTargetTime = DateTime(
                now.year,
                now.month,
                now.day,
                time.hour,
                time.minute,
                0,
              );
              await NotificationService.schedulePrayerNotification(name.hashCode, name, exactTargetTime);
            } else {
              await NotificationService.cancelNotification(name.hashCode);
            }
          },
        ),
      ),
    );
  }
}