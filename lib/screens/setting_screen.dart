import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dnd_service.dart';

class MasjidSettingsScreen extends StatefulWidget {
  final String? initialMosqueName;

  const MasjidSettingsScreen({
    Key? key,
    this.initialMosqueName,
    required double initialLatitude,
    required double initialLongitude,
  }) : super(key: key);

  @override
  State<MasjidSettingsScreen> createState() => _MasjidSettingsScreenState();
}

class _MasjidSettingsScreenState extends State<MasjidSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();

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
    bool? localEnabled = prefs.getBool('auto_silent_enabled');
    double? localRadius = prefs.getDouble('silent_radius');

    setState(() {
      _nameController.text = localName ?? widget.initialMosqueName ?? '';
      _isAutoSilentEnabled = localEnabled ?? false;
      _geofenceRadius = localRadius ?? 100.0;
    });

    // Firestore se background sync (Cache fallback)
    _fetchFromFirestore();
  }

  Future<void> _fetchFromFirestore() async {
    try {
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
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Please fill the mosque name!", Colors.red);
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
      await prefs.setBool('auto_silent_enabled', _isAutoSilentEnabled);
      await prefs.setDouble('silent_radius', _geofenceRadius);
      await prefs.setBool('is_settings_saved', true);

      // Step C: Firestore Unawaited Async Write (Non-blocking Fast Save)
      _firestore.collection('masjid_settings').doc('user_masjid_config').set({
        'name': _nameController.text.trim(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark Mode Detection & Theme Colors Setup
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;
    final iconBgColor = isDarkMode ? const Color(0xFF1E3A29) : Colors.green.shade50;
    final primaryGreen = isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: backgroundColor,
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
              color: cardColor,
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
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.mosque,
                              size: 32, color: primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Mosque Details",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: InputDecoration(
                        labelText: 'Masjid Name',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        hintText: 'e.g. Faisal mosque',
                        hintStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryGreen, width: 2),
                        ),
                        prefixIcon: Icon(Icons.location_city, color: secondaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: cardColor,
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
                        children: [
                          Text(
                            'Enable Auto-Silent Mode',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enables DND mode for your selected mosque zone',
                            style: TextStyle(color: secondaryTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAutoSilentEnabled,
                      activeColor: primaryGreen,
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
                color: cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Silent Zone Radius',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Radius:',
                              style: TextStyle(fontSize: 14, color: primaryTextColor)),
                          Text(
                            '${_geofenceRadius.round()} meters',
                            style: TextStyle(
                                color: primaryGreen,
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
                        activeColor: primaryGreen,
                        inactiveColor: isDarkMode ? Colors.grey.shade800 : Colors.green.shade100,
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