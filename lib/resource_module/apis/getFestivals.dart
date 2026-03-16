import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Import for SocketException

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/AppConstants.dart';
import '../model/festivalsModel.dart';
import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<FestivalResponse?> getFestivalCollection(BuildContext context, {int page = 1, String? search}) async {
  var urlStr = "${AppConstants.baseUrl}/getfestival?page=$page";
  if (search != null && search.trim().isNotEmpty) {
    urlStr += "&search=${Uri.encodeComponent(search.trim())}";
  }
  final url = Uri.parse(urlStr);
  try {
    final bearerToken = await getToken();
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[getFestivalCollection] 🌐 REQUEST URL: $url');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json', // Set the content type to JSON
      },
    ).timeout(Duration(seconds: 30));

    debugPrint('[getFestivalCollection] 📊 STATUS: ${response.statusCode}');
    debugPrint('[getFestivalCollection] 📋 HEADERS: ${response.headers}');
    debugPrint('[getFestivalCollection] 📄 BODY (raw): ${response.body}');
    try {
      final decoded = jsonDecode(response.body);
      debugPrint('[getFestivalCollection] 📦 BODY (decoded): $decoded');
    } catch (_) {}
    debugPrint('═══════════════════════════════════════════════════════════');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final festivalResponse = FestivalResponse.fromJson(data);
      debugPrint('[getFestivalCollection] 📤 API RESPONSE (complete): $data');
      return festivalResponse;
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
    debugPrint("error123: $error");
  }
  return null; // Return null if an error occurs
}
