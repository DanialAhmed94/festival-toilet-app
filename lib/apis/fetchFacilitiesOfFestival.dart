import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fetchFacilitiesOfFestival_model.dart';

Future<List<Toilet>?> fetchToiletsByFestivalId(String festivalId) async {
  final String apiUrl = 'https://stagingcrapadvisor.semicolonstech.com/api/getToiletsofFestival?festival_id=$festivalId';

  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['message'] == 'Toilets Fetched Successfully') {
      List<dynamic> data = responseData['data'];
      if (data.isEmpty) {
        return null; // No toilets available
      } else {
        List<Toilet> toilets = data.map((json) => Toilet.fromJson(json)).toList();
        return toilets;
      }
    } else {
      throw Exception('Failed to fetch toilets: ${responseData['message']}');
    }
  } else {
    throw Exception('Failed to load toilets');
  }
}

