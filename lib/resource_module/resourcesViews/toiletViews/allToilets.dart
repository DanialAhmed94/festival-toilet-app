// resource_module/resourcesViews/toiletsViews/AllToilets.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crapadvisor/resource_module/resourcesViews/toiletViews/toiletDetail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../annim/transiton.dart';
import '../../providers/toiletProvider.dart';
import '../../constants/AppConstants.dart';
import '../KidsActivitiesViews/activityDetail.dart';
// import 'toiletDetail.dart'; // Uncomment if you have a ToiletDetail page

class AllToilets extends StatefulWidget {
  final String festivalId;

  AllToilets({required this.festivalId});

  @override
  _AllToiletsState createState() => _AllToiletsState();
}

class _AllToiletsState extends State<AllToilets> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    await Future.delayed(Duration.zero);
    Provider.of<ToiletProvider>(context, listen: false)
        .fetchToilets(context, widget.festivalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        // Custom height for the AppBar
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
                      Navigator.pop(context); // Go back to previous screen
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: const Text(
                    "Toilets",
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
      body: Consumer<ToiletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Show a loading indicator while fetching data
            return Center(child: CircularProgressIndicator());
          }

          if (provider.toilets.isEmpty) {
            // Show a message if no toilets are available
            return Center(
              child: Text(
                "No toilets available.",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            );
          }

          // Display the list of toilets
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.toilets.length,
            itemBuilder: (BuildContext context, int index) {
              final toilet = provider.toilets[index];
              return GestureDetector(
                // Uncomment and adjust if you have a ToiletDetail page
                // onTap: () => Navigator.push(
                //   context,
                //   FadePageRouteBuilder(widget: ToiletDetail(toilet: toilet)),
                // ),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    FadePageRouteBuilder(widget: ToiletDetail(toilet: toilet)),
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    // Space between cards
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Rounded corners
                    ),
                    elevation: 5,
                    // Card shadow elevation
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      width: MediaQuery.of(context).size.width * 0.93,
                      height: MediaQuery.of(context).size.height * 0.11,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Container(
                              width: 50.0, // Container width
                              height: 50.0, // Container height
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF45A3D9), // Gradient start
                                    Color(0xFF45D9D0), // Gradient end
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape
                                    .circle, // Ensures the container is circular
                              ),
                              child: ClipOval(
                                // Clips the image to ensure it has a circular shape
                                child: CachedNetworkImage(
                                  imageUrl:
                                      "https://stagingcrapadvisor.semicolonstech.com/asset/toilet_types/" +
                                          toilet.toiletType!.image,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    "assets/icons/finalLogo.jpg",height: 50,width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              toilet.toiletType!.name ?? "",
                              // Use appropriate model field
                              style: TextStyle(
                                fontFamily: "UbuntuMedium",
                                fontSize: 15,
                                fontWeight: FontWeight.bold
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
