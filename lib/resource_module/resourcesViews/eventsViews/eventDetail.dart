import 'package:crapadvisor/resource_module/constants/AppConstants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../annim/transiton.dart';
import '../../apis/preRegistration.dart';
import '../../model/eventModel.dart';
import '../../utilities/sharedPrefs.dart';
import 'allEvents.dart';

class EventDetail extends StatefulWidget {
  final EventData event;

  EventDetail({required this.event});

  @override
  State<EventDetail> createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetail> {
  String? userName;

  String? email;

  String? phone;
  bool _isLoading = false;

  Future<void> _loadProfileData() async {
    final name = await getUserName() ?? "";
    final email1 = await getUserEmail() ?? " ";
    final phonetemp = await getUserPhone() ?? " ";
    userName = name;
    email = email1;
    phone = phonetemp;
  }

  void _handlePreRegistration(String eventId) async {
    setState(() {
      _isLoading = true;
    });

    await _loadProfileData(); // Simulated function for loading data
    final bool registrationSuccess =
        await preRegistration(context, eventId) ?? false;

    setState(() {
      _isLoading = false; // Hide progress indicator
    });

    if (registrationSuccess) {
      showDialog(
        context: context,
       barrierDismissible : false,

        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 50,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Pre-registration Successful!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Dear ${userName}, you have successfully registered for the event.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          email ?? "No email provided",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phone ?? "No phone number provided",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        String? festivalId =
                            await prefs.getString('festivalId');
                        int count = 0;
                        Navigator.pushAndRemoveUntil(
                          context,
                          FadePageRouteBuilder(
                            widget: AllEvents(
                              festivalId: festivalId!,
                            ),
                          ),
                              (route) {
                            count++;
                            return count > 3; // Keep routes only after the second pop
                          },
                        );


                      },
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                        "Event Detail",
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
                        // Text content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Title",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.event.eventTitle ?? " No title specified",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Spacer(), // Pushes the image to the right edge
                        // Image positioned on the right edge
                        Align(
                          alignment: Alignment.centerRight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              "assets/images/eventTitle.png",
                              height: 60, // Adjust height as needed
                              width: 60, // Adjust width as needed
                              fit: BoxFit.cover,
                            ),
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
                          widget.event.eventTitle ?? "",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.event.eventDescription ??
                              "No description specified",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16), // Spacing between containers
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
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
                        // Text content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Crowd Capacity",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.event.crowdCapacity ?? "0",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Spacer(), // Pushes the image to the right edge
                        // Image positioned on the right edge
                        Align(
                          alignment: Alignment.centerRight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              "assets/resource_images/crowdCapacity.png",
                              height: 60, // Adjust height as needed
                              width: 60, // Adjust width as needed
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                  "assets/resource_images/startTime.png"),
                              SizedBox(width: 12),
                              Text(
                                "Start Time",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.event.startTime ?? "0:00",
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
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset("assets/resource_images/endTime.png"),
                              SizedBox(width: 12),
                              Text(
                                "End Time",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.event.endTime ?? "0:00",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset("assets/resource_images/startTime.png"),
                        SizedBox(width: 12),
                        Text(
                          "Date",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.event.startDate ?? "0:00",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () =>
                            _handlePreRegistration(widget.event.id.toString()),
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Image.asset(
                            "assets/resource_images/preRegistration.png"),
                  ),
                  SizedBox(
                    height: 8,
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
