import 'package:crapadvisor/resource_module/model/festivalsModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../annim/transiton.dart';
import '../../services/getFestivalAddress.dart';
import '../LocationMap.dart';

void showDateDialog(FestivalResource festival, BuildContext context) {
  // Initialize variables for starting and ending dates
  DateTime? startingDate;
  DateTime? endingDate;
  bool hasEnded = false;

  // Attempt to parse the starting date
  String startingDateStr;
  if (festival.startingDate != null && festival.startingDate.isNotEmpty) {
    try {
      startingDate = DateTime.parse(festival.startingDate);
      startingDateStr = DateFormat('MMMM d, yyyy').format(startingDate);
    } catch (e) {
      // Handle parsing errors
      startingDateStr = 'Invalid date format';
      startingDate = null;
    }
  } else {
    startingDateStr = 'Date not available';
  }

  // Attempt to parse the ending date
  String endingDateStr;
  if (festival.endingDate != null && festival.endingDate.isNotEmpty) {
    try {
      endingDate = DateTime.parse(festival.endingDate);
      endingDateStr = DateFormat('MMMM d, yyyy').format(endingDate);

      // Check if the festival has ended
      hasEnded = DateTime.now().isAfter(endingDate);
    } catch (e) {
      // Handle parsing errors
      endingDateStr = 'Invalid date format';
      endingDate = null;
    }
  } else {
    endingDateStr = 'Date not available';
  }

  // Show the dialog
  showDialog(
    context: context,
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
              // Icon and Title
              Row(
                children: [
                  Icon(Icons.event, color: Colors.blueAccent, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Festival Dates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Divider
              Divider(thickness: 1, color: Colors.grey[300]),
              // Dates Content
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(
                      'Start Date: $startingDateStr',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'End Date: $endingDateStr',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 20),
                    if (hasEnded)
                      Text(
                        'This festival has already ended.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Close Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


void showAddressDialog(double lat, double lng, BuildContext context, String festivalName) {
  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder<String>(
        future: getFestivalAddress(lat, lng), // Your method to get the address
        builder: (context, snapshot) {
          // Prepare variables for address and content
          String title = '${festivalName} Address';
          Widget content;
          String address = '';

          if (snapshot.connectionState == ConnectionState.waiting) {
            // While loading, show a placeholder or loading indicator
            content = Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If there's an error, display the error message
            content = Text(
              'Error: ${snapshot.error}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            );
          } else {
            // When data is loaded, display the address
            address = snapshot.data ?? 'Address not available';
            content = Text(
              address,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 200, // Set a minimum height
                maxHeight: 300, // Set a maximum height
                minWidth: 300,  // Optionally set a minimum width
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon and Title
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blueAccent, size: 30),
                        SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Divider
                    Divider(thickness: 1, color: Colors.grey[300]),
                    // Address Content or Loading Indicator
                    Expanded(
                      child: Center(
                        child: content,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationMap(
                                  latitude: lat,
                                  longitude: lng,
                                  festivalName: festivalName,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View on Map',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


void showSuccessDialog<T>(
    BuildContext context,
    String message,
    String? choice,
    T navigateTo,
    ) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: choice != null
            ? Text(
          'Failure',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'Success',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.left,  // Set text alignment here
              style: TextStyle(
                  fontSize: 12
                // You can define your text style properties here, like fontSize, fontFamily, etc.
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                FadePageRouteBuilder(widget: navigateTo as Widget),
                    (route) => route.isFirst,
              );
            },
          ),
        ],
      );
    },
  );
}

void showErrorDialog(
    BuildContext context, String message, List<dynamic> errors) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error',style: TextStyle(color: Colors.red),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (errors.isNotEmpty)
              Column(
                children: errors
                    .map((error) => Text(error.toString(),
                    style: TextStyle(color: Colors.red)))
                    .toList(),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
