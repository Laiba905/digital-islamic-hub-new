import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dnd_service.dart'; // Ensure DndService contains enableDnd/disableDnd methods

// --- BACKGROUND SERVICE INITIALIZATION ---
Future<void> initializeBackgroundService() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'masjid_silent_channel',
      initialNotificationTitle: 'Masjid Auto-Silent',
      initialNotificationContent: 'Monitoring geofence location...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    bool isRunning = await FlutterBackgroundService().isRunning();
    if (!isRunning) {
      timer.cancel();
      return;
    }
    debugPrint("Background Geofence Service is running...");
  });
}

// --- MASJID SETTINGS SCREEN ---
class MasjidSettingsScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialMosqueName;

  const MasjidSettingsScreen({
    Key? key,
    this.initialLocation,
    this.initialMosqueName,
  }) : super(key: key);

  @override
  State<MasjidSettingsScreen> createState() => _MasjidSettingsScreenState();
}

class _MasjidSettingsScreenState extends State<MasjidSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  bool _isAutoSilentEnabled = false;
  double _geofenceRadius = 100.0;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialAndSavedData();
  }

  // Local storage aur Firestore se data load karne ka function
  Future<void> _loadInitialAndSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    String? localName = prefs.getString('masjid_name');
    double? localLat = prefs.getDouble('masjid_lat');
    double? localLng = prefs.getDouble('masjid_lng');
    bool? localEnabled = prefs.getBool('auto_silent_enabled');
    double? localRadius = prefs.getDouble('silent_radius');

    setState(() {
      _nameController.text = widget.initialMosqueName ?? localName ?? '';
      _latController.text = widget.initialLocation?.latitude.toString() ??
          (localLat != null ? localLat.toString() : '');
      _lngController.text = widget.initialLocation?.longitude.toString() ??
          (localLng != null ? localLng.toString() : '');

      _isAutoSilentEnabled = localEnabled ?? false;
      _geofenceRadius = localRadius ?? 100.0;
    });

    try {
      DocumentSnapshot doc = await _firestore
          .collection('masjid_settings')
          .doc('default_user')
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (mounted && _nameController.text.isEmpty) {
          setState(() {
            _nameController.text = data['masjid_name'] ?? '';
            _latController.text = data['masjid_lat']?.toString() ?? '';
            _lngController.text = data['masjid_lng']?.toString() ?? '';
            _isAutoSilentEnabled = data['is_auto_silent_enabled'] ?? false;
            _geofenceRadius =
                (data['geofence_radius'] as num?)?.toDouble() ?? 100.0;
          });
        }
      }
    } catch (e) {
      debugPrint("Firestore load error: $e");
    }
  }

  // SAVE DATA & TRIGGER DND FUNCTIONALITY
  Future<void> _saveAllSettings() async {
    // 1. Inputs Validation
    if (_nameController.text.trim().isEmpty ||
        _latController.text.trim().isEmpty ||
        _lngController.text.trim().isEmpty) {
      _showSnackBar("Please fill all details!", Colors.red);
      return;
    }

    double? lat = double.tryParse(_latController.text.trim());
    double? lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      _showSnackBar("Enter valid Latitude and Longitude!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. DND Permission & Activation Logic
      if (_isAutoSilentEnabled) {
        // DND Permission check
        bool isDndPermissionGranted = await DndService.isNotificationPolicyAccessGranted();

        if (!isDndPermissionGranted) {
          _showSnackBar("Please grant Do Not Disturb (DND) permission", Colors.green);
          // User ko DND Settings par bhejein permission ke liye
          await DndService.openNotificationPolicySettings();
          setState(() => _isLoading = false);
          return;
        }

        // Enable DND Mode
        await DndService.enableDnd();
      } else {
        // Disable DND Mode
        await DndService.disableDnd();
      }

      // 3. SharedPreferences local storage save
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('masjid_name', _nameController.text.trim());
      await prefs.setDouble('masjid_lat', lat);
      await prefs.setDouble('masjid_lng', lng);
      await prefs.setBool('auto_silent_enabled', _isAutoSilentEnabled);
      await prefs.setDouble('silent_radius', _geofenceRadius);
      await prefs.setBool('is_settings_saved', true);

      // 4. Firebase Cloud Firestore save
      await _firestore.collection('masjid_settings').doc('default_user').set({
        'masjid_name': _nameController.text.trim(),
        'masjid_lat': lat,
        'masjid_lng': lng,
        'geofence_radius': _geofenceRadius,
        'is_auto_silent_enabled': _isAutoSilentEnabled,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 5. Background Geofence Service Control
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final service = FlutterBackgroundService();
        bool isRunning = await service.isRunning();

        if (_isAutoSilentEnabled) {
          if (!isRunning) await service.startService();
        } else {
          if (isRunning) service.invoke("stopService");
        }
      }

      _showSnackBar(
        _isAutoSilentEnabled
            ? "Settings saved & DND Enabled!"
            : "Settings saved & DND Disabled!",
        const Color(0xFF2E7D32),
      );
    } catch (e) {
      _showSnackBar("Error saving settings: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Masjid Auto-Silent Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mosque Details Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.mosque,
                              size: 32, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Mosque Details",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Masjid Name',
                        hintText: 'e.g. Faisal mosque',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enable Auto-Silent Toggle
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Enable Auto-Silent Mode',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Controls Do Not Disturb based on your location.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAutoSilentEnabled,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (val) {
                        setState(() {
                          _isAutoSilentEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Geofence Radius Slider Card
            if (_isAutoSilentEnabled)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Silent Zone Radius',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Radius:', style: TextStyle(fontSize: 14)),
                          Text(
                            '${_geofenceRadius.round()} meters',
                            style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Slider(
                        value: _geofenceRadius,
                        min: 50,
                        max: 500,
                        divisions: 9,
                        activeColor: const Color(0xFF2E7D32),
                        inactiveColor: Colors.green.shade100,
                        onChanged: (val) {
                          setState(() {
                            _geofenceRadius = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Save Settings Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: _isLoading ? null : _saveAllSettings,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save Settings',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}