import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Import for SocketException

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../model/festivalsModel.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<FestivalResponse?> getFestivalCollection(BuildContext context) async {
  int c=0;
  print('$c++');
  final url = Uri.parse("${AppConstants.baseUrl}/getfestival");
  try {
    final bearerToken = await getToken();
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json', // Set the content type to JSON
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return FestivalResponse.fromJson(data);
    } else if (response.statusCode == 403) {
      // Handle forbidden access or authentication issues
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      showErrorDialog(context, responseData['message'], responseData['errors']);
    } else {
      final data = json.decode(response.body);
      showErrorDialog(context, data['message'], data['errors']);
    }
  } on SocketException catch (_) {
    showErrorDialog(context, "No internet connection. Please check your network settings.", []);
  } on TimeoutException catch (_) {
    showErrorDialog(context, "Request timed out. Please try again later.", []);
  } on FormatException catch (_) {
    showErrorDialog(context, "Invalid response format from server.", []);
  } catch (error) {
    showErrorDialog(
        context, "Operation failed while fetching festivals: $error", []);
    print("error123: $error");
  }
  return null; // Return null if an error occurs
}
