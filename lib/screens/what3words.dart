import 'package:crapadvisor/widgets/what3wordsmap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/drawer.dart';

class What3WordsScreen extends StatefulWidget {
  final LatLng festivalLocation;
  final String festivalId;
  late final initialLat;
  late final initialLng;
  late final what3words;

  What3WordsScreen(
      {required this.what3words,
      required this.festivalLocation,
      required this.festivalId});

  @override
  State<What3WordsScreen> createState() => _What3WordsScreenState();
}

class _What3WordsScreenState extends State<What3WordsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: Text(
          'Festival Toilet',
          style: TextStyle(
            fontFamily: 'Poppins-Bold',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            'assets/svgs/back-icon.svg',
            fit: BoxFit.cover,
          ),
        ),
        // leading: Builder(builder: (BuildContext context) {
        //   return IconButton(
        //     icon: SvgPicture.asset(
        //       'assets/svgs/drawer-icon.svg',
        //       fit: BoxFit.cover,
        //     ),
        //     onPressed: () {
        //       Scaffold.of(context).openDrawer();
        //     },
        //   );
        // }),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none_outlined),
          ),
        ],
      ),
      // drawer: MyDrawer(),
      body: MapScreen(
        intialCameraPosition: LatLng(widget.festivalLocation.latitude,
            widget.festivalLocation.longitude),
        festivalId: widget.festivalId,
        what3words: widget.what3words,
        festivalLatitude: widget.festivalLocation.latitude,
        festivalLongitude: widget.festivalLocation.longitude,
      ),
    );
  }
}
