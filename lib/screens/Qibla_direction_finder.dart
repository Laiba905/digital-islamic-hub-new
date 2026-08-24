import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double? _heading = 0;
  double _qiblaDirection = 0;
  double? _latitude;
  double? _longitude;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initCompassAndLocation();
  }

  Future<void> _initCompassAndLocation() async {
    // Location aur Sensor Permissions Request
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.sensors,
    ].request();

    if (statuses[Permission.location]!.isGranted) {
      setState(() => _hasPermission = true);

      // Current Position Get Karein
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _qiblaDirection = _calculateQibla(position.latitude, position.longitude);
      });

      // Stream Compass Data
      FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted) {
          setState(() {
            _heading = event.heading;
          });
        }
      });
    }
  }

  // Qibla Angle Calculation
  double _calculateQibla(double lat, double lng) {
    double kaabaLat = 21.4225;
    double kaabaLng = 39.8262;

    double phiK = kaabaLat * math.pi / 180.0;
    double lambdaK = kaabaLng * math.pi / 180.0;
    double phi = lat * math.pi / 180.0;
    double lambda = lng * math.pi / 180.0;

    double qibla = math.atan2(
      math.sin(lambdaK - lambda),
      math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(lambdaK - lambda),
    );

    return (qibla * 180.0 / math.pi + 360.0) % 360.0;
  }

  // 🔄 Phone ko kis taraf ghumana hai yeh calculate karne ka function
  Map<String, dynamic> _getDirectionGuidance(double heading, double qibla, Color accentColor) {
    // Angle difference (-180 se +180 range mein normalize)
    double diff = (qibla - heading + 540) % 360 - 180;

    if (diff.abs() <= 4) {
      return {

        "text": "Qibla Direction Found",
        "subText": "Your phone direction is pointing towards the Qibla",
        "color": accentColor,
        "isAligned": true,
      };
    } else if (diff > 0) {
      return {
        "text": "Turn the phone to the right",
        "subText": "Turn the phone to the right",
        "color": accentColor,
        "isAligned": false,
      };
    } else {
      return {
        "text": "Turn the phone to the left",
        "subText": "Turn the phone to the left",
        "color": accentColor,
        "isAligned": false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors based on your app's palette
    final Color primaryColor = const Color(0xFF003D33);
    final Color accentColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final Color bgColor = isDark ? const Color(0xFF001210) : const Color(0xFFFBFBFB);
    final Color cardColor = isDark ? const Color(0xFF00211D) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    double heading = _heading ?? 0;
    Map<String, dynamic> guidance = _getDirectionGuidance(heading, _qiblaDirection, accentColor);
    bool isAligned = guidance["isAligned"];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? primaryColor : const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          "Qibla Compass Online",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: !_hasPermission
          ? Center(
        child: Text(
          "Please grant location permissions",
          style: TextStyle(color: textColor),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Status & Dynamic Instruction
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mosque,
                      color: guidance["color"],
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        guidance["text"],
                        style: TextStyle(
                          color: guidance["color"],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  guidance["subText"],
                  style: TextStyle(color: accentColor, fontSize: 12),
                ),
              ],
            ),
          ),

          // Compass UI
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Compass Image (Background)
                  Transform.rotate(
                    angle: (heading * (math.pi / 180) * -1),
                    child: Image.asset(
                      'assets/images/compass.jpg',  // Your compass background image
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Needle Image (Foreground)
                  Transform.rotate(
                    angle: (heading * (math.pi / 180) * -1),
                    child: Image.asset(
                      'assets/images/needle.jpg',  // Your needle image
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Qibla Marker (Small Mosque Icon)
                  Transform.rotate(
                    angle: (_qiblaDirection * (math.pi / 180)),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.mosque_rounded,
                          color: accentColor,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  // Center Dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.tealAccent : Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: const Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}