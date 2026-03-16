// providers/eventProvider.dart

import 'package:flutter/material.dart';

import '../apis/getEvents.dart'; // Adjust the import path if necessary
import '../model/eventModel.dart'; // Adjust the import path if necessary

class EventProvider extends ChangeNotifier {
  List<EventData> _events = [];
  bool _isLoading = false;

  List<EventData> get events => _events;
  bool get isLoading => _isLoading;

  // Fetch events and update the list
  Future<void> fetchEvents(BuildContext context, String festivalId) async {
    _isLoading = true;
    notifyListeners();
    final response = await getEventsCollection(context, festivalId);

    if (response != null) {
      _events = response.data;
      _isLoading = false;
      notifyListeners(); // Notify listeners when data is updated
    }
    else{
      _isLoading = false;
      notifyListeners();
    }
  }
}
