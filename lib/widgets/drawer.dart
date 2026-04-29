import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../annim/transiton.dart';
import '../resource_module/HomeView.dart';
import '../resource_module/appSelectionView.dart';
import '../resource_module/utilities/sharedPrefs.dart';
import '../screens/mainScreen.dart';
import '../screens/ratingsScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  final String feedbackEmail = 'astraldesignapp@gmail.com';

  void _sendFeedback(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      query: encodeQueryParameters(<String, String>{
        'subject': 'Feedback',
        'body': 'App Feedback:',
      }),
    );

    try {
      bool launched = await launch(emailLaunchUri.toString());

      if (!launched) {
        // If launching the default email client fails, try opening other installed email applications
        await _openOtherEmailApps();
      }
    } catch (error) {
      // If an error occurs during either attempt, show an error message
      _showErrorDialog(
          context, 'An error occurred while trying to send feedback.');
    }
  }

  Future<void> _openOtherEmailApps() async {
    // List of known email application package names on Android
    final List<String> emailApps = [
      'com.google.android.gm', // Gmail
      'com.microsoft.office.outlook', // Outlook
      // Add more package names for other email apps if needed
    ];

    // Iterate through the list of email apps and try to open them
    for (final String packageName in emailApps) {
      final String url = 'package:$packageName';

      if (await canLaunch(url)) {
        await launch(url);
        return;
      }
    }
    // If no known email apps are found, show an error message
    throw 'No email application is available.';
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
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

  void _showUpCommingProducts(BuildContext context) {
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
                        " Amazing Products Coming Soon!",
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/drawerBackground.png'), // Change this to your image path
            fit: BoxFit.cover, // Control how the image scales
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Text(
                "Hello Festival Toilet",
                style: TextStyle(fontFamily: 'Poppins-Bold'),
              ),
              automaticallyImplyLeading: false,
            ),

            // Wrap each ListTile with a GestureDetector
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  FadePageRouteBuilder(
                    widget: MainScreen(),
                  ),
                );
                // Navigator.push(context,
                //     MaterialPageRoute(builder: (context) => MainScreen()));
              },
              child: ListTile(
                title: Text(
                  "Home",
                  style: TextStyle(fontFamily: 'Poppins-Medium'),
                ),
                leading: Icon(Icons.home_outlined),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  FadePageRouteBuilder(
                    widget: FestivalList(),
                  ),
                );
                // Navigator.push(context,
                //     MaterialPageRoute(builder: (context) => FestivalList()));
              },
              child: ListTile(
                title: Text(
                  "Toilet Ratings",
                  style: TextStyle(fontFamily: 'Poppins-Medium'),
                ),
                leading: Icon(Icons.dashboard_customize_outlined),
              ),
            ),
            // SizedBox(
            //   height: 10,
            // ),
            // GestureDetector(
            //   onTap: () {},
            //   child: ListTile(
            //     title: Text(
            //       "Share App",
            //       style: TextStyle(fontFamily: 'Poppins-Medium'),
            //     ),
            //     leading: Icon(Icons.share),
            //   ),
            // ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                _sendFeedback(context);
              },
              child: ListTile(
                title: Text(
                  "Feedback",
                  style: TextStyle(fontFamily: 'Poppins-Medium'),
                ),
                leading: Icon(Icons.feedback_outlined),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () async {
                bool isLoggedIn =
                    (await getIsLogedIn()) ?? false; // Default to false if null

                if (isLoggedIn) {
                  Navigator.push(
                    context,
                    FadePageRouteBuilder(widget: HomeView()),
                  );
                } else {
                  Navigator.push(
                    context,
                    FadePageRouteBuilder(widget: AppSelectionView()),
                  );
                }
              },
              child: ListTile(
                title: Text(
                  "Festival Resource",
                  style: TextStyle(fontFamily: 'Poppins-Medium'),
                ),
                leading: Image.asset(
                  "assets/images/festivalResourceLogo.png",
                  height: 50,
                  width: 50,
                ),
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     _showUpCommingProducts(context);
            //   },
            //   child: ListTile(
            //     title: Text(
            //       "Upcoming Products",
            //       style: TextStyle(fontFamily: 'Poppins-Medium'),
            //     ),
            //     leading: Icon(Icons.watch_later_outlined),
            //   ),
            // ),
            // Spacer(),
            // Row(
            //   children: [
            //     Padding(
            //       padding: EdgeInsets.only(right: 8.0, left: 18.0),
            //       // Adjust the right padding based on your preference
            //       child: SvgPicture.asset(
            //         'assets/svgs/logo-crap.svg',
            //         height: 80,
            //         width: 80,
            //         fit: BoxFit.contain,
            //       ),
            //     ),
            //     Text(
            //       "Crap Adviser",
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //         shadows: [
            //           Shadow(
            //             offset: Offset(2.0, 2.0),
            //             blurRadius: 5.0,
            //             color: Colors.black.withOpacity(0.5),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
//
// import '../screens/mainScreen.dart';
// import '../screens/reviewsScreen.dart';
//
// class My_Drawer extends StatelessWidget {
//   const My_Drawer({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Column(
//         children: [
//           AppBar(
//             title: Text(
//               "Hello Crap Advisor",
//               style: TextStyle(fontFamily: 'Poppins-Bold'),
//             ),
//             automaticallyImplyLeading: false,
//           ),
//           Divider(),
//           ListTile(
//             title: Text(
//               "Home",
//               style: TextStyle(fontFamily: 'Poppins-Medium'),
//             ),
//             leading: IconButton(
//                 onPressed: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => MainScreen()));
//                 },
//                 icon: Icon(Icons.home_outlined)),
//           ),
//           SizedBox(
//             height: 10,
//           ),
//           ListTile(
//             title: Text(
//               " Toilet Ratings",
//               style: TextStyle(fontFamily: 'Poppins-Medium'),
//             ),
//             leading: IconButton(
//               onPressed: () {
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => Reviews()));
//               },
//               icon: Icon(Icons.dashboard_customize_outlined),
//             ),
//           ),
//           SizedBox(
//             height: 10,
//           ),
//           ListTile(
//             title: Text(
//               " Share App",
//               style: TextStyle(fontFamily: 'Poppins-Medium'),
//             ),
//             leading: IconButton(onPressed: () {}, icon: Icon(Icons.share)),
//           ),
//           SizedBox(
//             height: 10,
//           ),
//           ListTile(
//             title: Text(
//               " Feedback",
//               style: TextStyle(fontFamily: 'Poppins-Medium'),
//             ),
//             leading: IconButton(
//                 onPressed: () {}, icon: Icon(Icons.feedback_outlined)),
//           ),
//           SizedBox(
//             height: 10,
//           ),
//           ListTile(
//             title: Text(
//               " Upcoming Products",
//               style: TextStyle(fontFamily: 'Poppins-Medium'),
//             ),
//             leading: IconButton(
//                 onPressed: () {}, icon: Icon(Icons.watch_later_outlined)),
//           ),
//           Spacer(),
//           Row(
//             children: [
//               Padding(
//                 padding: EdgeInsets.only(right: 8.0, left: 18.0),
//                 // Adjust the right padding based on your preference
//                 child: SvgPicture.asset(
//                   'assets/svgs/logo-crap.svg',
//                   height: 80,
//                   width: 80,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               Text(
//                 "Crap Adviser",
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     shadows: [
//                       Shadow(
//                         offset: Offset(2.0, 2.0),
//                         blurRadius: 5.0,
//                         color: Colors.black.withOpacity(0.5),
//                       ),
//                     ]),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }
