import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MasjidMapScreenState();
}

class _MasjidMapScreenState extends State<MapScreen> {
  // 1. Map ko control karne ke liye controller
  late GoogleMapController _mapController;

  late LatLng _selectedUserLocation;
  // 2. Default location (Aap isay badal sakte hain)
  static const LatLng _initialPosition = LatLng(33.6844, 73.0479);

  // 3. Markers (Pins) store karne ke liye set
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Screen khulne par default marker lagane ke liye
    _markers.add(
      const Marker(
        markerId: MarkerId('default_masjid_pin'),
        position: _initialPosition,
        infoWindow: InfoWindow(
          title: 'Masjid Location',
          snippet: 'Auto-Silencer Target Area',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Map View'),

        backgroundColor: const Color(0xFF2E7D32), // Green color matching your UI
      ),
      body: GoogleMap(
        // Map types: normal, satellite, terrain, hybrid
        mapType: MapType.normal,

        // Shuruati position jahan map khulega
        initialCameraPosition: const CameraPosition(
          target: _initialPosition,
          zoom: 15.0, // Zoom level (1-20)
        ),

        // Markers ko map par dikhane ke liye
        markers: _markers,

        // User ki apni live location ka blue dot dikhane ke liye
        myLocationEnabled: true,
        myLocationButtonEnabled: true,

        // Jab map ready ho jaye to controller save karne ke liye
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },

        // Agar user map par kahin click kare to naya marker lagane ke liye
        onTap: (LatLng latLng) {
          setState(() {
            _markers.clear(); // Purana pin hatane ke liye
            _markers.add(
              Marker(
                markerId: const MarkerId('new_masjid_pin'),
                position: latLng,
                infoWindow: const InfoWindow(title: 'Selected Location'),
              ),
            );
          });
          print("Selected Location: ${latLng.latitude}, ${latLng.longitude}");
        },
      ),
    );
  }
}