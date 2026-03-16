import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/getCustomMarker.dart'; // Make sure this function returns a BitmapDescriptor

class ToiletNavigationMap extends StatefulWidget {
  final double latitude;
  final double longitude;


  ToiletNavigationMap({
    required this.latitude,
    required this.longitude,
  });

  @override
  _ToiletNavigationMapState createState() => _ToiletNavigationMapState();
}

class _ToiletNavigationMapState extends State<ToiletNavigationMap> {
  late GoogleMapController mapController;

  // Marker
  Set<Marker> _markers = {};
  BitmapDescriptor? _customMarkerIcon; // Variable to store custom marker icon

  @override
  void initState() {
    super.initState();
    _fetchCustomMarker();
  }

  Future<void> _fetchCustomMarker() async {
    try {
      // Load the custom marker icon
      _customMarkerIcon = await getCustomMarker();

      // After the icon is loaded, add the marker
      _addMarker();
    } catch (e) {
      print("Error fetching custom marker icon: $e");
      // If there's an error, use the default marker
      _customMarkerIcon = BitmapDescriptor.defaultMarker;
      _addMarker();
    }
  }

  void _addMarker() {
    // Clear existing markers if any
    _markers.clear();

    // Add a marker at the specified location with the custom icon
    _markers.add(
      Marker(
        icon: _customMarkerIcon!,
        markerId: MarkerId('toiletLocation'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: 'Toilet Location'),
      ),
    );

    // Update the UI
    setState(() {});
  }

  // Function to open Google Maps Navigation
  Future<void> _openGoogleNavigation() async {
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Could not launch the URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Navigation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(...) is commented out
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80, // Custom app bar height
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                // Applying linear gradient
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF45A3D9), // Color at 0% stop
                    Color(0xFF45D9D0), // Color at 100% stop
                  ],
                  begin: Alignment.topLeft, // Start gradient from top left
                  end: Alignment.bottomRight, // End gradient at bottom right
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30), // Right-side circular corner
                  bottomRight: Radius.circular(30), // Right-side circular corner
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Back button (automatically imply leading behavior)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Go back to previous screen
                        },
                      ),
                    ),
                    // Center Title

                  ],
                ),
              ),
            ),
          ),

          // Google Map placed under the custom app bar
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: GoogleMap(
              zoomControlsEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
          ),

          // Navigation Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _openGoogleNavigation,
              label: Text(
                'Navigate',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(
                Icons.navigation,
                color: Colors.white,
              ),
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
