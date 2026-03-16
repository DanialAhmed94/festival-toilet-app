import 'package:crapadvisor/resource_module/HomeView.dart';
import 'package:crapadvisor/resource_module/utilities/sharedPrefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../annim/transiton.dart';
import '../screens/mainScreen.dart';
import '../socialMedia/socialpstview.dart';
import 'constants/appConstants.dart';
import 'engageDownloadView.dart';

class AppSelectionView extends StatelessWidget {
  const AppSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain screen dimensions
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.04; // 4% padding

    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SvgPicture.asset(
              AppConstants.appSelectionScreenBg,
              fit: BoxFit.cover,
            ),
          ),
          // Main Content with SingleChildScrollView
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Information Container
                  Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Column(
                      children: [
                        // Crap Advisor Section
                        _buildAppInfoSection(
                          title: "Festival Toilet:",
                          description:
                              "Discover and review clean festival toilets to make informed decisions. Upload reviews of your download and promote a better festival experience for everyone.",
                          logoPath: AppConstants.crapLogo,
                          logoSize: size.width * 0.2, // 20% of screen width
                        ),
                        SizedBox(height: padding),
                        // FestivalResource Section
                        _buildAppInfoSection(
                          title: "FestivalResource:",
                          description:
                              "Explore future events, performances, and more to plan your ultimate festival experience.",
                          logoPath: AppConstants.userAppLogo,
                          logoSize: size.width * 0.175, // 17.5% of screen width
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: padding * 1),

                  GestureDetector(
                    onTap: () async {
                      bool isLoggedIn = (await getIsLogedIn()) ??
                          false; // Default to false if null

                      if (isLoggedIn) {
                        Navigator.push(
                          context,
                          FadePageRouteBuilder(widget: SocialMediaHomeView()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          FadePageRouteBuilder(widget: EngagedownloadView()),
                        );
                      }
                    },
                    child: Image.asset(
                      "assets/images/festivalGlobalfeed.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: padding * 1),

                  // App Selection Row
                  Row(
                    children: [
                      // First App Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                              FadePageRouteBuilder(widget: MainScreen())),
                          child: Container(
                            // 25% of screen height
                            margin: EdgeInsets.only(right: padding / 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                AppConstants.app1Card,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Second App Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            bool isLoggedIn = (await getIsLogedIn()) ??
                                false; // Default to false if null

                            if (isLoggedIn) {
                              Navigator.push(
                                context,
                                FadePageRouteBuilder(widget: HomeView()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                FadePageRouteBuilder(
                                    widget: EngagedownloadView()),
                              );
                            }
                          },
                          child: Container(
                            // 25% of screen height
                            margin: EdgeInsets.only(left: padding / 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                AppConstants.app2Card,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Optional: Additional content can be added here
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the app information section
  Widget _buildAppInfoSection({
    required String title,
    required String description,
    required String logoPath,
    required double logoSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        // Logo Image
        Container(
          width: logoSize,
          height: logoSize,
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

// import 'package:crapadvisor/resource_module/HomeView.dart';
// import 'package:crapadvisor/resource_module/utilities/sharedPrefs.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../annim/transiton.dart';
// import '../screens/mainScreen.dart';
// import 'constants/appConstants.dart';
// import 'engageDownloadView.dart';
//
// class AppSelectionView extends StatelessWidget {
//   const AppSelectionView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: SvgPicture.asset(
//               AppConstants.appSelectionScreenBg,
//               fit: BoxFit.cover,
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).size.height * 0.1,
//             left: 0,
//             right: 0,
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Container(
//                       height: MediaQuery.of(context).size.height * 0.35,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         color: Colors.white,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: const [
//                                       Text(
//                                         "Crap Advisor:",
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       SizedBox(height: 10),
//                                       Text(
//                                         "Discover and review clean festival toilets to make informed decisions. Upload reviews of your download and promote a better festival experience for everyone.",
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(width: 16),
//                                 Image.asset(
//                                   AppConstants.crapLogo,
//                                   height: 80,
//                                   width: 80,
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 18),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: const [
//                                       Text(
//                                         "FestivalResource:",
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       SizedBox(height: 10),
//                                       Text(
//                                         "Explore future events, performances, and more to plan your ultimate festival experience.",
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(width: 16),
//                                 Image.asset(
//                                   AppConstants.userAppLogo,
//                                   height: 70,
//                                   width: 70,
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: GestureDetector(
//                           onTap: () => Navigator.push(context,
//                               FadePageRouteBuilder(widget: MainScreen())),
//                           child: Container(
//                             height: MediaQuery.of(context).size.height * 0.5,
//                             width: MediaQuery.of(context).size.width * 0.45,
//                             child: Image.asset(AppConstants.app1Card),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: GestureDetector(
//                           onTap: () async {
//                             bool isLoggedIn = (await getIsLogedIn()) ?? false; // Default to false if null
//
//                             if (isLoggedIn) {
//                               Navigator.pushAndRemoveUntil(
//                                 context,
//                                 FadePageRouteBuilder(widget: HomeView()), (Route<dynamic> route) => false,
//                               );
//                             } else {
//                               Navigator.push(
//                                 context,
//                                 FadePageRouteBuilder(widget: EngagedownloadView()),
//                               );
//                             }
//                           },
//
//                           child: Container(
//                             height: MediaQuery.of(context).size.height * 0.5,
//                             width: MediaQuery.of(context).size.width * 0.45,
//                             child: Image.asset(AppConstants.app2Card),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
