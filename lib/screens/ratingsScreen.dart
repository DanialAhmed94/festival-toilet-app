import 'package:crapadvisor/screens/reviewsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../annim/transiton.dart';
import '../apis/fetchFestivals.dart';
import '../models/festivalsDetail_model.dart';
import '../services/getFestivalAddress.dart';

// Custom cache manager for festival images
class FestivalCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'festivalCache';
  
  static FestivalCacheManager? _instance;
  factory FestivalCacheManager() {
    _instance ??= FestivalCacheManager._();
    return _instance!;
  }
  
  FestivalCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 100, // Store up to 100 images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class FestivalList extends StatefulWidget {
  const FestivalList({super.key});

  @override
  State<FestivalList> createState() => _FestivalListState();
}

class _FestivalListState extends State<FestivalList> {
  late Future<List<Festival>> futureFestivals;
  List<Festival> allFestivals = [];
  List<Festival> filteredFestivals = [];
  
  // Search functionality variables
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showSearchResults = false;
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    futureFestivals = fetchFestivalsData();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    
    // Preload images for better performance
    _preloadImages();
  }

  void _preloadImages() async {
    try {
      final festivals = await futureFestivals;
      for (final festival in festivals.take(10)) { // Preload first 10 images
        if (festival.image != null && festival.image!.isNotEmpty) {
          final imageUrl = "https://stagingcrapadvisor.semicolonstech.com/asset/festivals/${festival.image}";
          precacheImage(CachedNetworkImageProvider(imageUrl), context);
        }
      }
    } catch (e) {
      print('Error preloading images: $e');
    }
  }

  // Method to clear cache when needed (e.g., for debugging or memory management)
  static Future<void> clearImageCache() async {
    await FestivalCacheManager().emptyCache();
    print('Festival image cache cleared');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() {
            _showSearchResults = false;
          });
        }
      });
    } else {
      if (_searchController.text.isNotEmpty) {
        setState(() {
          _showSearchResults = true;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        filteredFestivals = [];
        _showSearchResults = false;
        _isSearching = false;
      });
    } else {
      _filterFestivals(_searchController.text);
    }
  }

  void _filterFestivals(String query) {
    setState(() {
      filteredFestivals = allFestivals.where((festival) {
        final name = festival.nameOrganizer?.toLowerCase() ?? '';
        final description = festival.description?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
      _showSearchResults = true;
      _isSearching = true;
    });
  }

  void _dismissKeyboardAndSearch() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      filteredFestivals = [];
      _isSearching = false;
    });
  }

  void _onSearchFieldTap() {
    setState(() {
      _showSearchResults = true;
    });
  }

  void _onClearButtonTap() {
    _searchController.clear();
    _dismissKeyboardAndSearch();
  }

  void _onSearchSubmitted(String value) {
    if (filteredFestivals.isNotEmpty) {
      // Select the first result
      _selectFestival(filteredFestivals.first);
    } else {
      _dismissKeyboardAndSearch();
    }
  }

  void _selectFestival(Festival festival) {
    _dismissKeyboardAndSearch();
    Navigator.push(
      context,
      FadePageRouteBuilder(
        widget: Reviews(
          festival_id: festival.id.toString(),
          festivalLocation: LatLng(double.parse(festival.latitude),
              double.parse(festival.longitude)),
        ),
      ),
    );
  }

  Future<List<Festival>> fetchFestivalsData() async {
    try {
      Festivals fetchedFestivals = await fetchFestivals(
          "https://stagingcrapadvisor.semicolonstech.com/api/getfestival");
      return fetchedFestivals.data;
    } catch (e) {
      throw Exception("Error fetching festivals data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_searchFocusNode.hasFocus || _showSearchResults) {
          _dismissKeyboardAndSearch();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () => _dismissKeyboardAndSearch(),
        child: Scaffold(
          body: Stack(
            children: [
              // Background image
              Container(
                height: MediaQuery.of(context).size.height * 0.8,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/slectFacilityBackground.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Transparent AppBar
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                toolbarHeight: 75,
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: SvgPicture.asset(
                    'assets/svgs/back-icon.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  "Festivals",
                  style: TextStyle(
                    fontFamily: "Poppins-Bold",
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                automaticallyImplyLeading: false,
              ),
              
              // Search Bar
              Positioned(
                top: MediaQuery.of(context).size.height * 0.12,
                left: MediaQuery.of(context).size.width * 0.04,
                right: MediaQuery.of(context).size.width * 0.04,
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
                      onEditingComplete: () => _onSearchSubmitted(_searchController.text),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onTap: _onSearchFieldTap,
                    ),
                  ),
                ),
              ),
              
              // Search Results
              if (_showSearchResults && _searchController.text.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.22,
                  left: MediaQuery.of(context).size.width * 0.04,
                  right: MediaQuery.of(context).size.width * 0.04,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Color(0xFF45A3D9).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: filteredFestivals.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredFestivals.length,
                            itemBuilder: (context, index) {
                              final festival = filteredFestivals[index];
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF45A3D9).withOpacity(0.1),
                                      Color(0xFF45D9D0).withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Color(0xFF45A3D9).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      _selectFestival(festival);
                                    },
                                    child: ListTile(
                                      leading: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF45A3D9),
                                              Color(0xFF45D9D0),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.festival,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        festival.nameOrganizer ?? festival.description ?? 'Unknown Festival',
                                        style: TextStyle(
                                          fontFamily: 'Poppins-SemiBold',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF45A3D9),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF45A3D9).withOpacity(0.1),
                                          Color(0xFF45D9D0).withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Color(0xFF45A3D9),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No festivals found',
                                    style: TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 18,
                                      color: Color(0xFF45A3D9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(
                                      fontFamily: 'Poppins-Regular',
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              
              // Festival List Content
              Positioned(
                top: _showSearchResults && _searchController.text.isNotEmpty 
                    ? MediaQuery.of(context).size.height * 0.65
                    : MediaQuery.of(context).size.height * 0.22,
                bottom: 0,
                left: 0,
                right: 0,
                child: FutureBuilder<List<Festival>>(
                  future: futureFestivals,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error}"),
                      );
                    } else if (snapshot.hasData) {
                      List<Festival> festivals = snapshot.data!;
                      // Store festivals for search functionality
                      if (allFestivals.isEmpty) {
                        allFestivals = festivals;
                      }
                      return ListView.builder(
                        itemCount: festivals.length,
                        itemBuilder: (context, index) {
                          return CustomCard(festival: festivals[index]);
                        },
                      );
                    } else {
                      return Center(
                        child: Text("No festivals available"),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatefulWidget {
  final Festival festival;

  CustomCard({required this.festival});

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  late Future<String> festivalAddressFuture;

  @override
  void initState() {
    super.initState();

    final latitude = double.tryParse(widget.festival.latitude);
    final longitude = double.tryParse(widget.festival.longitude);

    if (latitude != null && longitude != null) {
      // Fetch festival address with valid latitude and longitude
      festivalAddressFuture = getFestivalAddress(latitude, longitude);
    } else {
      // Handle the case where parsing failed
      print('Invalid latitude or longitude');
      festivalAddressFuture = Future.error('Invalid latitude or longitude');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 7,
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.all(8),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue, // You can add a color if desired
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: "https://stagingcrapadvisor.semicolonstech.com/asset/festivals/" +
                          widget.festival.image,
                      fit: BoxFit.cover,
                      cacheManager: FestivalCacheManager(),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A3D9)),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Image.asset(
                          "assets/icons/logo.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      memCacheWidth: 200, // Optimize memory usage
                      memCacheHeight: 200,
                      maxWidthDiskCache: 400, // Optimize disk cache
                      maxHeightDiskCache: 400,
                      cacheKey: "festival_${widget.festival.id}_${widget.festival.image}", // Unique cache key
                      fadeInDuration: Duration(milliseconds: 300), // Smooth fade in
                      fadeOutDuration: Duration(milliseconds: 300),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.festival.nameOrganizer ??
                        widget.festival.description

                                ,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Quicksand-Bold",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<String>(
                        future: festivalAddressFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              "Fetching address...",
                              style: TextStyle(
                                  fontFamily: "Quicksand-Medium", fontSize: 11),
                            );
                          } else if (snapshot.hasError) {
                            return Text(
                              "Address not available",
                              style: TextStyle(
                                  fontFamily: "Quicksand-Medium", fontSize: 11),
                            );
                          } else if (snapshot.hasData) {
                            return Text(
                              snapshot.data!,
                              style: TextStyle(
                                  fontFamily: "Quicksand-Medium", fontSize: 11),
                            );
                          } else {
                            return Text(
                              "Address not available",
                              style: TextStyle(
                                  fontFamily: "Quicksand-Medium", fontSize: 11),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            FadePageRouteBuilder(
                widget: Reviews(
              festival_id: widget.festival.id.toString(),
              festivalLocation: LatLng(double.parse(widget.festival.latitude),
                  double.parse(widget.festival.longitude)),
            )),
          );
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => Reviews(
          //               festival_id: widget.festival.id.toString(),
          //               festivalLocation: LatLng(
          //                   double.parse(widget.festival.latitude),
          //                   double.parse(widget.festival.longitude)),
          //             )));
        });
  }
}
