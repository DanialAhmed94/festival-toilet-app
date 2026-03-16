import 'package:crapadvisor/screens/mainScreen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../resource_module/appSelectionView.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videController;

  @override
  void initState() {
    super.initState();
    _videController = VideoPlayerController.asset("assets/videos/splashVideo.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videController.play();
        _videController.addListener(() {
          if (_videController.value.duration == _videController.value.position) {
            // Video playback has ended
            _navigateToMainScreen();
          }
        });
      });
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AppSelectionView()),
    );
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _videController =
  //       VideoPlayerController.asset("assets/videos/splashVideo.mp4");
  //   _videController.initialize().then((_) {
  //     setState(() {});
  //   });
  //   _videController.play();
  // }

  @override
  void dispose() {
    super.dispose();
    _videController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: _videController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videController.value.aspectRatio,
          child: VideoPlayer(_videController),
        )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

//          lotty code

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'mainScreen.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(seconds: (2)),
//       vsync: this,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Lottie.asset(
//         'assets/annim/toilet.json',
//         controller: _controller,
//         height: MediaQuery
//             .of(context)
//             .size
//             .height * 1,
//         animate: true,
//         onLoaded: (composition) {
//           _controller.duration = composition.duration;
//             _controller.forward().whenComplete(() {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => MainScreen()),
//               );
//             });
//
//           },
//
//       ),
//     );
//   }
// }
//
//
