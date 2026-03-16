import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import '../annim/transiton.dart';
import '../screens/feedbackForm.dart';

Future<void> postToilet(
    BuildContext context,
    double festivalLatitude,
    double festivalLongitude,
    double lat,
    double lng,
    String what3words,
    String festId,
    String toiletTypeId,
    String facilityName) async {
  final String url =
      'https://stagingcrapadvisor.semicolonstech.com/api/post_toilet';
  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode({
        'toilet_type_id': toiletTypeId,
        'festival_id': festId,
        'latitude': lat,
        'longitude': lng,
        'what_3_words': what3words,
      }),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> parsedJson = jsonDecode(response.body);
      String toiltIdresponse = parsedJson['data']['id'].toString();
      _showSuccessDialog(context, festId, toiltIdresponse, facilityName, lat,
          lng, what3words, festivalLatitude, festivalLongitude);
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.8, // Adjust width as needed
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // Ensure the dialog takes minimum space needed
                children: [
                  IntrinsicHeight(
                    child: Column(
                      children: [
                        Text(
                          "Error",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontFamily: "Poppins-Bold",
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          "Something went wrong!!",
                          style: TextStyle(
                            fontFamily: "Poppins-Medium",
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "OK",
                          style: TextStyle(fontFamily: "Poppins-Bold"),
                          textAlign: TextAlign.center,
                        ),
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
  } catch (e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width *
                0.8, // Adjust width as needed
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Ensure the dialog takes minimum space needed
              children: [
                IntrinsicHeight(
                  child: Column(
                    children: [
                      Text(
                        "Error",
                        style: TextStyle(
                          fontFamily: "Poppins-Bold",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        "Server is not responding!",
                        style: TextStyle(
                          fontFamily: "Poppins-Medium",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "OK",
                        style: TextStyle(fontFamily: "Poppins-Bold"),
                        textAlign: TextAlign.center,
                      ),
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

class DialogBox extends StatefulWidget {
  final String facilityName;
  final double toiletLat;
  final double toiletLng;
  final String toiletId;
  final String festivalId;
  final double festivalLatitude;
  final double festivalLongitude;
  final what3words;

  DialogBox(
      {required this.festivalLatitude,
      required this.festivalLongitude,
      required this.festivalId,
      required this.what3words,
      required this.toiletId,
      required this.facilityName,
      required this.toiletLat,
      required this.toiletLng});

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width:
            MediaQuery.of(context).size.width * 0.8, // Adjust width as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Ensure the dialog takes minimum space needed
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.07,
              child: Center(
                child: Lottie.asset(
                  'assets/annim/doneLottie.json',
                  controller: _controller,
                ),
              ),
            ),
            IntrinsicHeight(
              child: Column(
                children: [
                  Text(
                    "Success",
                    style: TextStyle(
                      fontFamily: "Poppins-Bold",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    "Toilet Posted!",
                    style: TextStyle(
                      fontFamily: "Poppins-Medium",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  FadePageRouteBuilder(
                    widget: FeedbackScreen(
                      festivalId: widget.festivalId,
                      toiletId: widget.toiletId,
                      faciliyName: widget.facilityName,
                      toiletLat: widget.toiletLat,
                      toiletLng: widget.toiletLng,
                      what3words: widget.what3words,
                      festivalLatitude: widget.festivalLatitude, festivalLongitude: widget.festivalLongitude,
                    ),
                  ),
                );
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) => FeedbackScreen(
                //             festivalId: widget.festivalId,
                //             toiletId: widget.toiletId,
                //             faciliyName: widget.facilityName,
                //             toiletLat: widget.toiletLat,
                //             toiletLng: widget.toiletLng,
                //             what3words: widget.what3words,
                //             festivalLatitude: widget.festivalLatitude, festivalLongitude: widget.festivalLongitude,
                //           )),
                // );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "OK",
                    style: TextStyle(fontFamily: "Poppins-Bold"),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSuccessDialog(
    BuildContext context,
    String festivalId,
    String toiletId,
    String facilityName,
    double toiletLat,
    double toiletLng,
    String what3words,
    double festivalLatitude,
    double festivalLongitude) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return DialogBox(
        festivalId: festivalId,
        toiletId: toiletId,
        facilityName: facilityName,
        toiletLat: toiletLat,
        toiletLng: toiletLng,
        what3words: what3words,
        festivalLatitude: festivalLatitude,
        festivalLongitude: festivalLongitude,
      );
    },
  );
}
