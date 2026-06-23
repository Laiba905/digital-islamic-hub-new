import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Map<String, bool> notificationsActive = {};
  Future<PrayerTimes?>? _prayerTimesFuture;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _prayerTimesFuture = PrayerService.getPrayerTimes();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Prayer Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF001F1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: "Test Azan Sound",
              onPressed: () => NotificationService.testInstant()
          )
        ],
      ),
      body: FutureBuilder<PrayerTimes?>(
        future: _prayerTimesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Connection Error or Location Disabled", style: TextStyle(color: Colors.grey)));
          }

          final pt = snapshot.data!;
          final zawal = pt.dhuhr.subtract(const Duration(minutes: 10));

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                // Removed large top padding to fix the "too much space" issue
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    _buildExtraTimesCard(pt.sunrise, zawal, pt.maghrib, isDark),
                    const SizedBox(height: 24),
                    _prayerTile("Fajr", pt.fajr, Icons.wb_twilight_rounded, isDark),
                    _prayerTile("Dhuhr", pt.dhuhr, Icons.wb_sunny_rounded, isDark),
                    _prayerTile("Asr", pt.asr, Icons.cloud_queue_rounded, isDark),
                    _prayerTile("Maghrib", pt.maghrib, Icons.nightlight_round_rounded, isDark),
                    _prayerTile("Isha", pt.isha, Icons.dark_mode_rounded, isDark),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExtraTimesCard(DateTime sunrise, DateTime zawal, DateTime sunset, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.white.withAlpha(20), Colors.white.withAlpha(10)] 
            : [const Color(0xFFFFF3E0), Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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

  Widget _extraItem(String label, DateTime time, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
        Text(DateFormat.jm().format(time), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  Widget _prayerTile(String name, DateTime time, IconData icon, bool isDark) {
    bool isNotify = notificationsActive[name] ?? false;
    final primaryColor = const Color(0xFF2E7D32);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 8),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isNotify ? primaryColor.withAlpha(100) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isNotify ? primaryColor : Colors.grey).withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: isNotify ? primaryColor : Colors.grey, size: 24),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(
          DateFormat.jm().format(time), 
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black45,
            fontWeight: FontWeight.w500,
            fontSize: 14
          )
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: isNotify,
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
            onChanged: (v) async {
              if (v) {
                await NotificationService.requestPermissions();
              }

              final prefs = await SharedPreferences.getInstance();
              setState(() {
                notificationsActive[name] = v;
                prefs.setBool(name, v);
              });

              if (v) {
                final DateTime exactTargetTime = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    time.hour,
                    time.minute,
                    0
                );
                await NotificationService.schedulePrayerNotification(name.hashCode, name, exactTargetTime);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Azan alert enabled for $name"),
                      backgroundColor: primaryColor,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } else {
                await NotificationService.cancelNotification(name.hashCode);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Azan alert disabled for $name"),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
