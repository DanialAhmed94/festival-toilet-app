import 'package:flutter/material.dart';

import '../../models/festivalsDetail_model.dart';
import '../apis/getFestivals.dart';
import '../model/festivalsModel.dart';

// Import your model

class FestivalProvider extends ChangeNotifier {
  List<FestivalResource> _resourceFestivals = [];
  int _totalFestivals = 0;
  int _totalAttendees = 0;

  List<FestivalResource> get resourceFestivals => _resourceFestivals;

  int get totalFestivals => _totalFestivals;

  int get totalAttendees => _totalAttendees;

  // Fetch festivals and update the list, total attendees, and total festivals
  Future<void> fetchFestivals(BuildContext context) async {
    final response = await getFestivalCollection(context);

    if (response != null) {
      _resourceFestivals = response.data;


      notifyListeners(); // Notify listeners when data is updated
    }
  }
}
