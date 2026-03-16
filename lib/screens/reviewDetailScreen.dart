import 'package:crapadvisor/screens/mainScreen.dart';
import 'package:crapadvisor/screens/what3words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;

import 'package:http/http.dart' as http;
import '../models/getFeedbacksModel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/ToiletNavigationMap.dart';


class ReviewDetailScreen extends StatelessWidget {
  final LatLng festivalLocation;
  final FeedbackItem feedbackItem;
  final List<String?> imageUrls;
  final String festivalName;

  ReviewDetailScreen({required this.feedbackItem,
    required this.imageUrls,
    required this.festivalName, required this.festivalLocation});

  Future<bool> isValidImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            height: MediaQuery.of(context).size.height, // Set the height to the screen height
            width: MediaQuery.of(context).size.width, // Set the width to the screen width
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/slectFacilityBackground.png'), // Change this to your image path
                fit: BoxFit.cover, // Control how the image scales
              ),
            ),
          ),
          // Custom AppBar
          AppBar(
            backgroundColor: Colors.transparent,
            // Make the AppBar transparent
            elevation: 0,
            // Remove the shadow
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
              "Review's Detail",
              style: TextStyle(
                fontFamily: "Poppins-Bold",
                fontSize: 24,
                color: Colors
                    .white, // You can change the color for better visibility
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          // Main content
          Positioned(   top: MediaQuery.of(context).size.height*0.12,
            bottom: 0,left: 0,right: 0,
            child: Column(
              children: [
                // ImageSlider takes up 40% of the screen height
                ImageSlider(
                  imageUrls: imageUrls,
                  isValidImageUrl: isValidImageUrl,
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
                ReviewDetail(
                  feedbackItem: feedbackItem,
                  festivalName: festivalName,
                  festivalLocation: festivalLocation,
                ),
                // Other widgets can be added here
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
        "Review's Detail",
        style: TextStyle(
          fontFamily: "Poppins-Bold",
          fontSize: 24,
        ),
      ),
      automaticallyImplyLeading: false,
    );
  }
}

class ReviewDetail extends StatelessWidget {
  final FeedbackItem feedbackItem;
  final String festivalName;
  final LatLng festivalLocation;

  ReviewDetail(
      {required this.feedbackItem, required this.festivalName, required this.festivalLocation});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4262,
        decoration: BoxDecoration(
        //  color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, left: 8),
                            child: Text(
                              "Festival:",
                              style: TextStyle(
                                color: Color(0xFF445EFF),
                                fontFamily: "Quicksand-Bold",
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12, left: 8),
                              child: Text(
                                festivalName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontFamily: "Ubuntu-Bold",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, left: 8),
                            child: Text(
                              "Toilet:",
                              style: TextStyle(
                                color: Color(0xFF445EFF),
                                fontFamily: "Quicksand-Bold",
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12, left: 8),
                              child: Text(
                                "${feedbackItem.toiletType_name}",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontFamily: "Ubuntu-Bold",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            Text(
                              "Reviewer:",
                              style: TextStyle(
                                fontFamily: "Quicksand-Bold",
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF445EFF),
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              feedbackItem.username,
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            Text(
                              "Review Date:",
                              style: TextStyle(
                                color: Color(0xFF445EFF),
                                fontFamily: "Quicksand-Bold",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(feedbackItem.date),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                    color: Color(0xFF445EFF),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Rating",
                        style: TextStyle(
                          fontFamily: 'Quicksand-Bold',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${feedbackItem.totalScore}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "/",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "160",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // navigation button
            Padding(
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.78,
                top: MediaQuery.of(context).size.height * 0.03,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ToiletNavigationMap(
                        latitude: festivalLocation.latitude,
                        longitude: festivalLocation.longitude,
                      ),
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  "assets/svgs/navigation.svg",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class ImageSlider extends StatelessWidget {
  final List<String?> imageUrls;
  final Future<bool> Function(String) isValidImageUrl;
  final double height;

  ImageSlider({required this.imageUrls,
    required this.isValidImageUrl,
    required this.height});

  @override
  Widget build(BuildContext context) {
    final List<String> filteredImageUrls = imageUrls
        .where((url) => url != null && url!.isNotEmpty)
        .map((url) => url!)
        .toList();

    return Column(
      children: [
        FutureBuilder<List<bool>>(
          future: Future.wait(filteredImageUrls.map(isValidImageUrl)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final isValidImageList = snapshot.data!;
            final validImageUrls = <String>[];
            for (var i = 0; i < isValidImageList.length; i++) {
              if (isValidImageList[i]) {
                validImageUrls.add(filteredImageUrls[i]);
              }
            }
            if (validImageUrls.isNotEmpty) {
              return  carousel_slider.CarouselSlider(
                options: carousel_slider.CarouselOptions(
                  height: height,
                  autoPlay: true,
                  enableInfiniteScroll: true,
                  autoPlayInterval: Duration(seconds: 3),
                ),
                items: validImageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            height: MediaQuery
                                .of(context)
                                .size
                                .height / 2,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            } else {
              return Container(
                height: height,
                alignment: Alignment.center,
                child: Text(
                  'No images available',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
