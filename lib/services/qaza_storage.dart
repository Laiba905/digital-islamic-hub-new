import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Har prayer ka Qaza count SharedPreferences mai store/manage karta hai.
class QazaStorage {
  static const List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  /// Har baar count change hone par ye value bump hoti hai. Notification
  /// service (background/foreground) increment karti hai to jo bhi screen
  /// (jaise QazaRecordScreen) is ko sun rahi ho wo turant refresh ho jati hai.
  static final ValueNotifier<int> qazaUpdated = ValueNotifier<int>(0);

  static String _key(String prayer) => 'qaza_count_$prayer';

  /// Agli namaz ke notification mai pichli namaz ke baare mai poochne ke
  /// liye — Fajr se pehli "Isha" hai (pichli raat wali), baqi sab apni
  /// list order wali pichli namaz.
  static String previousPrayer(String currentPrayer) {
    final idx = prayers.indexOf(currentPrayer);
    if (idx <= 0) return prayers.last; // Fajr -> Isha
    return prayers[idx - 1];
  }

  /// Jab user notification mai "No" (namaz nahi parhi) press kare
  static Future<int> incrementQaza(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key(prayer)) ?? 0;
    final updated = current + 1;
    await prefs.setInt(_key(prayer), updated);
    qazaUpdated.value++;
    return updated;
  }

  /// Jab user Qaza screen se manually 1 qaza namaz ada kar le
  static Future<int> decrementQaza(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key(prayer)) ?? 0;
    if (current <= 0) return 0; // 0 se neeche nahi jaega
    final updated = current - 1;
    await prefs.setInt(_key(prayer), updated);
    qazaUpdated.value++;
    return updated;
  }

  static Future<int> getQaza(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(prayer)) ?? 0;
  }

  /// Sab prayers ka record ek sath (Qaza screen ke liye)
  static Future<Map<String, int>> getAllQaza() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final p in prayers) p: prefs.getInt(_key(p)) ?? 0,
    };
  }

  static Future<int> getTotalQaza() async {
    final all = await getAllQaza();
    // Yahan .fold<int> use karne se error khatam ho jayega
    return all.values.fold<int>(0, (sum, v) => sum + v);
  }
}