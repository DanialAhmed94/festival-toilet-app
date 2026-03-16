// resource_module/resourcesViews/eventsViews/AllEvents.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../annim/transiton.dart';
import '../../constants/AppConstants.dart';
import '../../providers/eventsProvider.dart';
import '../eventsViews/eventDetail.dart'; // Make sure you have an EventDetail page

class AllEvents extends StatefulWidget {
  final String festivalId;

  AllEvents({required this.festivalId});

  @override
  State<AllEvents> createState() => _AllEventsState();
}

class _AllEventsState extends State<AllEvents> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    await Future.delayed(Duration.zero);
    Provider.of<EventProvider>(context, listen: false)
        .fetchEvents(context, widget.festivalId);
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
                    "Events",
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
      body: Consumer<EventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Show a loading indicator while fetching data
            return Center(child: CircularProgressIndicator());
          }
          if (provider.events.isEmpty) {
            // Show a message if no events are available
            return Center(
              child: Text(
                "No events available.",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            );
          }

          // Display the list of events
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.events.length,
            itemBuilder: (BuildContext context, int index) {
              final event = provider.events[index];
              return GestureDetector(
                onTap: (){
                  print("EventID ${event.id}");
                  Navigator.push(
                    context,
                    FadePageRouteBuilder(widget: EventDetail(event: event)),
                  );
                },
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
                        // Event Icon
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
                              AppConstants.eventIcon, // Make sure this icon exists
                              height: 40,
                              width: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Event Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.eventTitle ?? "No Title",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.eventDescription ?? "No Description",
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Start Time: ${event.startTime ?? "Not Available"}",
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
