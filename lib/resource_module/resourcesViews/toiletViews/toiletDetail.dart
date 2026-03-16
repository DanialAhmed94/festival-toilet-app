import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../annim/transiton.dart';
import '../../LocationMap.dart';
import '../../constants/appConstants.dart';
import '../../model/activitiesModel.dart';
import '../../model/toiletModel.dart';

class ToiletDetail extends StatelessWidget {
  final ToiletData toilet;

  ToiletDetail({required this.toilet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppConstants.homeBG,
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height * 0.75,
            ),
          ),
          // Custom App Bar in the body
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF45A3D9),
                    Color(0xFF45D9D0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const Text(
                      "Toilet Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          // Add additional content in the body here (e.g., news details)
          Positioned.fill(
            top: 130, // Adjust based on your custom app bar height
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title container
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // White background color for the container
                      borderRadius: BorderRadius.circular(16),
                      // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Light shadow
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading title
                        Text(
                          "Toilet Category",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Dummy subtitle
                        Text(
                          toilet.toiletType.name ?? " No title specified",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16), // Sp
                  // Placeholder for news content
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4.0,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        height: 90,
                        width: 90,
                        imageUrl:
                            "https://stagingcrapadvisor.semicolonstech.com/public/asset/toilets/${toilet.image}",
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      // Left-aligned "View Location" text
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              FadePageRouteBuilder(
                                widget: LocationMap(
                                  latitude:
                                      double.parse(toilet.latitude ?? "0"),
                                  longitude:
                                      double.parse(toilet.longitude ?? "0"),
                                  activityName: "Toilet ",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                "View Location",
                                style: TextStyle(
                                  fontFamily: "UbuntuMedium",
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Centered arrow icon
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_forward_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Right-aligned image (PNG)
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                FadePageRouteBuilder(
                                  widget: LocationMap(
                                    latitude:
                                        double.parse(toilet.latitude ?? "0"),
                                    longitude:
                                        double.parse(toilet.longitude ?? "0"),
                                    activityName: "Toilet ",
                                  ),
                                ),
                              );
                            },
                            child: Image.asset(AppConstants.mapPreview),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
