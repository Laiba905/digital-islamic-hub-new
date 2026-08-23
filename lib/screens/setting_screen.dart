import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dnd_service.dart';

class MasjidSettingsScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialMosqueName;

  const MasjidSettingsScreen({
    Key? key,
    this.initialLocation,
    this.initialMosqueName,
    required double initialLatitude,
    required double initialLongitude,
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
    _loadSavedData();
  }

  // 1. SharedPreferences + Firestore se Fast Data Load
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Pehle SharedPreferences se fast load karein (Instant UI render)
    String? localName = prefs.getString('masjid_name');
    double? localLat = prefs.getDouble('masjid_lat');
    double? localLng = prefs.getDouble('masjid_lng');
    bool? localEnabled = prefs.getBool('auto_silent_enabled');
    double? localRadius = prefs.getDouble('silent_radius');

    setState(() {
      _nameController.text = localName ?? widget.initialMosqueName ?? '';
      _latController.text = localLat != null
          ? localLat.toString()
          : (widget.initialLocation?.latitude.toString() ?? '');
      _lngController.text = localLng != null
          ? localLng.toString()
          : (widget.initialLocation?.longitude.toString() ?? '');

      _isAutoSilentEnabled = localEnabled ?? false;
      _geofenceRadius = localRadius ?? 100.0;
    });

    // Firestore se background sync (Cache fallback)
    _fetchFromFirestore();
  }

  Future<void> _fetchFromFirestore() async {
    try {
      // Document ID aap apni zaroorat ke mutabiq dynamic rakh sakte hain (e.g., userId)
      DocumentSnapshot doc = await _firestore
          .collection('masjid_settings')
          .doc('user_masjid_config')
          .get(const GetOptions(source: Source.cache)); // Direct cache check for high speed

      if (!doc.exists) {
        doc = await _firestore
            .collection('masjid_settings')
            .doc('user_masjid_config')
            .get();
      }

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          if (_nameController.text.isEmpty) _nameController.text = data['name'] ?? '';
          if (_latController.text.isEmpty) _latController.text = data['lat']?.toString() ?? '';
          if (_lngController.text.isEmpty) _lngController.text = data['lng']?.toString() ?? '';
          _isAutoSilentEnabled = data['auto_silent'] ?? _isAutoSilentEnabled;
          _geofenceRadius = (data['radius'] as num?)?.toDouble() ?? _geofenceRadius;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Firestore data: $e");
    }
  }

  // 2. Optimized Data Save Function
  Future<void> _saveAllSettings() async {
    if (_nameController.text.trim().isEmpty ||
        _latController.text.trim().isEmpty ||
        _lngController.text.trim().isEmpty) {
      _showSnackBar("Please fill all mosque details!", Colors.red);
      return;
    }

    double? lat = double.tryParse(_latController.text.trim());
    double? lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      _showSnackBar("Please enter valid Latitude & Longitude!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step A: DND Trigger
      bool dndSuccess = _isAutoSilentEnabled
          ? await DndService.enableDnd()
          : await DndService.disableDnd();

      if (!dndSuccess && _isAutoSilentEnabled) {
        _showSnackBar(
          "Please allow DND Permission in System Settings first.",
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Step B: SharedPreferences me Instant Save (Offline-First Approach)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('masjid_name', _nameController.text.trim());
      await prefs.setDouble('masjid_lat', lat);
      await prefs.setDouble('masjid_lng', lng);
      await prefs.setBool('auto_silent_enabled', _isAutoSilentEnabled);
      await prefs.setDouble('silent_radius', _geofenceRadius);
      await prefs.setBool('is_settings_saved', true);

      // Step C: Firestore Unawaited Async Write (Non-blocking Fast Save)
      _firestore.collection('masjid_settings').doc('user_masjid_config').set({
        'name': _nameController.text.trim(),
        'lat': lat,
        'lng': lng,
        'auto_silent': _isAutoSilentEnabled,
        'radius': _geofenceRadius,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((error) {
        debugPrint("Firestore Sync Error: $error");
      });

      _showSnackBar(
        _isAutoSilentEnabled
            ? "Settings saved & DND Enabled successfully!"
            : "Settings saved & DND Disabled!",
        const Color(0xFF2E7D32),
      );
    } catch (e) {
      _showSnackBar("Failed to save settings: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
      ),
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                            'Enables DND mode for your selected mosque zone',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAutoSilentEnabled,
                      activeThumbColor: const Color(0xFF2E7D32),
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
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
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