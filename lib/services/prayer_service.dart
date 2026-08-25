import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerService {
  static Future<PrayerTimes?> getPrayerTimes() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check karein ke mobile ka GPS (Location Service) on hai ya nahi
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Agar GPS off hai to user ko settings mein bhejain ya error den
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    // 2. Permission check karein
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // 3. Current Location lein
    // DesiredAccuracy low rakha hai taake battery kam consume ho aur jaldi result aaye
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);

    // 4. Adhan logic (Pakistan/Hanafi settings)
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    return PrayerTimes.today(coordinates, params);
  }
}