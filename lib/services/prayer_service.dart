import 'package:flutter/foundation.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerService {
  static Future<PrayerTimes?> getPrayerTimes() async {
    try {
      // Web par permission check thoda different hota hai
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _getDefaultPrayerTimes();
      }

      if (permission == LocationPermission.deniedForever) return _getDefaultPrayerTimes();

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);

      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;

      return PrayerTimes.today(coordinates, params);
    } catch (e) {
      debugPrint("Location error: $e");
      return _getDefaultPrayerTimes();
    }
  }

  // Fallback data agar GPS kaam na kare (Default: Karachi)
  static PrayerTimes _getDefaultPrayerTimes() {
    final coordinates = Coordinates(24.8607, 67.0011);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    return PrayerTimes.today(coordinates, params);
  }
}
