import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crapadvisor/resource_module/HomeView.dart';
import 'package:crapadvisor/resource_module/utilities/dialogBoxes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Import for SocketException

import '../../annim/transiton.dart';
import '../constants/appConstants.dart';
import '../utilities/sharedPrefs.dart';

Future<void> LogInApi(
    BuildContext context, String email, String password) async {
  final url = Uri.parse("${AppConstants.baseUrl}/authin");
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final fcmToken = prefs.getString('fcm_token');
  final Map<String, dynamic> logInData = {
    'email': email,
    'password': password,
    'device_token': fcmToken,
    'app_type': "user",
  };
  try {
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json', // Set the content type to JSON
          },
          body: jsonEncode(logInData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['code'] == 200) {
        final token = responseData['data']['response']['token'];
        final userName = responseData['data']['user']['name'];
        final userEmail = responseData['data']['user']['email'];
        final userPhone = responseData['data']['user']['phone'];
        final userId = responseData['data']['user']['id'];

        await saveToken(token);
        await saveUserName(userName);
        await saveUserEmail(userEmail);
        await saveUserPhone(userPhone);
        await setIsLogedIn(true);
        await saveUserId(userId);

        // Save FCM token in Firestore

        print("userId ${userId}");
        print("deviceId ${fcmToken}");

        if (userId != null && (fcmToken != "")) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId.toString())
              .set({"fcmToken": fcmToken}, SetOptions(merge: true));
          print("✅ FCM token updated for user: $userId");
        }

        print("api hit ${responseData['data']['response']['token']}");
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRouteBuilder(widget: HomeView()),
          (Route<dynamic> route) => false, // This removes all previous routes
        );
      } else {
        // Server-side validation or other errors
        showErrorDialog(
            context, responseData['message'], responseData['errors']);
      }
    } else if (response.statusCode == 400) {
      // Handle client-side errors (e.g., validation failed)
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      showErrorDialog(context, responseData['message'], responseData['errors']);
    } else {
      // Handle other HTTP errors
      showErrorDialog(
          context, "Login failed with status code: ${response.statusCode}", []);
    }
  } on SocketException catch (_) {
    showErrorDialog(context,
        "No internet connection. Please check your network settings.", []);
  } on TimeoutException catch (_) {
    showErrorDialog(context, "Request timed out. Please try again later.", []);
  } on FormatException catch (_) {
    showErrorDialog(context, "Invalid response format from server.", []);
  } catch (error) {
    showErrorDialog(context, "Login failed with error: $error", []);
  }
}
