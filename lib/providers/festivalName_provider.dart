import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/festivalsDetail_model.dart';

class FestivalNameProvider extends ChangeNotifier {
  FestivalNameProvider() {
    _fetchFestivalsIfNeeded();
  }

  late List<Festival> _festivals = [];
  bool _fetchedFestivals = false;

  Future<void> _fetchFestivalsIfNeeded() async {
    if (!_fetchedFestivals) {
      await fetchFestivals();
      _fetchedFestivals = true;
    }
  }

  Future<void> fetchFestivals() async {
    final response = await http.get(Uri.parse(
        "https://stagingcrapadvisor.semicolonstech.com/api/getfestival"));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      Festivals festivalsData = Festivals.fromJson(data);
      _festivals = festivalsData.data;
    } else {
      throw Exception('Failed to load festivals');
    }
    notifyListeners();
  }

  Future<String> getFestivalName(int festivalId) async {
    await _fetchFestivalsIfNeeded();
    Festival? festival = _festivals.firstWhere(
          (element) => element.id.toString() == festivalId.toString(),
    );

    if (festival != null) {
      // Check if description is "-N/A" and return accordingly
      return
           festival.nameOrganizer ?? festival.description; // Default value if description is null
    } else {
      return 'Unknown Festival';
    }
  }

}


