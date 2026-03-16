import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../model/toiletModel.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<ToiletResponse?> getToiletCollection(BuildContext context,String festivalId) async {
  final url = Uri.parse(
      "${AppConstants.baseUrl}/toilets-all?festival_id=$festivalId"); // Adjust endpoint accordingly
  try {
    final bearerToken = await getToken(); // Fetch token from utility
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json', // Set the content type to JSON
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ToiletResponse.fromJson(data); // Parse the response
    } else {
      final data = json.decode(response.body);
      showErrorDialog(context, data['message'], data['errors']);
    }
  } on TimeoutException catch (_) {
    showErrorDialog(context, "Request timed out. Please try again later.", []);
  } on SocketException catch (_) {
    showErrorDialog(
        context,
        "No internet connection. Please check your connection and try again.",
        []);
  } on FormatException catch (_) {
    showErrorDialog(
        context, "Data format is incorrect. Please try again later.", []);
  } catch (error) {
    showErrorDialog(
        context, "Operation failed with while fetching toilets: $error", []);
    print("error: $error");
  }
  return null;
}
