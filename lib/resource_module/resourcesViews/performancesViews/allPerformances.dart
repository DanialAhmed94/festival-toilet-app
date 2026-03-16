import 'package:crapadvisor/resource_module/resourcesViews/performancesViews/performanceDetail.dart';
import 'package:flutter/material.dart';
import 'package:crapadvisor/annim/transiton.dart';
import 'package:crapadvisor/resource_module/constants/appConstants.dart';
import 'package:provider/provider.dart';

import '../../providers/performanceProvider.dart';


class AllPerformances extends StatefulWidget {
  final String festivalId;
  AllPerformances({required this.festivalId});

  @override
  State<AllPerformances> createState() => _AllPerformancesState();
}

class _AllPerformancesState extends State<AllPerformances> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  void _fetchData() async {
    await Future.delayed(Duration.zero);
    Provider.of<PerformanceProvider>(context, listen: false)
        .fetchPerformanceCollection(context, widget.festivalId);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF45A3D9), Color(0xFF45D9D0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(60),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: const Text(
                    "Performances",
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
      body: Consumer<PerformanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Show a loading indicator while fetching data
            return Center(child: CircularProgressIndicator());
          }

          if (provider.performances == null || provider.performances!.data.isEmpty) {
            // Show a message if no performances are available
            return Center(
              child: Text(
                "No performances available.",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            );
          }

          // Display the list of performances
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.performances!.data.length,
            itemBuilder: (BuildContext context, int index) {
              final performance = provider.performances!.data[index];
              return GestureDetector(

                onTap: () => Navigator.push(
                  context,
                  FadePageRouteBuilder(widget: Performancedetail(performance: performance)),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Performance Icon
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF45A3D9), Color(0xFF45D9D0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              AppConstants.performanceIcon,
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Performance Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                performance.performanceTitle ?? "No Title",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                performance.artistName ?? "No Artist",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                performance.bandName ?? "No Band",
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
