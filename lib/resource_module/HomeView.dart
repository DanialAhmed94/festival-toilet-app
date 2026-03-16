import 'package:cached_network_image/cached_network_image.dart';
import 'package:crapadvisor/main.dart';
import 'package:crapadvisor/resource_module/apis/logout.dart';
import 'package:crapadvisor/resource_module/apis/deleteAccount_api.dart';
import 'package:crapadvisor/resource_module/providers/refreshNotifier.dart';
import 'package:crapadvisor/resource_module/views/authViews/LoginView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../annim/transiton.dart';
import '../socialMedia/socialpstview.dart';
import 'constants/AppConstants.dart';
import 'providers/festivalProvider.dart';
import 'resourcesViews/resourceHomeView.dart';
import 'utilities/dialogBoxes.dart';
import 'utilities/sharedPrefs.dart';
import 'package:flutter/services.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String? _userName = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<dynamic> allFestivals = [];
  List<dynamic> filteredFestivals = [];

  final List<Color> colors = [
    Color(0xFF015CE9),
    Color(0xFFFF866D),
    Color(0xFF8B5CF6),
  ];

  final List<Color> openColors = [
    Color(0xFFFF866D),
    Color(0xFF015CE9),
    Color(0xFFFF866D),
  ];

  Future<void> _loadProfileData() async {
    final name = await getUserName() ?? "";
    setState(() {
      _userName = name;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FestivalProvider>(context, listen: false)
          .fetchFestivals(context);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      if (notificationProvider.shouldRefreshHome) {
        _fetchFestivalData(context);
        notificationProvider
            .setShouldRefreshHome(false); // Reset flag after refreshing
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    print('Search text changed: "${_searchController.text}"');
    _filterFestivals();
  }

  void _filterFestivals() {
    final query = _searchController.text.toLowerCase();
    final festivalProvider =
        Provider.of<FestivalProvider>(context, listen: false);

    print('Search query: "$query"');
    print(
        'Total festivals available: ${festivalProvider.resourceFestivals?.length ?? 0}');

    setState(() {
      if (query.isEmpty) {
        filteredFestivals = [];
        print('Query is empty, showing all festivals');
      } else {
        filteredFestivals = festivalProvider.resourceFestivals
                ?.where((festival) =>
                    (festival.nameOrganizer ?? '')
                        .toLowerCase()
                        .contains(query) ||
                    (festival.description ?? '')
                        .toLowerCase()
                        .contains(query) ||
                    (festival.descriptionOrganizer ?? '')
                        .toLowerCase()
                        .contains(query))
                .toList() ??
            [];
        print('Filtered festivals count: ${filteredFestivals.length}');
      }
    });
  }

  void _dismissKeyboardAndSearch() {
    FocusScope.of(context).unfocus();
  }

  void _onClearButtonTap() {
    _searchController.clear();
  }

  void _onSearchSubmitted(String value) {
    _dismissKeyboardAndSearch();
  }

  void _selectFestival(dynamic festival) {
    _navigateToFestival(festival);
  }

  void _navigateToFestival(dynamic festival) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('festivalId', festival.id.toString());
    Navigator.push(
      context,
      FadePageRouteBuilder(
        widget: Resourcehomeview(
          festivalId: festival.id.toString(),
          festivalName: festival.nameOrganizer ?? festival.description,
        ),
      ),
    );
  }

  void _fetchFestivalData(BuildContext context) {
    final festivalProvider =
        Provider.of<FestivalProvider>(context, listen: false);
    festivalProvider.fetchFestivals(context);
  }

  List<dynamic> _getDisplayFestivals() {
    final festivalProvider =
        Provider.of<FestivalProvider>(context, listen: false);
    if (_searchController.text.isEmpty) {
      return festivalProvider.resourceFestivals ?? [];
    } else {
      return filteredFestivals;
    }
  }

  @override
  Widget build(BuildContext context) {
    final festivalProvider = Provider.of<FestivalProvider>(context);

    // Obtain screen size and device info
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Responsive sizing helpers
    double getResponsiveSize(double baseSize,
        {double? tabletMultiplier, double? largeScreenMultiplier}) {
      if (isLargeScreen && largeScreenMultiplier != null) {
        return baseSize * largeScreenMultiplier;
      } else if (isTablet && tabletMultiplier != null) {
        return baseSize * tabletMultiplier;
      }
      return baseSize;
    }

    // Define responsive padding and sizing
    final horizontalPadding = getResponsiveSize(screenWidth * 0.04,
        tabletMultiplier: 0.06, largeScreenMultiplier: 0.08);
    final verticalPadding = getResponsiveSize(screenHeight * 0.01,
        tabletMultiplier: 0.015, largeScreenMultiplier: 0.02);

    // Responsive font sizes
    final titleFontSize = getResponsiveSize(screenWidth * 0.05,
        tabletMultiplier: 0.04, largeScreenMultiplier: 0.035);
    final subtitleFontSize = getResponsiveSize(screenWidth * 0.035,
        tabletMultiplier: 0.03, largeScreenMultiplier: 0.025);
    final searchFontSize = getResponsiveSize(16.0,
        tabletMultiplier: 18.0, largeScreenMultiplier: 20.0);

    // Responsive icon sizes
    final iconSize = getResponsiveSize(screenWidth * 0.07,
        tabletMultiplier: 0.06, largeScreenMultiplier: 0.05);
    final searchIconSize = getResponsiveSize(24.0,
        tabletMultiplier: 28.0, largeScreenMultiplier: 32.0);

    // Responsive spacing
    final smallSpacing = getResponsiveSize(8.0,
        tabletMultiplier: 12.0, largeScreenMultiplier: 16.0);
    final mediumSpacing = getResponsiveSize(16.0,
        tabletMultiplier: 20.0, largeScreenMultiplier: 24.0);
    final largeSpacing = getResponsiveSize(20.0,
        tabletMultiplier: 24.0, largeScreenMultiplier: 28.0);

    // Responsive border radius
    final borderRadius = getResponsiveSize(12.0,
        tabletMultiplier: 16.0, largeScreenMultiplier: 20.0);

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: GestureDetector(
        onTap: _dismissKeyboardAndSearch,
        child: Scaffold(
          body: Stack(
            children: [
              // Background Image
              SizedBox(
                height: screenHeight,
                width: screenWidth,
                child: Image.asset(
                  AppConstants.homeBG,
                  fit: BoxFit.cover,
                  height: screenHeight * 0.7, // 70% of screen height
                ),
              ),

              // AppBar at the top of the Stack
              Positioned(
                top: getResponsiveSize(screenHeight * 0.02,
                    tabletMultiplier: 0.025, largeScreenMultiplier: 0.03),
                left: horizontalPadding,
                right: horizontalPadding,
                child: Column(
                  children: [
                    AppBar(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$_userName",
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMM').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leadingWidth: getResponsiveSize(screenWidth * 0.22,
                          tabletMultiplier: 0.18, largeScreenMultiplier: 0.15),
                      // Dynamic leading width
                      leading: Row(
                        mainAxisSize: MainAxisSize.min, // Minimize space
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: getResponsiveSize(24.0,
                                  tabletMultiplier: 28.0,
                                  largeScreenMultiplier: 32.0),
                            ),
                            onPressed: () {
                              // Check if there's anything to pop
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                // If no more routes in the stack, exit the app
                                SystemNavigator.pop();
                              }
                            },
                          ),
                          Image.asset(
                            AppConstants.userProfile,
                            width: iconSize,
                            height: iconSize,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                      actions: [
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/resource_svgs/Feed_Selected.svg',
                            color: Colors.white,
                            width: iconSize,
                            height: iconSize,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              FadePageRouteBuilder(
                                  widget: SocialMediaHomeView()),
                            );
                          },
                        ),
                        PopupMenuButton<int>(
                          icon: Icon(Icons.more_vert_outlined,
                              color: Colors.white),
                          onSelected: (value) {
                            if (value == 1) {
                              _logout(context);
                            } else if (value == 2) {
                              _showDeleteAccountDialog(context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 1,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the menu
                                  _logout(context); // Call your logout function
                                },
                                child: Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the menu
                                  _showDeleteAccountDialog(
                                      context); // Call delete account function
                                },
                                child: Text(
                                  "Delete Account",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: largeSpacing),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: getResponsiveSize(8.0,
                                tabletMultiplier: 10.0,
                                largeScreenMultiplier: 12.0),
                            offset: Offset(
                                0,
                                getResponsiveSize(2.0,
                                    tabletMultiplier: 3.0,
                                    largeScreenMultiplier: 4.0)),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onSubmitted: _onSearchSubmitted,
                              onEditingComplete: _dismissKeyboardAndSearch,
                              textInputAction: TextInputAction.search,
                              style: TextStyle(fontSize: searchFontSize),
                              decoration: InputDecoration(
                                hintText: "Search festivals...",
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: searchFontSize,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                  size: searchIconSize,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: mediumSpacing,
                                  vertical: mediumSpacing,
                                ),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: _onClearButtonTap,
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[600],
                                size: searchIconSize,
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: largeSpacing),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            FadePageRouteBuilder(
                                widget: SocialMediaHomeView()));
                      },
                      child: SvgPicture.asset(
                        "assets/svgs/crapChat.svg",
                        width: getResponsiveSize(screenWidth * 0.15,
                            tabletMultiplier: 0.12,
                            largeScreenMultiplier: 0.10),
                        height: getResponsiveSize(screenHeight * 0.08,
                            tabletMultiplier: 0.06,
                            largeScreenMultiplier: 0.05),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 10,
              ),

              // ListView.builder for festivals
              Positioned.fill(
                top: getResponsiveSize(screenHeight * 0.35,
                    tabletMultiplier: 0.28, largeScreenMultiplier: 0.25),
                left: horizontalPadding,
                right: horizontalPadding,
                child: festivalProvider.resourceFestivals == null
                    ? Center(child: CircularProgressIndicator())
                    : _getDisplayFestivals().isEmpty
                        ? Center(
                            child: Text(
                                _searchController.text.isNotEmpty
                                    ? "No festivals found matching '${_searchController.text}'"
                                    : "No festivals available",
                                style: TextStyle(
                                    fontSize: getResponsiveSize(
                                        screenWidth * 0.045,
                                        tabletMultiplier: 0.04,
                                        largeScreenMultiplier: 0.035),
                                    color: Colors.black)),
                          )
                        : ListView.builder(
                            // Ensure the ListView doesn't shrink unexpectedly
                            padding: EdgeInsets.only(
                                bottom: getResponsiveSize(screenHeight * 0.02,
                                    tabletMultiplier: 0.025,
                                    largeScreenMultiplier: 0.03)),
                            itemCount: _getDisplayFestivals().length,
                            itemBuilder: (context, index) {
                              final festival = _getDisplayFestivals()[index];
                              Color containerColor =
                                  colors[index % colors.length];
                              Color openColor =
                                  openColors[index % openColors.length];

                              return GestureDetector(
                                onTap: () => _navigateToFestival(festival),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: getResponsiveSize(
                                          screenHeight * 0.01,
                                          tabletMultiplier: 0.015,
                                          largeScreenMultiplier: 0.02),
                                      horizontal: getResponsiveSize(
                                          screenWidth * 0.02,
                                          tabletMultiplier: 0.025,
                                          largeScreenMultiplier: 0.03)),
                                  child: Container(
                                    height: getResponsiveSize(
                                        screenHeight * 0.35,
                                        tabletMultiplier: 0.32,
                                        largeScreenMultiplier: 0.30),
                                    // Responsive height
                                    width: double.infinity,
                                    // Make width flexible
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                      // Responsive border radius
                                      color: containerColor,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                                getResponsiveSize(
                                                    screenWidth * 0.02,
                                                    tabletMultiplier: 0.025,
                                                    largeScreenMultiplier:
                                                        0.03)),
                                            // Responsive padding
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(
                                                      getResponsiveSize(
                                                          screenWidth * 0.02,
                                                          tabletMultiplier:
                                                              0.025,
                                                          largeScreenMultiplier:
                                                              0.03)),
                                                  // Responsive padding
                                                  child: Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          showAddressDialog(
                                                            double.parse(
                                                                festival
                                                                    .latitude),
                                                            double.parse(
                                                                festival
                                                                    .longitude),
                                                            context,
                                                            festival.nameOrganizer ??
                                                                festival
                                                                    .description,
                                                          );
                                                        },
                                                        child: Image.asset(
                                                            AppConstants
                                                                .festivalCardIcon2,
                                                            height: getResponsiveSize(
                                                                screenWidth *
                                                                    0.10,
                                                                tabletMultiplier:
                                                                    0.08,
                                                                largeScreenMultiplier:
                                                                    0.06),
                                                            width: getResponsiveSize(
                                                                screenWidth *
                                                                    0.10,
                                                                tabletMultiplier:
                                                                    0.08,
                                                                largeScreenMultiplier:
                                                                    0.06)),
                                                      ),
                                                      SizedBox(
                                                          width: getResponsiveSize(
                                                              screenWidth *
                                                                  0.03,
                                                              tabletMultiplier:
                                                                  0.025,
                                                              largeScreenMultiplier:
                                                                  0.02)),
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDateDialog(
                                                              festival,
                                                              context);
                                                        },
                                                        child: Image.asset(
                                                            AppConstants
                                                                .festivalCardIcon3,
                                                            height: getResponsiveSize(
                                                                screenWidth *
                                                                    0.10,
                                                                tabletMultiplier:
                                                                    0.08,
                                                                largeScreenMultiplier:
                                                                    0.06),
                                                            width: getResponsiveSize(
                                                                screenWidth *
                                                                    0.10,
                                                                tabletMultiplier:
                                                                    0.08,
                                                                largeScreenMultiplier:
                                                                    0.06)),
                                                      ),
                                                      Spacer(),
                                                      Container(
                                                        child: Image.asset(
                                                            AppConstants
                                                                .unofficial,
                                                            height: getResponsiveSize(
                                                                screenWidth *
                                                                    0.22,
                                                                tabletMultiplier:
                                                                    0.18,
                                                                largeScreenMultiplier:
                                                                    0.15),
                                                            width: getResponsiveSize(
                                                                screenWidth *
                                                                    0.32,
                                                                tabletMultiplier:
                                                                    0.28,
                                                                largeScreenMultiplier:
                                                                    0.25)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // SizedBox(height: screenHeight * 0.001), // 0.5% of screen height
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      left: getResponsiveSize(
                                                          screenWidth * 0.02,
                                                          tabletMultiplier:
                                                              0.025,
                                                          largeScreenMultiplier:
                                                              0.03)),
                                                  // Responsive padding
                                                  child: Text(
                                                    festival.nameOrganizer ??
                                                        festival.description,
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: getResponsiveSize(
                                                            screenWidth * 0.05,
                                                            tabletMultiplier:
                                                                0.045,
                                                            largeScreenMultiplier:
                                                                0.04)),
                                                    // Responsive font size
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: getResponsiveSize(
                                                          screenWidth * 0.02,
                                                          tabletMultiplier:
                                                              0.025,
                                                          largeScreenMultiplier:
                                                              0.03)),
                                                  // Responsive padding
                                                  child: Text(
                                                    festival.descriptionOrganizer ??
                                                        "description not specified",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: getResponsiveSize(
                                                            screenWidth * 0.033,
                                                            tabletMultiplier:
                                                                0.03,
                                                            largeScreenMultiplier:
                                                                0.028)),
                                                    // Responsive font size
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: getResponsiveSize(
                                                        screenHeight * 0.005,
                                                        tabletMultiplier: 0.008,
                                                        largeScreenMultiplier:
                                                            0.01)),
                                                // 0.5% of screen height
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left:
                                                                    screenWidth *
                                                                        0.02,
                                                                // 2% of screen width
                                                                right:
                                                                    screenWidth *
                                                                        0.015),
                                                        // 1.5% of screen width
                                                        child: Text(
                                                          "From: ${_formatFestivalDate(festival.startingDate)}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  screenWidth *
                                                                      0.04),
                                                          // Increased from 3.5% to 4%
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left:
                                                                    screenWidth *
                                                                        0.015,
                                                                // 1.5% of screen width
                                                                right:
                                                                    screenWidth *
                                                                        0.02),
                                                        // 2% of screen width
                                                        child: Text(
                                                          "To: ${_formatFestivalDate(festival.endingDate)}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  screenWidth *
                                                                      0.04),
                                                          // Increased from 3.5% to 4%
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Removed Spacer() here to prevent overflow
                                                // Added Flexible to allow content to adjust
                                                Flexible(
                                                  fit: FlexFit.tight,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            screenHeight * 0.05,
                                                        // Increased from 6% to 7% of screen height
                                                        width:
                                                            screenWidth * 0.3,
                                                        // Increased from 30% to 35% of screen width
                                                        decoration:
                                                            BoxDecoration(
                                                          color: openColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  screenWidth *
                                                                      0.04), // 4% of screen width
                                                        ),
                                                        child: Center(
                                                          child: Text("Open",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      screenWidth *
                                                                          0.05,
                                                                  // Increased from 4.5% to 5%
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: screenWidth *
                                                              0.05),
                                                      // 5% of screen width
                                                      Image.asset(
                                                          AppConstants
                                                              .forwardIcon,
                                                          height: screenWidth *
                                                              0.05,
                                                          // Increased from 5% to 7%
                                                          width: screenWidth *
                                                              0.05),
                                                      Spacer(),
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    screenWidth *
                                                                        0.02),
                                                        // 4% of screen width
                                                        child: Container(
                                                          height: screenWidth *
                                                              0.35,
                                                          // Increased from 22% to 28% of screen width
                                                          width: screenWidth *
                                                              0.28,
                                                          child: festival.image !=
                                                                      null &&
                                                                  festival.image
                                                                      .isNotEmpty
                                                              ? CachedNetworkImage(
                                                                  height:
                                                                      screenWidth *
                                                                          0.28,
                                                                  width:
                                                                      screenWidth *
                                                                          0.28,
                                                                  imageUrl:
                                                                      "https://stagingcrapadvisor.semicolonstech.com/asset/festivals/${festival.image}",
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  placeholder: (context,
                                                                          url) =>
                                                                      Center(
                                                                          child:
                                                                              CircularProgressIndicator()),
                                                                  errorWidget: (context,
                                                                          url,
                                                                          error) =>
                                                                      Icon(Icons
                                                                          .error),
                                                                )
                                                              : Image.asset(
                                                                  AppConstants
                                                                      .festivalImage,
                                                                  fit: BoxFit
                                                                      .cover),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    LogoutApi(context);
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Responsive sizing for dialog
    double getDialogSize(double baseSize,
        {double? tabletMultiplier, double? largeScreenMultiplier}) {
      if (isLargeScreen && largeScreenMultiplier != null) {
        return baseSize * largeScreenMultiplier;
      } else if (isTablet && tabletMultiplier != null) {
        return baseSize * tabletMultiplier;
      }
      return baseSize;
    }

    final dialogWidth = getDialogSize(screenWidth * 0.85,
        tabletMultiplier: 0.7, largeScreenMultiplier: 0.5);
    final dialogBorderRadius = getDialogSize(15.0,
        tabletMultiplier: 20.0, largeScreenMultiplier: 25.0);
    final titleFontSize = getDialogSize(18.0,
        tabletMultiplier: 20.0, largeScreenMultiplier: 22.0);
    final contentFontSize = getDialogSize(16.0,
        tabletMultiplier: 18.0, largeScreenMultiplier: 20.0);
    final detailFontSize = getDialogSize(14.0,
        tabletMultiplier: 16.0, largeScreenMultiplier: 18.0);
    final listFontSize = getDialogSize(13.0,
        tabletMultiplier: 15.0, largeScreenMultiplier: 17.0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogBorderRadius),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: getDialogSize(20.0,
                tabletMultiplier: 40.0, largeScreenMultiplier: 60.0),
            vertical: getDialogSize(20.0,
                tabletMultiplier: 30.0, largeScreenMultiplier: 40.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: getDialogSize(28.0,
                    tabletMultiplier: 32.0, largeScreenMultiplier: 36.0),
              ),
              SizedBox(
                  width: getDialogSize(10.0,
                      tabletMultiplier: 12.0, largeScreenMultiplier: 15.0)),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(
                  fontSize: contentFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                  height: getDialogSize(15.0,
                      tabletMultiplier: 18.0, largeScreenMultiplier: 20.0)),
              Text(
                'This action cannot be undone. All your data including:',
                style: TextStyle(
                  fontSize: detailFontSize,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(
                  height: getDialogSize(8.0,
                      tabletMultiplier: 10.0, largeScreenMultiplier: 12.0)),
              Padding(
                padding: EdgeInsets.only(
                    left: getDialogSize(10.0,
                        tabletMultiplier: 12.0, largeScreenMultiplier: 15.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Your profile information',
                        style: TextStyle(
                            fontSize: listFontSize, color: Colors.grey[600])),
                    Text('• Chat messages and conversations',
                        style: TextStyle(
                            fontSize: listFontSize, color: Colors.grey[600])),
                    Text('• Posts and comments',
                        style: TextStyle(
                            fontSize: listFontSize, color: Colors.grey[600])),
                    Text('• Festival preferences and data',
                        style: TextStyle(
                            fontSize: listFontSize, color: Colors.grey[600])),
                  ],
                ),
              ),
              SizedBox(
                  height: getDialogSize(15.0,
                      tabletMultiplier: 18.0, largeScreenMultiplier: 20.0)),
              Text(
                'will be permanently deleted.',
                style: TextStyle(
                  fontSize: detailFontSize,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: getDialogSize(16.0,
                      tabletMultiplier: 18.0, largeScreenMultiplier: 20.0),
                ),
              ),
            ),
            SizedBox(
                width: getDialogSize(10.0,
                    tabletMultiplier: 12.0, largeScreenMultiplier: 15.0)),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteAccount(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(getDialogSize(8.0,
                      tabletMultiplier: 10.0, largeScreenMultiplier: 12.0)),
                ),
              ),
              child: Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: getDialogSize(16.0,
                      tabletMultiplier: 18.0, largeScreenMultiplier: 20.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(BuildContext context) async {
    // Always use root context for dialogs
    final rootContext = navigatorKey.currentContext!;

    // Show loading dialog
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Deleting your account..."),
            ],
          ),
        );
      },
    );

    print('🔍 Debug: Calling deleteAccount API with userId');
    final success = await deleteAccount(rootContext);
    print('🔍 Debug: deleteAccount API returned: $success');

    // Close loading
    Navigator.of(rootContext, rootNavigator: true).pop();

    if (success) {
      print('🔍 Debug: Account deletion successful, navigating to login...');
      Navigator.of(rootContext).pushAndRemoveUntil(
        FadePageRouteBuilder(widget: LoginView()),
        (route) => false,
      );
    } else {
      print('🔍 Debug: Account deletion failed');
    }
  }

  String _formatFestivalDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Date not available';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
