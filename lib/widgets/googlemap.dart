import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../apis/fetchFestivals.dart';
import '../models/festivalsDetail_model.dart';
import '../services/getuser_location.dart';
import '../services/getCustomMarker.dart';
import 'modalbottamsheet.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({Key? key}) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late GoogleMapController _controller;
  List<Marker> _markers = [];
  List<Festival> festivals = [];
  late Festivals fetchedFestivals;
  BitmapDescriptor? _customMarkerIcon; // Variable to store custom marker icon
  LatLng? userLocation;
  bool _showLoadingOverlay = true; // Loading overlay state
  bool _showInstructionOverlay = false; // Instruction overlay state

  // Search functionality variables
  static const String _festivalsBaseUrl =
      'https://stagingcrapadvisor.semicolonstech.com/api/getfestival';
  TextEditingController _searchController = TextEditingController();
  List<Festival> _filteredFestivals = [];
  List<Festival> _searchResultFestivals = [];
  bool _isSearchingApi = false;
  String? _searchErrorApi;
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _showSearchResults = false;
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupMap();
    _fetchCustomMarker();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);

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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Handle focus changes
    if (!_searchFocusNode.hasFocus) {
      // When search field loses focus, hide results after a short delay
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() {
            _showSearchResults = false;
          });
        }
      });
    } else {
      // When search field gains focus, show results if there's text
      if (_searchController.text.isNotEmpty) {
        setState(() {
          _showSearchResults = true;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResultFestivals = [];
        _searchErrorApi = null;
        _showSearchResults = false;
        _isSearchingApi = false;
      });
      return;
    }
    setState(() => _showSearchResults = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _performSearchApi(query);
    });
  }

  Future<void> _performSearchApi(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearchingApi = true;
      _searchErrorApi = null;
    });
    try {
      final result = await fetchFestivals(_festivalsBaseUrl, page: 1, search: query);
      if (!mounted) return;
      setState(() {
        _searchResultFestivals = result.data;
        _isSearchingApi = false;
        _searchErrorApi = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResultFestivals = [];
        _isSearchingApi = false;
        _searchErrorApi = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Comprehensive keyboard dismissal method
  void _dismissKeyboardAndSearch() {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Clear search and hide results
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResultFestivals = [];
      _searchErrorApi = null;
      _isSearchingApi = false;
    });
  }

  // Handle map tap to dismiss keyboard
  void _onMapTap(LatLng? position) {
    _dismissKeyboardAndSearch();
  }

  // Handle search field tap
  void _onSearchFieldTap() {
    setState(() {
      _showSearchResults = true;
    });
  }

  // Handle keyboard actions
  void _onKeyboardAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.search:
        _onSearchSubmitted(_searchController.text);
        break;
      case TextInputAction.done:
      case TextInputAction.go:
        _dismissKeyboardAndSearch();
        break;
      default:
        _dismissKeyboardAndSearch();
        break;
    }
  }

  // Handle clear button tap
  void _onClearButtonTap() {
    _searchController.clear();
    _dismissKeyboardAndSearch();
  }

  // Handle search field submission
  void _onSearchSubmitted(String value) {
    if (_searchResultFestivals.isNotEmpty) {
      _selectFestival(_searchResultFestivals.first);
    } else {
      _dismissKeyboardAndSearch();
    }
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    if (_searchFocusNode.hasFocus || _showSearchResults) {
      _dismissKeyboardAndSearch();
      return false; // Don't pop the route
    }
    return true; // Allow popping the route
  }

  // Handle system back button (Android)
  void _handleSystemBackButton() {
    if (_searchFocusNode.hasFocus || _showSearchResults) {
      _dismissKeyboardAndSearch();
    }
  }

  String _getCleanFestivalName(Festival festival) {
    final name = festival.nameOrganizer?.trim();
    final description = festival.description?.trim();

    // Return the first non-empty, non-N/A value
    if (name != null &&
        name.isNotEmpty &&
        name.toLowerCase() != 'n/a' &&
        name.toLowerCase() != '-n/a') {
      return name;
    } else if (description != null &&
        description.isNotEmpty &&
        description.toLowerCase() != 'n/a' &&
        description.toLowerCase() != '-n/a') {
      return description;
    } else {
      return 'Unknown Festival';
    }
  }

  String _getCleanFestivalDescription(Festival festival) {
    final description = festival.description?.trim();

    // Return description only if it's not empty and not N/A
    if (description != null &&
        description.isNotEmpty &&
        description.toLowerCase() != 'n/a' &&
        description.toLowerCase() != '-n/a') {
      return description;
    } else {
      return 'No description available';
    }
  }

  void _selectFestival(Festival festival) {
    final double? latitude = double.tryParse(festival.latitude);
    final double? longitude = double.tryParse(festival.longitude);

    if (latitude != null && longitude != null) {
      final LatLng festivalLatLng = LatLng(latitude, longitude);

      // Dismiss keyboard and remove focus efficiently
      _dismissKeyboardAndSearch();

      // Animate camera to the selected festival
      _controller.animateCamera(CameraUpdate.newLatLngZoom(festivalLatLng, 16));

      // Add a special marker for the selected festival (with onTap so bottom sheet opens)
      setState(() {
        // Remove previous selected festival marker
        _markers.removeWhere(
            (marker) => marker.markerId.value == "selectedFestival");

        // Add new selected festival marker
        _markers.add(
          Marker(
            icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
            markerId: MarkerId("selectedFestival"),
            position: festivalLatLng,
            infoWindow: InfoWindow(
              title: _getCleanFestivalName(festival),
              snippet: "Selected Festival",
            ),
            onTap: () => showMarkerInfo(context, festival),
          ),
        );
      });

      // Open bottom sheet when navigating from search (same as tapping a marker)
      showMarkerInfo(context, festival);

      // Show a brief success message (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Navigating to ${_getCleanFestivalName(festival)}',
            style: TextStyle(
              fontFamily: 'Poppins-Medium',
              fontSize: 14,
            ),
          ),
          backgroundColor: Color(0xFF45A3D9),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

// Function to calculate the distance between two points
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
        start.latitude, start.longitude, end.latitude, end.longitude);
  }

