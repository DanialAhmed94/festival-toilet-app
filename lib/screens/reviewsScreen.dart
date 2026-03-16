import 'package:cached_network_image/cached_network_image.dart';
import 'package:crapadvisor/screens/reviewDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import '../annim/transiton.dart';
import '../apis/getFeedbacks.dart';
import '../models/getFeedbacksModel.dart';
import '../providers/festivalName_provider.dart';
import '../widgets/customTopSnackBar.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Custom cache manager for review images
class ReviewCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'reviewCache';
  
  static ReviewCacheManager? _instance;
  factory ReviewCacheManager() {
    _instance ??= ReviewCacheManager._();
    return _instance!;
  }
  
  ReviewCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 200, // Store up to 200 images (more than festivals)
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class Reviews extends StatefulWidget {
  late String festival_id;
  late LatLng festivalLocation;

  Reviews({required this.festival_id, required this.festivalLocation});

  @override
  State<Reviews> createState() => _ReviewsState();
}

class _ReviewsState extends State<Reviews> {
  late int _pageNumber;
  List<FeedbackItem> _feedbacks = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMoreData = true; // Track whether there's more data to load
  late int totalPages; // total pages in api
  late FestivalNameProvider _festivalNameProvider;
  bool _noMoreReviewsSnackbarShown = false;
  bool _noReviewsSnackbarShown = false;

  // Method to clear cache when needed (e.g., for debugging or memory management)
  static Future<void> clearImageCache() async {
    await ReviewCacheManager().emptyCache();
    print('Review image cache cleared');
  }

  @override
  void initState() {
    super.initState();
    _festivalNameProvider = FestivalNameProvider();
    _pageNumber = 1;
    _isLoading = true;
    setState(() {});
    _scrollController.addListener(_onScroll);
    getData(widget.festival_id);
  }

  getData(String festival_id) async {
    try {
      // if (!_hasMoreData && !_noMoreReviewsSnackbarShown && _pageNumber > 1) {
      //   awesomeTopSnackbar(context, "No more reviews available");
      //   _noMoreReviewsSnackbarShown = true;
      //   return; // Exit early if no more data and snackbar shown
      // }

      if (_hasMoreData) {
        final List<FeedbackItem> feedbacks =
            await fetchFeedback(_pageNumber, festival_id);
        totalPages = getTotalPages();

        if (feedbacks.isEmpty) {
          setState(() {
            _hasMoreData = false;
            if (_pageNumber == 1 && !_noReviewsSnackbarShown) {
              awesomeTopSnackbar(context, "No reviews available");
              _noReviewsSnackbarShown = true;
            }
          });
        } else {
          setState(() {
            _feedbacks.addAll(feedbacks);
            _pageNumber++;
          });
        }
      }
    } catch (e) {
      if (e.toString().contains(
          "Exception: Failed to load feedback: Exception: Response does not contain data")) {
        awesomeTopSnackbar(context, "No reviews are available");
      } else {
        awesomeTopSnackbar(context, "Failed to load reviews");
      }
      print("Failed to fetch feedback: $e");
    } finally {
      _isLoading = false;
      setState(() {});
    }
  }

