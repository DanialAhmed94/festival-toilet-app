import 'package:crapadvisor/models/festivalsDetail_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:crapadvisor/screens/reviewsScreen.dart';
import '../annim/transiton.dart';
import '../screens/what3words.dart';

showMarkerInfo(BuildContext context, Festival festival) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(

              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: festival.image != null && festival.image.isNotEmpty
                    ? Padding(
                  padding: EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      "https://stagingcrapadvisor.semicolonstech.com/asset/festivals/" +
                          festival.image,
                      fit: BoxFit.cover,
                      height: 200, // Set the height
                      width: 200,
                      errorBuilder: (context, error, stackTrace) {
                        // If an error occurs while loading the image, show the default image
                        return Image.asset(
                          "assets/icons/logo.png",
                          fit: BoxFit.cover,
                        );
                      },
                      loadingBuilder: (BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                            loadingProgress.expectedTotalBytes !=
                                null
                                ? loadingProgress
                                .cumulativeBytesLoaded /
                                loadingProgress
                                    .expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    "assets/icons/logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),


            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Container(
                      child: Text(
                        festival.nameOrganizer ??
                            festival.description,
                        maxLines: 3,
                        // Limit text to 3 lines
                        overflow: TextOverflow.ellipsis,
                        // Add ellipsis for overflow
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16.0,
                            fontFamily: "Poppins-Bold"),
                      ),
                    ),
                  ),
                  Text(
                    "Date: ${festival.startingDate}",
                    style: TextStyle(
                      fontFamily: "Poppins-Medium",
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    "Time: ${festival.time ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: "Poppins-Medium",
                      color: Colors.black54,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(right: 8,bottom: 8),
                    child: Container(
                      width: double.infinity, // Set your desired width here
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadePageRouteBuilder(
                              widget: What3WordsScreen(
                                what3words: "",
                                festivalLocation: LatLng(
                                    double.parse(festival.latitude),
                                    double.parse(festival.longitude)),
                                festivalId: festival.id.toString(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // Remove padding for full gradient coverage
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Keep original round shape
                          ),
                          backgroundColor: Colors.transparent, // Make the button background transparent
                          shadowColor: Colors.transparent, // Remove shadow to avoid overlapping effect
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF45A3D9),  // Color at 0%
                                Color(0xFF45D9D0),  // Color at 100%
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20), // Match the round shape
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 15.0), // Adjust padding
                            child: Text(
                              "Post Toilet Review",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontFamily: "Poppins-Medium",
                              ),
                            ),
                          ),
                        ),
                      ),
                    )

                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 8,bottom: 8,),
                    child: Container(
                      width: double.infinity, // Set your desired width here
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadePageRouteBuilder(
                              widget: Reviews(
                                festival_id:festival.id.toString(),
                                festivalLocation: LatLng(
                                    double.parse(festival.latitude),
                                    double.parse(festival.longitude)),
                              )
                            ),
                          );
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => Reviews(
                          //           festival_id:festival.id.toString(),
                          //           festivalLocation: LatLng(
                          //               double.parse(festival.latitude),
                          //               double.parse(festival.longitude)),
                          //         )));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text(
                          "Ratings",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontFamily: "Poppins-Medium",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
