import 'dart:async';
import 'package:crapadvisor/providers/facilityName_provider.dart';
import 'package:crapadvisor/screens/feedbackForm.dart';
import 'package:crapadvisor/screens/selectFacility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../annim/transiton.dart';
import '../apis/fetchFacilitiesOfFestival.dart';
import '../models/fetchFacilitiesOfFestival_model.dart';
import '../services/getCustomMarker.dart';

class MapScreen extends StatefulWidget {
  final String festivalId;
  final LatLng intialCameraPosition;
  final festivalLatitude;
  final festivalLongitude;
  late double latitude;
  late double longitude;
  late String what3words;

  MapScreen({
    required this.festivalLatitude,
    required this.festivalLongitude,
    required this.intialCameraPosition,
    required this.festivalId,
    required this.what3words,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  late TextEditingController _what3WordsController;
  Marker? marker = null;
  Set<Marker> markers = {};
  bool isSnackBarVisible = false;
  double buttonPosition = 16;
  Set<Polyline> _gridLines = {};
  BitmapDescriptor? _customMarkerIcon; // Variable to store custom marker icon
  BitmapDescriptor? _fetchedMarkerIcon;
  List<Toilet> toilets = [];
  String _facilitTypeName = "";
  FacilityNameProvider _facilityNameProvider = FacilityNameProvider();
  bool _showLoadingOverlay = true; // Loading overlay state
  bool _showInstructionOverlay = false; // Instruction overlay state


  void fetchToilets() async {
    try {
      List<Toilet>? fetchedToilets =
          await fetchToiletsByFestivalId(widget.festivalId);
      if (fetchedToilets != null) {
        // Do something with the fetched toilets
        setState(() {
          toilets = fetchedToilets;
        });
      } else {
        // Handle case where no toilets are available
        print('No toilets available');
      }
    } catch (e) {
      // Handle error
      print('Error fetching toilets: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _what3WordsController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomMarker();

    _what3WordsController = TextEditingController(text: "${widget.what3words}");

    fetchToilets();

    // Show loading overlay for exactly 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLoadingOverlay = false;
          _showInstructionOverlay = true; // Show instruction after loading
        });
      }
    });
    
