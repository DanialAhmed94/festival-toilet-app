import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../annim/transiton.dart';
import '../../LocationMap.dart';
import '../../constants/appConstants.dart';
import '../../model/activitiesModel.dart';

class ActivityDetail extends StatelessWidget {
  final ActivityData activity;

  ActivityDetail({required this.activity});

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
                  bottomRight:
                      Radius.circular(30), // Right-side circular corner
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
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        "Activity Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Add additional content in the body here (e.g., news details)
          Positioned.fill(
            top: 100, // Adjust based on your custom app bar height
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
                          "Activity Title",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Dummy subtitle
                        Text(
                          activity.activityTitle ?? " No title specified",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16), // Spacing between the containers
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
                          "Festival Title",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Dummy subtitle
                        Text(
                          activity.festival.nameOrganizer?.isNotEmpty == true
                              ? activity.festival.nameOrganizer!
                              : activity.festival.description?.isNotEmpty ==
                                      true
                                  ? activity.festival.description!
                                  : "No title specified",
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
                            "https://stagingcrapadvisor.semicolonstech.com/asset/festivals/${activity.festival.image}",
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),

                  SizedBox(height: 16), // Spacing between containers
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
                          "Detail",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Dummy subtitle
                        Text(
                          activity.description ?? "No description",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
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
                                  latitude: double.parse(activity.latitude),
                                  longitude: double.parse(activity.longitude),
                                  activityName: activity.activityTitle,
                                ),
                              ),
                            );
                          },

                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            color: Colors.black,
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
                                    latitude: double.parse(activity.latitude),
                                    longitude: double.parse(activity.longitude),
                                    activityName: activity.activityTitle,
                                  ),
                                ),
                              );
                            },
                            child: Image.asset(AppConstants.mapPreview),
                          ),
                        ),
                      ),
                    ],
                  ),


                  SizedBox(height: 16), // Spacing between containers

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Start Time Container
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start Time",
                            style:
                            TextStyle(fontFamily: "UbuntuMedium", fontSize: 15,fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8,),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  activity.startTime ?? "N/A",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12), // Space between the two containers

                      // End Time Container
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "End Time",
                            style:
                            TextStyle(fontFamily: "UbuntuMedium", fontSize: 15,fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8,),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  activity.endTime ?? "N/A",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Start Time Container
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start Date",
                            style:
                            TextStyle(fontFamily: "UbuntuMedium", fontSize: 15,fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8,),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  activity.startDate ?? "N/A",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12), // Space between the two containers

                      // End Time Container
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "End Date",
                            style:
                            TextStyle(fontFamily: "UbuntuMedium", fontSize: 15,fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8,),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  activity.endDate ?? "N/A",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
