import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../model/NewsModel.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<BulletinResponse?> getBulletinCollection(BuildContext context) async {
  final url = Uri.parse("${AppConstants.baseUrl}/bulletins-all");
  try {
    final bearerToken = await getToken(); // Fetch the bearer token
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body); // Decode the JSON response
      return BulletinResponse.fromJson(data); // Return the ApiResponse object
    } else {
      final data = json.decode(response.body); // Decode error response
      showErrorDialog(
          context, data['message'], data['errors']); // Show error dialog
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
        context, "Operation failed with while fetching bulletins: $error", []);
    print("error: $error"); // Print the error for debugging
  }
  return null; // Return null in case of an error
}
