import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../model/performanceModel.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<Performances?> getPerformanceCollection(BuildContext context,String festivalId) async {
  final url = Uri.parse("${AppConstants.baseUrl}/performance-all?festival_id=$festivalId");

  if (kDebugMode) {
    print('========== PERFORMANCE COLLECTION API ==========');
    print('Request URL: $url');
    print('Festival ID: $festivalId');
  }

  try {
    final bearerToken = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(seconds: 30));

    if (kDebugMode) {
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('================================================');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Performances.fromJson(data);
    } else {
      final data = json.decode(response.body);
      showErrorDialog(context, data['message'], data['errors']);
    }
  } on TimeoutException catch (_) {
    if (kDebugMode) print('Performance API: Request timed out');
    showErrorDialog(context, "Request timed out. Please try again later.", []);
  } on SocketException catch (_) {
    if (kDebugMode) print('Performance API: No internet connection');
    showErrorDialog(context, "No internet connection. Please check your connection and try again.", []);
  } on FormatException catch (_) {
    if (kDebugMode) print('Performance API: Data format error');
    showErrorDialog(context, "Data format is incorrect. Please try again later.", []);
  } catch (error) {
    if (kDebugMode) print('Performance API unexpected error: $error');
    showErrorDialog(context, "An unexpected error occurred: $error", []);
  }

  return null;
}
