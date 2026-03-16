import 'package:crapadvisor/resource_module/views/authViews/SignupView.dart';
import 'package:flutter/material.dart';

import '../annim/transiton.dart';
import 'constants/appConstants.dart';

class EngagedownloadView extends StatefulWidget {
  const EngagedownloadView({super.key});

  @override
  _EngagedownloadViewState createState() => _EngagedownloadViewState();
}

class _EngagedownloadViewState extends State<EngagedownloadView> {
  @override
  void initState() {
    super.initState();
    // Delay of 2 seconds before navigating to the next screen
    Future.delayed(const Duration(seconds: 2), () {
      // Replace 'NextScreen' with your desired screen widget
      Navigator.pushReplacement(
        context,
        FadePageRouteBuilder(widget: SignupView()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppConstants.engageDownload,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

// Dummy NextScreen widget for navigation, replace this with your actual next screen