// Function to find the nearest festival
  Festival? _findNearestFestival() {
    if (userLocation == null || festivals.isEmpty) return null;

    Festival? nearestFestival;
    double minDistance = double.infinity;

    for (final festival in festivals) {
      // Attempt to parse latitude and longitude safely
      final double? latitude = double.tryParse(festival.latitude);
      final double? longitude = double.tryParse(festival.longitude);

      // Skip if either latitude or longitude is invalid
      if (latitude != null && longitude != null) {
        double distance = _calculateDistance(
          userLocation!,
          LatLng(latitude, longitude),
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestFestival = festival;
        }
      }
    }
    return nearestFestival;
  }

  Future<void> _setupMap() async {
    try {
      final Position position = await getUserLocation();
      userLocation = LatLng(position.latitude, position.longitude);
      final LatLng latLng = LatLng(position.latitude, position.longitude);

      await fetchFestivalsData();

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('userLocation'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Your Current Location'),
            icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
          ),
        );

        for (final festival in festivals) {
          // Attempt to parse latitude and longitude safely
          final double? latitude = double.tryParse(festival.latitude);
          final double? longitude = double.tryParse(festival.longitude);

          // Skip if either latitude or longitude is invalid
          if (latitude != null && longitude != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(festival.id.toString()),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: _getCleanFestivalName(festival),
                ),
                icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
                onTap: () {
                  showMarkerInfo(context, festival);
                },
              ),
            );
          }
        }
      });

      _controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 10));
    } catch (e) {
      print("Error setting up map: $e");
    }
  }

  // Asynchronous operation to fetch custom marker icon
  Future<void> _fetchCustomMarker() async {
    try {
      _customMarkerIcon = await getCustomMarker();
    } catch (e) {
      print("Error fetching custom marker icon: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => _dismissKeyboardAndSearch(),
        child: Stack(
          children: [
            // Full screen map
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              onTap: _onMapTap, // Dismiss keyboard when map is tapped
              initialCameraPosition: CameraPosition(
                target: LatLng(0, 0),
                // Initial value doesn't matter since we update it later
                zoom: 16,
              ),
              markers: Set<Marker>.of(_markers),
              zoomControlsEnabled: false,
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
                            Icons.map,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Discovering amazing festivals around you...",
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
                          "Loading festival locations and details",
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF45A3D9)),
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top section with search bar and nearest button
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  MediaQuery.of(context).size.height * 0.11,
              left: MediaQuery.of(context).size.width * 0.04,
              right: MediaQuery.of(context).size.width * 0.04,
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF45A3D9),
                            Color(0xFF45D9D0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            fontFamily: 'Poppins-Medium',
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: _onSearchSubmitted,
                          onEditingComplete: () =>
                              _onKeyboardAction(TextInputAction.search),
                          decoration: InputDecoration(
                            hintText: 'Search festivals...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontFamily: 'Poppins-Regular',
                              fontSize: 16,
                            ),
                            prefixIcon: Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF45A3D9),
                                    Color(0xFF45D9D0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Container(
                                    margin: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: _onClearButtonTap,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                          onTap: _onSearchFieldTap,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      width:
                          12), // 4px space between search bar and nearest button
                  // Find Nearest Festival Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF45A3D9),
                          Color(0xFF45D9D0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () async {
                          // Dismiss keyboard when finding nearest festival
                          _dismissKeyboardAndSearch();

                          Festival? nearestFestival = _findNearestFestival();
                          if (nearestFestival != null) {
                            LatLng festivalLatLng = LatLng(
                                double.parse(nearestFestival.latitude),
                                double.parse(nearestFestival.longitude));
                            _controller.animateCamera(
                                CameraUpdate.newLatLngZoom(festivalLatLng, 16));
                            setState(() {
                              // Remove previous nearest festival marker
                              _markers.removeWhere((marker) =>
                                  marker.markerId.value == "nearestFestival");

                              _markers.add(
                                Marker(
                                  icon: _customMarkerIcon ??
                                      BitmapDescriptor.defaultMarker,
                                  markerId: MarkerId("nearestFestival"),
                                  position: festivalLatLng,
                                  infoWindow: InfoWindow(
                                      title: _getCleanFestivalName(
                                          nearestFestival)),
                                ),
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_searching,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Nearest",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins-SemiBold',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Results — visible list so user can see results before selecting
            if (_showSearchResults && _searchController.text.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top +
                    MediaQuery.of(context).size.height * 0.16,
                left: MediaQuery.of(context).size.width * 0.04,
                right: MediaQuery.of(context).size.width * 0.04,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF45A3D9).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _isSearchingApi
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A3D9)),
                                  ),
                                ),
                              ),
                            )
                          : _searchResultFestivals.isNotEmpty
                              ? Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, size: 14, color: Color(0xFF45A3D9)),
                                          SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Search results (${_searchResultFestivals.length})',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Poppins-SemiBold',
                                                fontSize: 12,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 1),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: EdgeInsets.symmetric(vertical: 4),
                                        itemCount: _searchResultFestivals.length,
                                        itemBuilder: (context, index) {
                                          final festival = _searchResultFestivals[index];
                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                FocusScope.of(context).unfocus();
                                                _selectFestival(festival);
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFF45A3D9).withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(Icons.festival, color: Color(0xFF45A3D9), size: 14),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        _getCleanFestivalName(festival),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins-Medium',
                                                          fontSize: 13,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                          : SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchErrorApi != null)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          _searchErrorApi!,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Poppins-Regular',
                                            fontSize: 11,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    Icon(
                                      Icons.search_off,
                                      size: 32,
                                      color: Color(0xFF45A3D9),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No festivals found',
                                      style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold',
                                        fontSize: 14,
                                        color: Color(0xFF45A3D9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Try different keywords',
                                      style: TextStyle(
                                        fontFamily: 'Poppins-Regular',
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),

            // User Instruction Overlay
            if (_showInstructionOverlay)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25,
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
                              "How to use the map",
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
                              "Tap on festival markers to view details, ratings, and post reviews",
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
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Use the search bar to find specific festivals",
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
                              Icons.location_searching,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Tap 'Nearest' to find the closest festival to you",
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

            // Current location button
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.09,
              right: MediaQuery.of(context).size.width * 0.05,
              child: ElevatedButton(
                onPressed: () async {
                  // Dismiss keyboard when getting current location
                  _dismissKeyboardAndSearch();

                  getUserLocation().then((locationData) async {
                    if (locationData != null) {
                      print("my location");
                      print(
                          "${locationData.latitude}, ${locationData.longitude}");
                      _markers.add(Marker(
                        icon:
                            _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
                        markerId: MarkerId("currentLocation"),
                        position: LatLng(locationData.latitude ?? 0,
                            locationData.longitude ?? 0),
                        infoWindow: InfoWindow(title: "Your current location"),
                      ));
                      CameraPosition newCameraPosition = CameraPosition(
                        target: LatLng(locationData.latitude ?? 0,
                            locationData.longitude ?? 0),
                        zoom: 14,
                      );
                      GoogleMapController googleMapController =
                          await _controller;
                      googleMapController.animateCamera(
                        CameraUpdate.newCameraPosition(newCameraPosition),
                      );
                      setState(() {}); // Update UI with new marker
                    }
                  }).catchError((error) {
                    print("Error getting location: $error");
                  });
                },
                child: Icon(Icons.my_location_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchFestivalsData() async {
    try {
      fetchedFestivals = await fetchFestivals(
          "https://stagingcrapadvisor.semicolonstech.com/api/getfestival");
      festivals = fetchedFestivals.data;
    } catch (e) {
      print("Error fetching festivals data: $e");
    }
  }
}
