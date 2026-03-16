
import 'package:crapadvisor/resource_module/resourcesViews/KidsActivitiesViews/activityDetail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../annim/transiton.dart';
import '../../constants/AppConstants.dart';
import '../../providers/activitesProvider.dart';


class AllActivities extends StatefulWidget {
  final String festivalId; // Accepting festivalId for API call

  const AllActivities({super.key, required this.festivalId});

  @override
  State<AllActivities> createState() => _AllActivitiesState();
}

class _AllActivitiesState extends State<AllActivities> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    await Future.delayed(Duration.zero);
    Provider.of<ActivityProvider>(context, listen: false)
        .fetchActivities(context, widget.festivalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Custom height for the AppBar
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF45A3D9), // Color at 0% stop
                Color(0xFF45D9D0), // Color at 100% stop
              ],
              begin: Alignment.topLeft, // Start gradient from top left
              end: Alignment.bottomRight, // End gradient at bottom right
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20), // Right-side circular corner
              bottomRight: Radius.circular(60), // Right-side circular corner
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous screen
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: const Text(
                    "Kids Activities",
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
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Show a loading indicator while fetching data
            return Center(child: CircularProgressIndicator());
          }
          if (provider.activities.isEmpty) {
            // Show a message if no activities are available
            return Center(
              child: Text(
                "No activities available.",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            );
          }

          // Display the list of activities
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.activities.length,
            itemBuilder: (BuildContext context, int index) {
              final activity = provider.activities[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  FadePageRouteBuilder(widget: ActivityDetail(activity: activity)),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16), // Space between cards
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                  ),
                  elevation: 5, // Card shadow elevation
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Container with gradient and activity icon
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF45A3D9), // Gradient start
                                Color(0xFF45D9D0), // Gradient end
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          child: Center(
                            child: Image.asset(
                              AppConstants.festivalIcon, // Replace with appropriate icon
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Spacing between the icon and text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.activityTitle ?? "No Title",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activity.description ?? "No Description",
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Start Time: ${activity.startTime ?? "Not Available"}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:crapadvisor/annim/transiton.dart';
// import 'package:crapadvisor/resource_module/constants/appConstants.dart';
//
//
// class AllActivities extends StatelessWidget {
//   const AllActivities({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(80), // Custom height for the AppBar
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF45A3D9), // Color at 0% stop
//                 Color(0xFF45D9D0), // Color at 100% stop
//               ],
//               begin: Alignment.topLeft, // Start gradient from top left
//               end: Alignment.bottomRight, // End gradient at bottom right
//             ),
//             borderRadius: BorderRadius.only(
//               topRight: Radius.circular(20), // Right-side circular corner
//               bottomRight: Radius.circular(60), // Right-side circular corner
//             ),
//           ),
//           child: SafeArea(
//             child: Stack(
//               children: [
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () {
//                       Navigator.pop(context); // Go back to previous screen
//                     },
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.center,
//                   child: const Text(
//                     "All Kids Activities",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: 10, // Number of festival cards to display
//         itemBuilder: (BuildContext context, int index) {
//           return GestureDetector(
//             // onTap: () => Navigator.push(
//             //   context,
//             //   FadePageRouteBuilder(widget: const FestivalDetail()), // Navigate to the festival details page
//             // ),
//             child: Card(
//               margin: const EdgeInsets.only(bottom: 16), // Space between cards
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15), // Rounded corners
//               ),
//               elevation: 5, // Card shadow elevation
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Container with gradient and festival icon
//                     Container(
//                       height: 60,
//                       width: 60,
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [
//                             Color(0xFF45A3D9), // Gradient start
//                             Color(0xFF45D9D0), // Gradient end
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12), // Rounded corners
//                       ),
//                       child: Center(
//                         child: Image.asset(AppConstants.festivalIcon, height: 40, width: 40), // Festival icon
//                       ),
//                     ),
//                     const SizedBox(width: 16), // Spacing between the icon and text
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Reading Festival",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             "This is a brief description of festival. It gives an overview of the event.",
//                             style: TextStyle(fontSize: 14),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
