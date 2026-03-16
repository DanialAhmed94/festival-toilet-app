import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/facilityType_model.dart';

class FacilityNameProvider extends ChangeNotifier {
  FacilityNameProvider() {
    fetchData(); // Call fetchData method when the provider is initialized
  }

  late List<Facility> dataList = [];

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        "https://stagingcrapadvisor.semicolonstech.com/api/getToiletType"));

    if (response.statusCode == 200) {
      // Parse the JSON directly into the dataList
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      FacilityTypes facilityTypes = FacilityTypes.fromJson(jsonResponse);
      dataList = facilityTypes.facilityList;
      // Notify listeners that data has been updated
    } else {
      throw Exception('Failed to load facility type');
    }
  }
  String getFacilityTypeNameById(String id) {
    // Search for the facility with the given ID in the dataList
    Facility facility = dataList.firstWhere((facility) => facility.id.toString() == id);
    // Return the name if facility is found, otherwise return null
    notifyListeners();
    return  facility.name;
  }

}
