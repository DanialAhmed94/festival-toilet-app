import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../apis/fetchFacilityType.dart';
import '../apis/postToilet.dart';
import '../models/facilityType_model.dart';
import '../widgets/drawer.dart';

class SelectFacility extends StatefulWidget {
  final festivalLatitude;
  final festivalLongitude;
  final double toiletLat;
  final double toiletLng;
  final String toiletWhat3words;
  final String festivalid;

  SelectFacility({
    required this.toiletLat,
    required this.festivalLongitude,
    required this.festivalLatitude,
    required this.toiletLng,
    required this.toiletWhat3words,
    required this.festivalid,
  });

  @override
  State<SelectFacility> createState() => _SelectFacilityState();
}

class _SelectFacilityState extends State<SelectFacility> {
  // Step 1: Create a GlobalKey for the ScaffoldState
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late String toiletTypeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Step 2: Assign the GlobalKey to your Scaffold
      key: _scaffoldKey,
      // drawer: MyDrawer(),
      body: Stack(
        children: [
          // Background image that covers part of the screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/slectFacilityBackground.png',
              fit: BoxFit.fill,
              height: MediaQuery.of(context).size.height * 0.85,
            ),
          ),
          // Main content
          Column(
            children: [
              SizedBox(height: 23),
              // Custom AppBar
              Container(
                height: 75, // Toolbar height
                child: Stack(
                  children: [
                    // Centered Title
                    Center(
                      child: Text(
                        'Select Facility',
                        style: TextStyle(
                          fontFamily: 'Poppins-Bold',
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    // Leading icon
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: SvgPicture.asset(
                          'assets/svgs/back-icon.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // child: IconButton(
                      //   icon: SvgPicture.asset(
                      //     'assets/svgs/drawer-icon.svg',
                      //     fit: BoxFit.cover,
                      //   ),
                      //   onPressed: () {
                      //     // Step 3: Use the GlobalKey to open the drawer
                      //     _scaffoldKey.currentState!.openDrawer();
                      //   },
                      // ),
                    ),
                    // Actions
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.notifications_none_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              // The rest of the content
              Expanded(
                child: FutureBuilder<FacilityTypes>(
                  future: fetchFacilityTypeData(
                    "https://stagingcrapadvisor.semicolonstech.com/api/getToiletType",
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else {
                      List<Facility> facilityList = snapshot.data!.facilityList;
                      return GridView.builder(
                        padding: EdgeInsets.only(top: 16),
                        // Add padding as needed
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                        ),
                        itemCount: facilityList.length,
                        itemBuilder: (context, index) {
                          Facility facility = facilityList[index];
                          return GestureDetector(
                            child: GridTile(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 4, right: 4, top: 4, bottom: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: Image.network(
                                              "https://stagingcrapadvisor.semicolonstech.com/asset/toilet_types/" +
                                                  facility.image,
                                              fit: BoxFit.fill,
                                              loadingBuilder:
                                                  (BuildContext context,
                                                      Widget child,
                                                      ImageChunkEvent?
                                                          loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child; // Return the image if it's loaded

                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            (loadingProgress
                                                                    .expectedTotalBytes ??
                                                                1)
                                                        : null, // Show progress if we know the total bytes
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  "assets/images/test-toiletType.jpeg",
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        flex: 2,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Stroke Text (white outline)
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                facility.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily:
                                                      "Poppins-SemiBold",
                                                  fontSize: 16,
                                                  foreground: Paint()
                                                    ..style =
                                                        PaintingStyle.stroke
                                                    ..strokeWidth = 1.2
                                                    ..color = Colors.white,
                                                ),
                                                textHeightBehavior:
                                                    TextHeightBehavior(
                                                  applyHeightToFirstAscent:
                                                      false,
                                                  applyHeightToLastDescent:
                                                      false,
                                                ),
                                              ),
                                            ),
                                            // Solid Text (black fill)
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                facility.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily:
                                                      "Poppins-SemiBold",
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                                textHeightBehavior:
                                                    TextHeightBehavior(
                                                  applyHeightToFirstAscent:
                                                      false,
                                                  applyHeightToLastDescent:
                                                      false,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              postToilet(
                                context,
                                widget.festivalLatitude,
                                widget.festivalLongitude,
                                widget.toiletLat,
                                widget.toiletLng,
                                widget.toiletWhat3words,
                                widget.festivalid,
                                facility.id.toString(),
                                facility.name.toString(),
                              );
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<FacilityTypes> fetchFacilityTypeData(String url) async {
    return fetchFacilityType(url);
  }
}
