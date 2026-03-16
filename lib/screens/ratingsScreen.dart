import 'dart:async';
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

const String _festivalsBaseUrl =
    'https://stagingcrapadvisor.semicolonstech.com/api/getfestival';

class FestivalList extends StatefulWidget {
  const FestivalList({super.key});

  @override
  State<FestivalList> createState() => _FestivalListState();
}

class _FestivalListState extends State<FestivalList> {
  List<Festival> allFestivals = [];
  List<Festival> filteredFestivals = [];
  List<Festival> _searchResultFestivals = [];
  bool _isSearchingApi = false;
  String? _searchErrorApi;
  Timer? _searchDebounce;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showSearchResults = false;
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_dismissKeyboardOnScroll);
    _loadFirstPage();
  }

  void _dismissKeyboardOnScroll() {
    if (_searchFocusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _showSearchResults) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final result = await fetchFestivals(_festivalsBaseUrl, page: 1);
      if (!mounted) return;
      setState(() {
        allFestivals = result.data;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _hasMore = _currentPage < _lastPage;
        _isInitialLoading = false;
      });
      _preloadImagesFromList(allFestivals.take(10).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final result = await fetchFestivals(_festivalsBaseUrl, page: nextPage);
      if (!mounted) return;
      setState(() {
        allFestivals = [...allFestivals, ...result.data];
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _hasMore = _currentPage < _lastPage && result.data.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _preloadImagesFromList(List<Festival> festivals) {
    for (final festival in festivals) {
      if (festival.image.isNotEmpty) {
        final imageUrl =
            'https://stagingcrapadvisor.semicolonstech.com/asset/festivals/${festival.image}';
        precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    }
  }

  // Method to clear cache when needed (e.g., for debugging or memory management)
  static Future<void> clearImageCache() async {
    await FestivalCacheManager().emptyCache();
    print('Festival image cache cleared');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_dismissKeyboardOnScroll);
    _scrollController.dispose();
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
    final query = _searchController.text.trim();
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResultFestivals = [];
        _searchErrorApi = null;
        _showSearchResults = false;
        _isSearching = false;
        _isSearchingApi = false;
      });
      return;
    }
    setState(() {
      _showSearchResults = true;
      _isSearching = true;
    });
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

  void _dismissKeyboardAndSearch() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResultFestivals = [];
      _searchErrorApi = null;
      _isSearching = false;
      _isSearchingApi = false;
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

  Widget _buildListContent() {
    if (_isInitialLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A3D9)),
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                'Error loading festivals',
                style: TextStyle(
                  fontFamily: 'Poppins-SemiBold',
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadFirstPage,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (allFestivals.isEmpty) {
      return Center(
        child: Text(
          'No festivals available',
          style: TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16),
        ),
      );
    }
    final itemCount = allFestivals.length + (_isLoadingMore ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < allFestivals.length) {
          return CustomCard(festival: allFestivals[index]);
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A3D9)),
              ),
            ),
          ),
        );
      },
    );
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
        behavior: HitTestBehavior.deferToChild,
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
              
              // Search Results — compact list, professional UI
              if (_showSearchResults && _searchController.text.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.20,
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
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 28),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A3D9)),
                                    ),
                                  ),
                                ),
                              )
                            : _searchResultFestivals.isNotEmpty
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                                        child: Row(
                                          children: [
                                            Icon(Icons.search, size: 14, color: Color(0xFF45A3D9)),
                                            SizedBox(width: 6),
                                            Text(
                                              'Search results (${_searchResultFestivals.length})',
                                              style: TextStyle(
                                                fontFamily: 'Poppins-SemiBold',
                                                fontSize: 12,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(height: 1),
                                      Flexible(
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
                                                          festival.nameOrganizer ?? festival.description ?? 'Unknown Festival',
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
                                : Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_searchErrorApi != null)
                                            Padding(
                                              padding: EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                _searchErrorApi!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins-Regular',
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF45A3D9).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(50),
                                            ),
                                            child: Icon(
                                              Icons.search_off,
                                              size: 40,
                                              color: Color(0xFF45A3D9),
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'No festivals found',
                                            style: TextStyle(
                                              fontFamily: 'Poppins-SemiBold',
                                              fontSize: 16,
                                              color: Color(0xFF45A3D9),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Try different keywords',
                                            style: TextStyle(
                                              fontFamily: 'Poppins-Regular',
                                              fontSize: 13,
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
              
              // Festival List Content
              Positioned(
                top: _showSearchResults && _searchController.text.isNotEmpty
                    ? MediaQuery.of(context).size.height * 0.65
                    : MediaQuery.of(context).size.height * 0.22,
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildListContent(),
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
