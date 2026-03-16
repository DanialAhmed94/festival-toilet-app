import 'package:crapadvisor/annim/transiton.dart';
import 'package:crapadvisor/resource_module/resourcesViews/toiletViews/allToilets.dart';
import 'package:flutter/material.dart';

import '../constants/appConstants.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'KidsActivitiesViews/allActivites.dart';
import 'eventsViews/allEvents.dart';
import 'newsViews/allNews.dart';
import 'performancesViews/allPerformances.dart';
class Resourcehomeview extends StatelessWidget {
  final String festivalId;
  String festivalName;
  Resourcehomeview({required this.festivalId,required this.festivalName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white.withOpacity(0.9),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppConstants.homeBG,
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height * 0.75,
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: AppBar(
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              title: Text( maxLines: 1, // Limits the text to 2 lines to prevent excessive height
                overflow: TextOverflow.ellipsis, // Adds ellipsis for overflow
                textAlign: TextAlign.center,
                "${festivalName} Resources",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            bottom: 0,
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              itemCount: 5,
              itemBuilder: (BuildContext context, int index) {
                return _buildGridItem(context, index);
              },
            ),
          ),


        ],
      ),
    );
  }
  Widget _buildGridItem(BuildContext context, int index) {
    List<String> titles = ["News", "Performance", "Event", "Toilet", "Kids Activities"];
    List<String> imageAssets = [
      AppConstants.newsIcon,
      AppConstants.performanceIcon,
      AppConstants.eventIcon, // Assuming you have different icons
      AppConstants.toiletIcon,
      AppConstants.festivalIcon,
    ];
    List<Color> containerColors = [
      Color(0xFF1D86CA),

      Color(0xFFF97316),
      Color(0xFF06B6D4)
      ,
      Color(0xFF8B5CF6)
      ,
      Color(0xFF514EFF)

    ];
    List<Widget> screens = [
      AllNews(),
      AllPerformances(festivalId: festivalId,),
      AllEvents(festivalId: festivalId,),
      AllToilets(festivalId: festivalId,),
      AllActivities(festivalId: festivalId,),
    ];

    // Determine the properties based on the index
    bool isBlue = index == 0 || index == 3|| index == 4;
    double containerHeight = isBlue
        ? MediaQuery.of(context).size.height * 0.15
        : MediaQuery.of(context).size.height * 0.17;

    double padding = isBlue
        ? 10
        : 25;
    return GestureDetector(
      onTap: ()=> Navigator.push(context,FadePageRouteBuilder(widget: screens[index])),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Container(
              height: containerHeight,
              width: MediaQuery.of(context).size.width * 0.3,
              decoration: BoxDecoration(
                color: containerColors[index],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Image.asset(
                  imageAssets[index],
                  height: 80,
                  width: 80,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              titles[index],
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: padding),
      
          ],
        ),
      ),
    );
  }

}
