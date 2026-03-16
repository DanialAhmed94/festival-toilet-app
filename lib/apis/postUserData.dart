import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../screens/mainScreen.dart';

class DialogBox extends StatefulWidget {
  const DialogBox({super.key});

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: (2)),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if (_controller != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: SizedBox(
          width:
              MediaQuery.of(context).size.width * 0.8, // Adjust width as needed
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Ensure the dialog takes minimum space needed
            children: [
              IntrinsicHeight(
                child: Column(
                  children: [
                    Lottie.asset(
                      "assets/annim/user-submit.json",
                      controller: _controller,
                    ),
                    Text(
                      "Thank You!",
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
                      "We will notify you when our new app is online.",
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
                      MaterialPageRoute(builder: (context) => MainScreen()),
                      (route) => false);
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
      ),
    );
  }
}

void submitForm(BuildContext context, String email, String name,
    String lastName, String dob, String address) async {
  final String url =
      "https://stagingcrapadvisor.semicolonstech.com/api/postUser";
  try {
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode({
        "firstname": name,
        "lastname": lastName,
        "dob": dob,
        "email": email,
        "location": address
      }),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['status'] != 'error') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return DialogBox();
        },
      );
    } else {
      final errorList = responseData['errors']['email'];
      if (errorList != null && errorList.isNotEmpty) {
        final error = errorList[0];
        showErrorDialog(context, error?? "Something went wrong!!!");
      }
    }
  } catch (e) {
    showServerErrorDialog(context);
  }
}

showErrorDialog(BuildContext context, String errorMessage){
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
                      errorMessage,
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

void showServerErrorDialog(BuildContext context){
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