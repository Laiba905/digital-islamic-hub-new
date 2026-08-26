import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_islamic_hub_new/screens/setting_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/dnd_service.dart';

// BACKGROUND SERVICE & AUTOMATIC DND LOGIC

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
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!await service.isForegroundService()) {
        timer.cancel();
        return;
      }
    }

    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('masjid_settings')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isEnabled = data['is_auto_silent_enabled'] ?? false;
        double targetLat = (data['masjid_lat'] as num).toDouble();
        double targetLng = (data['masjid_lng'] as num).toDouble();
        double radius = (data['geofence_radius'] as num).toDouble();

        if (isEnabled) {
          Position currentPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );

          double distanceInMeters = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            targetLat,
            targetLng,
          );

          if (distanceInMeters <= radius) {
            await DndService.enableDnd();
            debugPrint("Inside Geofence Zone: DND Enabled automatically");
          } else {
            await DndService.disableDnd();
            debugPrint("Outside Geofence Zone: DND Disabled automatically");
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking location in background: $e");
    }
  });
}

// MAP SCREEN UI
class MasjidMapScreen extends StatefulWidget {
  const MasjidMapScreen({super.key});

  @override
  State<MasjidMapScreen> createState() => _MasjidMapScreenState();
}

class _MasjidMapScreenState extends State<MasjidMapScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedUserLocation;
  final Set<Marker> _markers = {};
  bool _isLoadingCurrentLocation = false;

  final TextEditingController _searchController = TextEditingController();

  static const LatLng _initialPosition = LatLng(33.6844, 73.0479); // Default Islamabad

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Permission Request Handler
  Future<bool> _checkAndRequestPermissions() async {
    if (!await Permission.accessNotificationPolicy.isGranted) {
      await Permission.accessNotificationPolicy.request();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  /// Robust Current Location Retrieval
  Future<void> _getCurrentLocation() async {
    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required.")),
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please turn on GPS/Location services.")),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 10),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
          distanceFilter: 0,
        );
      } else {
        locationSettings = const LocationSettings(accuracy: LocationAccuracy.high);
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).catchError((_) async {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) return lastPos;
        throw Exception("Unable to fix GPS location.");
      });

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      String placeName = "Current Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String name = place.name ?? '';
          String locality = place.locality ?? place.subLocality ?? '';
          placeName = "$name, $locality".trim();
          if (placeName.startsWith(',')) placeName = placeName.substring(1).trim();
        }
      } catch (e) {
        placeName = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      }

      if (!mounted) return;

      setState(() {
        _selectedUserLocation = currentLatLng;
        _searchController.text = placeName.isEmpty ? "Current Location" : placeName;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: currentLatLng,
            infoWindow: InfoWindow(title: placeName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16.5),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  void _searchMasjidByName() async {
    final String searchAddress = _searchController.text.trim();
    await _checkAndRequestPermissions();

    if (!mounted) return;

    if (searchAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Enter The Masjid Name")),
      );
      return;
    }
    try {
      List<Location> locations = await locationFromAddress(searchAddress);
      if (locations.isNotEmpty) {
        final Location targetLoc = locations.first;
        final LatLng foundPoint = LatLng(targetLoc.latitude, targetLoc.longitude);
        setState(() {
          _selectedUserLocation = foundPoint;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('searched_masjid'),
              position: foundPoint,
              infoWindow: InfoWindow(title: searchAddress),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        });
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(foundPoint, 16.0),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Enter A Valid Masjid Name")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Search Masjid",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: (LatLng tappedPoint) async {
              await _checkAndRequestPermissions();
              if (!mounted) return;
              setState(() {
                _selectedUserLocation = tappedPoint;
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: const MarkerId('tapped_masjid'),
                    position: tappedPoint,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
                );
              });
              try {
                List<Placemark> placemarks = await placemarkFromCoordinates(
                  tappedPoint.latitude,
                  tappedPoint.longitude,
                );
                if (placemarks.isNotEmpty && mounted) {
                  setState(() {
                    _searchController.text =
                    "${placemarks.first.name}, ${placemarks.first.locality}";
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _searchController.text =
                    "${tappedPoint.latitude.toStringAsFixed(4)}, ${tappedPoint.longitude.toStringAsFixed(4)}";
                  });
                }
              }
            },
          ),
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Enter Masjid Name (e.g., Faisal Mosque)",
                          border: InputBorder.none,
                          icon: Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                      onPressed: _searchMasjidByName,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            right: 80,
            child: FloatingActionButton.extended(
              heroTag: 'current_location_btn',
              onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
              backgroundColor: const Color(0xFF2E7D32),
              icon: _isLoadingCurrentLocation
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.my_location, color: Colors.white),
              label: const Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            left: 55,
            right: 55,
            child: ElevatedButton(
              onPressed: () async {
                await _checkAndRequestPermissions();

                if (!mounted) return;

                if (_selectedUserLocation != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MasjidSettingsScreen(
                        initialLatitude: _selectedUserLocation!.latitude,
                        initialLongitude: _selectedUserLocation!.longitude,
                        initialMosqueName: _searchController.text.trim().isEmpty
                            ? "Selected Location"
                            : _searchController.text.trim(),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("First select a location or search a valid Masjid name.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 0),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
              ),
              child: const Text(
                "Confirm & Save Location",
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}