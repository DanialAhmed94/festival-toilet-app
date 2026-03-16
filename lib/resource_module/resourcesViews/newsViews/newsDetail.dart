import 'package:crapadvisor/resource_module/model/NewsModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/appConstants.dart';

class NewsDetail extends StatelessWidget {
  final Bulletin newsBulletin;

  NewsDetail({required this.newsBulletin});

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
                        "News Details",
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
                          "Bulletin Title",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Dummy subtitle
                        Text(
                          newsBulletin.title ?? " No title specified",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16), // Spacing between the containers

                  // Placeholder for news content
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // White background color for the content container
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
                        // Placeholder for detailed news content
                        Text(
                          newsBulletin.title ?? " No title specified",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          newsBulletin.content ?? " No content specified",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16), // Spacing between containers

                  // Time and Date row
                  Row(
                    children: [
                      // Time container
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _formatTime(newsBulletin.time),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Spacing between time and date containers

                      // Date container
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 13,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                newsBulletin.date ?? "0:00",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return "0:00";

    try {
      final parsedTime = DateFormat("HH:mm").parse(time);
      return DateFormat("h:mm a").format(parsedTime); // Formats to AM/PM
    } catch (e) {
      return "0:00"; // Return a default if parsing fails
    }
  }

}
