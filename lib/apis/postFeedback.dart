import 'dart:convert';
import 'package:crapadvisor/screens/mainScreen.dart';
import 'package:crapadvisor/screens/userForm.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../annim/transiton.dart';
import '../models/feedbackModel.dart';

Future<void> postReview(ToiletReview review, BuildContext context) async {
  // API endpoint URL
  final String apiUrl = 'https://stagingcrapadvisor.semicolonstech.com/api/postFeedback';

  try {
    // Convert the review object to a JSON string
    String reviewJson = jsonEncode(review.toJson());

// Log the reviewJson string
    print('Review JSON: $reviewJson');

    // Make the POST request
    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: reviewJson,
    );

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // Parse the response JSON
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      // Check if the 'message' field contains the success message
      if (jsonResponse.containsKey('message') &&
          jsonResponse['message'] == 'Feedback Added Successfully') {
        print('Review posted successfully');
        _showSuccessDialog(context);
      } else {
        print('Failed to post review. Unexpected response: $jsonResponse');
      }
    } else {
      print('Failed to post review. Status code: ${response.statusCode}');
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
                            color: Colors.red,
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
    print('Error posting review: $e');
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
        width: MediaQuery
            .of(context)
            .size
            .width * 0.8, // Adjust width as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Ensure the dialog takes minimum space needed
          children: [
            Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.07,
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
                  SizedBox(height: 4,),
                  Text(
                    "Feedback Posted!",
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
                Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRouteBuilder(
                      widget:MainScreen(),
                    ),
                        (route) => false);
                // Navigator.push(
                //   context,
                //   FadePageRouteBuilder(
                //     widget:UserForm(),
                //   ),
                // );
                // Navigator.push(context,
                //   MaterialPageRoute(builder: (context) => UserForm()),
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

void _showSuccessDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return DialogBox();
    },
  );
}

