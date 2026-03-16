import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<bool> preRegistration(BuildContext context, String event_id) async {
  final url = Uri.parse(
      "${AppConstants.baseUrl}/event-registration");

  try {
    final bearerToken = await getToken(); // Fetch the bearer token

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'event_id': event_id, // Pass the event_id in the body
      }),
    ).timeout(Duration(seconds: 30)); // Set a timeout for the request

    if (response.statusCode == 200) {
      // If the request is successful, return true
      return true;
    } else {
      // Handle unsuccessful responses
      final data = json.decode(response.body); // Decode error response
      showErrorDialog(
          context, data['message'] ?? "Something went wrong.", []); // Show error dialog
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
        context,
        "Operation failed while fetching activities: $error",
        []);
    print("Error: $error"); // Print the error for debugging
  }
  // Return false in case of any error or non-200 status code
  return false;
}
