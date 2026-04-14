import 'package:flutter/material.dart';
import 'package:crapadvisor/widgets/drawer.dart';
import 'package:flutter_svg/svg.dart';
import '../annim/transiton.dart';
import '../resource_module/HomeView.dart';
import '../resource_module/appSelectionView.dart';
import '../resource_module/engageDownloadView.dart';
import '../resource_module/utilities/sharedPrefs.dart';
import '../services/getuseraddres.dart';
import '../widgets/googlemap.dart';
import '../services/location_service.dart';
import 'package:app_settings/app_settings.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  DateTime? currentBackPressTime;
  Future<String>? _addressFuture; // ① Store the future here

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Kick off the first address lookup
    _addressFuture = getUserAddress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ② Re-fetch address whenever the app/screen is resumed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      setState(() {
        _addressFuture = getUserAddress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentBackPressTime == null ||
            DateTime.now().difference(currentBackPressTime!) >
                Duration(seconds: 2)) {
          currentBackPressTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          title: Text(
            'The Festival Toilet',
            style: TextStyle(
              fontFamily: 'Poppins-Bold',
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: Builder(builder: (BuildContext context) {
            return IconButton(
              icon: SvgPicture.asset(
                'assets/svgs/drawer-icon.svg',
                fit: BoxFit.cover,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () async {
                  bool isLoggedIn = (await getIsLogedIn()) ?? false;
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
                child: Image.asset(
                  "assets/images/festivalResourceLogo.png",
                  height: 40,
                  width: 40,
                ),
              ),
            ),
          ],
        ),
        drawer: MyDrawer(),
        body: FutureBuilder<bool>(
          future: _checkServices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.data == false) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Please enable internet and location services.',
                        style: const TextStyle(
                          fontFamily: 'Poppins-SemiBold',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          AppSettings.openAppSettings(
                              type: AppSettingsType.location);
                        },
                        child: const Text("Open Location Settings"),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Stack(
                children: [
                  GoogleMapWidget(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF45A3D9),
                            Color(0xFF45D9D0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20.0),
                          bottomLeft: Radius.circular(20.0),
                        ),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Location",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 8.0),
                          // ③ Use the state variable here instead of calling the function directly
                          FutureBuilder<String>(
                            future: _addressFuture,
                            builder: (context, addressSnapshot) {
                              if (addressSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              } else if (addressSnapshot.hasError) {
                                return Text('Error getting user address');
                              } else {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        addressSnapshot.data ??
                                            'Unknown Address',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins-SemiBold',
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Future<bool> _checkServices() async {
    bool isInternetConnected = await checkInternetConnection();
    bool isLocationServiceEnabled = await checkLocationService();
    return isInternetConnected && isLocationServiceEnabled;
  }
}
