import 'package:flutter/material.dart';

import '../apis/getToilet.dart';
import '../model/toiletModel.dart';

class ToiletProvider extends ChangeNotifier {
  List<ToiletData> _toilets = [];
  int _totalToilets = 0;
  bool _isLoading = false;

  List<ToiletData> get toilets => _toilets;
  int get totalToilets => _totalToilets;
  bool get isLoading => _isLoading;

  // Fetch toilets and update the list and total count
  Future<void> fetchToilets(BuildContext context,String festivalId) async {
    _isLoading = true;
    notifyListeners();
    final response = await getToiletCollection(context,festivalId); // Assuming getToiletCollection is your API method

    if (response != null) {
      _toilets = response.data;
      _totalToilets = response.data.length; // Assuming total is the length of the data array
      _isLoading = false;
      notifyListeners(); // Notify listeners when data is updated
    }
    else{
      _isLoading = false;
      notifyListeners();
    }
  }
}