  void _onScroll() async {
    if (!_isLoading &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMoreData &&
        _pageNumber <= totalPages) {
      // Store current position before loading more data
      final double currentPosition = _scrollController.position.pixels;

      // Set loading state to true
      setState(() {
        _isLoading = true;
      });
      awesomeTopSnackbar(context, "Loading more reviews");
      // Load more data
      await getData(widget.festival_id);

      // Restore scroll position after loading new data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(currentPosition);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            height: MediaQuery.of(context).size.height *
                0.74, // Set the height to the screen height
            width: MediaQuery.of(context)
                .size
                .width, // Set the width to the screen width
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/slectFacilityBackground.png'),
                // Change this to your image path
                fit: BoxFit.fitWidth, // Control how the image scales
              ),
            ),
          ),
          // Transparent AppBar
          AppBar(
            centerTitle: true,
            toolbarHeight: 75,
            backgroundColor: Colors.transparent,
            // Make the AppBar transparent
            elevation: 0,
            // Remove the shadow
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
              "Toilets Reviews",
              style: TextStyle(
                fontFamily: "Poppins-Bold",
                fontSize: 24,
                color: Colors.white, // Change color for better visibility
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          // Loading indicator or ListView
          Positioned(
            top: MediaQuery.of(context).size.height*0.1,
            bottom: 0,left: 0,right: 0,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _feedbacks.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) => CustomCard(
                      festivalLocation: widget.festivalLocation,
                      feedbackItem: _feedbacks[index],
                      festivalNameFuture: _festivalNameProvider
                          .getFestivalName(_feedbacks[index].festivalId),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final FeedbackItem feedbackItem;
  final Future<String> festivalNameFuture;
  final LatLng festivalLocation;
  List<String> cachedImageUrls = [];

  CustomCard(
      {required this.festivalLocation,
      required this.feedbackItem,
      required this.festivalNameFuture});

  Map<String, String?> cachedImagePaths = {}; // Map to store cached image paths

  Future<String?> _image(BuildContext context, String festivalName,
      List<String?> imageUrls) async {
    try {
      // Iterate through each URL to fetch the image
      for (String? url in imageUrls) {
        if (url != null && url.isNotEmpty) {
          // Simple HTTP HEAD request to check if image exists (lightweight)
          try {
            final response = await http.head(Uri.parse(url));
            if (response.statusCode == 200) {
              return url; // Return the URL if image exists
            }
          } catch (e) {
            // Continue to next URL if this one fails
            continue;
          }
        }
      }
      return null; // Return null if no valid URL or image found
    } catch (e) {
      print("Error fetching image: $e");
      return null; // Return null if any error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String?> imageUrls = [
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/cleanliness_image/${feedbackItem.cleanlinessImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/odour_image/${feedbackItem.odourImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/aaa_disabled_access_image/${feedbackItem.aaaDisabledAccessImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/green_credentials_image/${feedbackItem.greenCredentialsImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/bog_roll_standard_image/${feedbackItem.bogRollStandardImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/clean_flush_fluid_image/${feedbackItem.cleanFlushFluidImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/locking_system_image/${feedbackItem.lockingSystemImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/hand_wash_facility_image/${feedbackItem.handWashFacilityImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/soap_availablity_image/${feedbackItem.soapAvailabilityImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/hand_sanitizer_availability_image/${feedbackItem.handSanitizerAvailabilityImage}",
      "https://stagingcrapadvisor.semicolonstech.com/public/asset/water_availability_image/${feedbackItem.waterAvailabilityImage}",
    ];

    return FutureBuilder<String?>(
      future: festivalNameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(); // Or any other loading indicator
        } else {
          final String festivalName = snapshot.data!;
          return _buildCard(context, festivalName, imageUrls);
        }
      },
    );
  }

  Widget _buildCard(
      BuildContext context, String festivalName, List<String?> imageUrls) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 7,
          child: Row(
            children: [
              FutureBuilder<String?>(
                future: _image(context, festivalName, imageUrls),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: EdgeInsets.all(8),
                      height: 100,
                      width: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    final String? imageUrl = snapshot.data;

                    return Container(
                      margin: EdgeInsets.all(8),
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue,
                      ),
                      child: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                                                             child: CachedNetworkImage(
                                 imageUrl: imageUrl,
                                 fit: BoxFit.cover,
                                 width: 100,
                                 height: 100,
                                 cacheManager: ReviewCacheManager(),
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
                                   child: Icon(
                                     Icons.error,
                                     color: Colors.red,
                                     size: 30,
                                   ),
                                 ),
                                 memCacheWidth: 200,
                                 memCacheHeight: 200,
                                 maxWidthDiskCache: 400,
                                 maxHeightDiskCache: 400,
                                 cacheKey: "review_${feedbackItem.id}_${imageUrl.hashCode}",
                                 fadeInDuration: Duration(milliseconds: 200),
                                 fadeOutDuration: Duration(milliseconds: 200),
                               ),
                            )
                          : SvgPicture.asset('assets/svgs/logo-crap.svg',
                              height: 50, width: 50),
                    );
                  }
                },
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
                      festivalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "Quicksand-Medium", fontSize: 11),
                    ),
                    Text(
                      feedbackItem.username,
                      style:  TextStyle(
                          fontFamily: "Quicksand-Bold",
                          fontSize: 15,
                          fontWeight: FontWeight.bold)
                    ),
                    Text(feedbackItem.date),
                  ],
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Score(obtainedScore: feedbackItem.totalScore.toString()),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          FadePageRouteBuilder(
            widget: ReviewDetailScreen(
              feedbackItem: feedbackItem,
              imageUrls: imageUrls,
              festivalName: festivalName,
              festivalLocation: festivalLocation,
            ),
          ),
        );
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ReviewDetailScreen(
        //       feedbackItem: feedbackItem,
        //       imageUrls: imageUrls,
        //       festivalName: festivalName,
        //       festivalLocation: festivalLocation,
        //     ),
        //   ),
        // );
      },
    );
  }
}

class Score extends StatelessWidget {
  String obtainedScore;

  Score({required this.obtainedScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(
            "Score",
            style: TextStyle(
              fontFamily: 'Quicksand-Bold',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 20, // Set the minimum height here
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$obtainedScore",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("/"),
                Text("160"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