    // Hide instruction overlay after 8 seconds
    Future.delayed(const Duration(seconds: 11), () {
      if (mounted) {
        setState(() {
          _showInstructionOverlay = false;
        });
      }
    });
  }

  Set<Marker> _buildToiletMarkers() {
    for (Toilet toilet in toilets) {
      LatLng toiletPosition =
          LatLng(double.parse(toilet.latitude), double.parse(toilet.longitude));
      markers.add(
        Marker(
          markerId: MarkerId(toilet.id),
          position: toiletPosition,
          icon: _fetchedMarkerIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () {
            _facilitTypeName = _facilityNameProvider
                .getFacilityTypeNameById(toilet.toiletTypeId);
            Navigator.push(
              context,
              FadePageRouteBuilder(
                widget: FeedbackScreen(
                  festivalId: toilet.festivalId,
                  toiletId: toilet.id,
                  faciliyName: _facilitTypeName,
                  toiletLat: double.parse(toilet.latitude),
                  toiletLng: double.parse(toilet.longitude),
                  what3words: toilet.what3Words,
                  festivalLatitude:widget.festivalLatitude,
                  festivalLongitude: widget.festivalLongitude,
                )),
            );
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => FeedbackScreen(
            //               festivalId: toilet.festivalId,
            //               toiletId: toilet.id,
            //               faciliyName: _facilitTypeName,
            //               toiletLat: double.parse(toilet.latitude),
            //               toiletLng: double.parse(toilet.longitude),
            //               what3words: toilet.what3Words,
            //           festivalLatitude:widget.festivalLatitude,
            //           festivalLongitude: widget.festivalLongitude,
            //             )));
          },
          // Add other marker customization if needed...
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextFormField(
            controller: _what3WordsController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'what3words address',
              labelStyle: TextStyle(
                fontFamily: "Poppins-Medium",
              ),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => _onMapCreated(controller),
                onCameraMove: _onCameraMove,
                onTap: _onMapTap,
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.intialCameraPosition.latitude,
                      widget.intialCameraPosition.longitude),
                  // Center on London
                  zoom: 20,
                ),
                polylines: _gridLines,
                zoomControlsEnabled: false,
                markers: {
                  ..._buildToiletMarkers(),
                  if (marker != null) marker!
                },
                // markers: marker != null ? Set<Marker>.of([marker!]) : {},
                myLocationButtonEnabled: false,
              ),
              
              // Loading overlay to prevent blue screen flash
              if (_showLoadingOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF45A3D9),
                                  Color(0xFF45D9D0),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Loading What3Words map...",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontFamily: 'Poppins-SemiBold',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Preparing location services and toilet markers",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins-Regular',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A3D9)),
                              strokeWidth: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                               ),
               
               // User Instruction Overlay
               if (_showInstructionOverlay)
                 Positioned(
                   top: MediaQuery.of(context).size.height * 0.15,
                   left: MediaQuery.of(context).size.width * 0.05,
                   right: MediaQuery.of(context).size.width * 0.05,
                   child: Container(
                     padding: EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [
                           Color(0xFF45A3D9).withOpacity(0.95),
                           Color(0xFF45D9D0).withOpacity(0.95),
                         ],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.2),
                           blurRadius: 20,
                           offset: Offset(0, 8),
                         ),
                       ],
                       border: Border.all(
                         color: Colors.white.withOpacity(0.3),
                         width: 1,
                       ),
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Row(
                           children: [
                             Container(
                               padding: EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Icon(
                                 Icons.lightbulb_outline,
                                 color: Colors.white,
                                 size: 24,
                               ),
                             ),
                             SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 "How to post a review",
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 18,
                                   fontWeight: FontWeight.w600,
                                   fontFamily: 'Poppins-SemiBold',
                                 ),
                               ),
                             ),
                             GestureDetector(
                               onTap: () {
                                 setState(() {
                                   _showInstructionOverlay = false;
                                 });
                               },
                               child: Container(
                                 padding: EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.2),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Icon(
                                   Icons.close,
                                   color: Colors.white,
                                   size: 20,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         SizedBox(height: 16),
                         Row(
                           children: [
                             Container(
                               padding: EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Icon(
                                 Icons.location_on,
                                 color: Colors.white,
                                 size: 20,
                               ),
                             ),
                             SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 "Tap on existing toilet markers to review them",
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 14,
                                   fontFamily: 'Poppins-Regular',
                                   height: 1.4,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         SizedBox(height: 12),
                         Row(
                           children: [
                             Container(
                               padding: EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Icon(
                                 Icons.add_location,
                                 color: Colors.white,
                                 size: 20,
                               ),
                             ),
                             SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 "Tap anywhere on the map to add a new toilet location",
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 14,
                                   fontFamily: 'Poppins-Regular',
                                   height: 1.4,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         SizedBox(height: 12),
                         Row(
                           children: [
                             Container(
                               padding: EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Icon(
                                 Icons.rate_review,
                                 color: Colors.white,
                                 size: 20,
                               ),
                             ),
                             SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 "Use the 'Post Review' button to submit your feedback",
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 14,
                                   fontFamily: 'Poppins-Regular',
                                   height: 1.4,
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
               
               AnimatedPositioned(
                 bottom: buttonPosition,
                 left: 0,
                 right: 0,
                 duration: Duration(milliseconds: 300),
                 child: Center(
                   child: Padding(
                     padding: EdgeInsets.only(
                         left: MediaQuery.of(context).size.width * 0.2,
                         right: MediaQuery.of(context).size.width * 0.2),
                     child: Container(
                       width: double.infinity,
                       child: ElevatedButton(
                        onPressed: () {
                          if (marker == null) {
                            setState(() {
                              buttonPosition = 50.0; // Move button upwards when Snackbar is shown
                            });
                            if (!isSnackBarVisible) {
                              isSnackBarVisible = true;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(" Select a position first"),
                                duration: Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'Close',
                                  onPressed: () {
                                    // Hide the SnackBar when the action is pressed
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  },
                                ),
                              ));
                              _resetSnackBarFlagAfterDelay();
                            }
                          } else {
                            Navigator.push(
                              context,
                              FadePageRouteBuilder(
                                widget: SelectFacility(
                                  toiletLat: widget.latitude,
                                  toiletLng: widget.longitude,
                                  festivalid: widget.festivalId,
                                  toiletWhat3words: widget.what3words,
                                  festivalLatitude: widget.festivalLatitude,
                                  festivalLongitude: widget.festivalLongitude,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // Removes padding to allow gradient to fill the button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Keep the round shape
                          ),
                          backgroundColor: Colors.transparent, // Make button background transparent
                          shadowColor: Colors.transparent, // Remove shadow if necessary
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF45A3D9),  // Color at 0%
                                Color(0xFF45D9D0),  // Color at 100%
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20), // Same border radius as the button
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 15.0), // Adjust padding
                            child: Text(
                              "Post Review",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Poppins-Medium",
                              ),
                            ),
                          ),
                        ),
                      ),
                    )

                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _fetchCustomMarker() async {
    try {
      _customMarkerIcon = await getCustomMarker();
      _fetchedMarkerIcon = await getCustomfetchedMarkerIcon();
    } catch (e) {
      print("Error fetching custom marker icon: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;

      if (widget.intialCameraPosition != null) {
        controller.moveCamera(
          CameraUpdate.newLatLngZoom(widget.intialCameraPosition, 20),
        );
      }

    });
  }

  void _onMapTap(LatLng latLng) async {
    String? what3Words =
        await convertToWhat3Words(latLng.latitude, latLng.longitude);
    widget.latitude = latLng.latitude;
    widget.longitude = latLng.longitude;
    setState(() {
      _what3WordsController.text =
          what3Words ?? 'Unable to fetch What3Words address';
      if (marker != null) {
        String markerId =
            '${DateTime.now().millisecondsSinceEpoch}_${latLng.latitude}_${latLng.longitude}';
        marker = Marker(
          markerId: MarkerId(markerId),
          position: latLng,
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        );
      } else {
        marker = Marker(
            markerId: MarkerId("3"),
            position: latLng,
            icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker);
      }
    });
  }

  Future<String?> convertToWhat3Words(double lat, double lng) async {
    const apiKey = 'J78IRDS5';
    final url =
        "https://api.what3words.com/v3/convert-to-3wa?coordinates=$lat%2C$lng&key=$apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      widget.what3words = jsonResponse['words'];
      return jsonResponse['words'];
    } else {
      throw Exception('Failed to get What3Words address');
    }
  }

  Future<LatLng?> convertToCoordinates(String what3words) async {
    const apiKe = 'E1NAKJWV';
    final url =
        "https://api.what3words.com/v3/convert-to-coordinates?words=$what3words&key=$apiKe";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      var lat = jsonResponse['coordinates']['lat'];
      var lng = jsonResponse['coordinates']['lng'];
      return LatLng(double.parse(lat), double.parse(lng));
    } else {
      throw Exception("Failed to convert address to coordinates");
    }
  }

  void _generateGrid(LatLngBounds bounds) {
    final double step =
        0.0001; // This represents the approximate size of a what3words square
    _gridLines.clear();

    // Calculate the number of grid lines needed
    int latLines =
        ((bounds.northeast.latitude - bounds.southwest.latitude) / step).ceil();
    int lngLines =
        ((bounds.northeast.longitude - bounds.southwest.longitude) / step)
            .ceil();

    // Create latitude lines
    for (int i = 0; i <= latLines; i++) {
      double lat = bounds.southwest.latitude + (step * i);
      _gridLines.add(
        Polyline(
          polylineId: PolylineId('lat_$i'),
          points: [
            LatLng(lat, bounds.southwest.longitude),
            LatLng(lat, bounds.northeast.longitude),
          ],
          color: Colors.blue,
          width: 1, // Increased width for visibility at high zoom levels
        ),
      );
    }

    // Create longitude lines
    for (int i = 0; i <= lngLines; i++) {
      double lng = bounds.southwest.longitude + (step * i);
      _gridLines.add(
        Polyline(
          polylineId: PolylineId('lng_$i'),
          points: [
            LatLng(bounds.southwest.latitude, lng),
            LatLng(bounds.northeast.latitude, lng),
          ],
          color: Colors.blue,
          width: 1, // Increased width for visibility at high zoom levels
        ),
      );
    }

    setState(() {});
  }

  void _onCameraMove(CameraPosition position) async {
    if (mapController != null) {
      double zoomLevel = position.zoom;
      if (zoomLevel > 18 && zoomLevel <= 20) {
        LatLngBounds bounds = await mapController!.getVisibleRegion();
        _generateGrid(bounds);
      } else {
        setState(() {
          _gridLines
              .clear(); // Clear grid lines if zoom level is outside the desired range
        });
      }
    }
    setState(() {
        _what3WordsController.clear();
        marker = null;
        widget.latitude = 0.0;
        widget.longitude = 0.0;
        widget.what3words = "";


    });
  }

  void _resetSnackBarFlagAfterDelay() {
    const delay = Duration(seconds: 2);
    Timer(delay, () {
      setState(() {
        isSnackBarVisible = false;
        buttonPosition = 16;
      });
    });
  }
}
