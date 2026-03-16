import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../model/activitiesModel.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<ActivityResponse?> getActivitiesCollection(
    BuildContext context, String festivalId) async {
  final url = Uri.parse(
      "${AppConstants.baseUrl}/activity-all?festival_id=$festivalId");

  try {
    final bearerToken = await getToken(); // Fetch the bearer token
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(seconds: 30)); // Set a timeout for the request

    if (response.statusCode == 200) {
      final data = json.decode(response.body); // Decode the JSON response
      return ActivityResponse.fromJson(
          data); // Parse and return the ActivityResponse object
    } else {
      final data = json.decode(response.body); // Decode error response
      showErrorDialog(
          context, data['message'], data['errors']); // Show error dialog
    }
  } on TimeoutException catch (_) {
    showErrorDialog(context, "Request timed out. Please try again later.",
        []); // Handle timeout
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
        context,
        "Operation failed while fetching activities: $error",
        []); // Handle other errors
    print("Error: $error"); // Print the error for debugging
  }
  return null;
}
