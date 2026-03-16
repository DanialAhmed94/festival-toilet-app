import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festivalsDetail_model.dart';

Future<Festivals> fetchFestivals(String url) async {
  // Replace the URL with the actual endpoint from where you're fetching data
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, then parse the JSON.
    return Festivals.fromJson(json.decode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load festivals');
  }
}
