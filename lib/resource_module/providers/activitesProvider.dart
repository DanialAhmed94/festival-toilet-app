
import 'package:flutter/material.dart';

import '../apis/getActivites.dart';
import '../model/activitiesModel.dart';

class ActivityProvider extends ChangeNotifier {
  List<ActivityData> _activities = [];
  bool _isLoading = false;

  List<ActivityData> get activities => _activities;
  bool get isLoading => _isLoading;

  // Fetch activities and update the list
  Future<void> fetchActivities(BuildContext context, String festivalId) async {
    _isLoading = true;
    notifyListeners();

    final response = await getActivitiesCollection(context, festivalId);

    if (response != null) {
      _activities = response.data;
    }

    _isLoading = false;
    notifyListeners();
  }
}
