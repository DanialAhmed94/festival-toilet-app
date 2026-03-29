import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'package:crapadvisor/resource_module/views/authViews/LoginView.dart';
import 'package:crapadvisor/services/firestore_user_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/appConstants.dart';
import '../utilities/dialogBoxes.dart';

Future<void> signUp(BuildContext context, String fullName, String email,
    String password, String phone) async {
  final url = Uri.parse("${AppConstants.baseUrl}/authup");
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? deviceId = await prefs.getString("fcm_token");

  debugPrint(
    '[Signup/API] POST authup url=$url email=$email phone=$phone '
    'app_type=user firebaseAppId=${AppConstants.firebaseRegistrationAppId} '
    'hasFcmToken=${deviceId != null && deviceId.isNotEmpty}',
  );

  final Map<String, dynamic> signUpData = {
    'name': fullName,
    'email': email,
    'password': password,
    'phone': phone,
    'device_token': deviceId,
    'app_type': "user",
  };

  try {
    // Send the POST request with a timeout
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json', // Set the content type to JSON
          },
          body: jsonEncode(signUpData), // Encode the data to JSON format
        )
        .timeout(const Duration(seconds: 30)); // Set a timeout duration

    // Handle the response
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['code'] == 200) {
        // Signup successful
        final token =
            responseData['data']?['response']?['token']?.toString() ?? '';
        debugPrint(
          '[Signup/API] HTTP 200 code=200 message=${responseData['message']} '
          'tokenLen=${token.length}',
        );

        // Create user in Firestore for chat functionality
        try {
          final userData = responseData['data']['user'];
          final userId = userData['id'].toString();
          final userName = userData['name'];
          final phoneNumber = userData['phone'];

          debugPrint(
            '[Signup/API] Backend user created userId=$userId name=$userName '
            'phone=$phoneNumber → Firestore createOrUpdateUser',
          );

          await FirestoreUserService.createOrUpdateUser(
            userId: userId,
            phoneNumber: phoneNumber,
            userName: userName,
            registeredFromApp: AppConstants.firebaseRegistrationAppId,
          );

          debugPrint('[Signup/API] Firestore user doc synced for chat');
        } catch (e) {
          debugPrint('[Signup/API] Firestore sync failed (signup still OK): $e');
          // Don't block signup if Firestore fails
        }

        showSuccessDialog(context,
            "Your account has been created successfully!", null, LoginView());
      } else {
        debugPrint(
          '[Signup/API] Business error code=${responseData['code']} '
          'message=${responseData['message']}',
        );
        // Server-side validation or other errors
        showErrorDialog(
            context, responseData['message'], responseData['errors']);
      }
    } else if (response.statusCode == 400) {
      // Handle client-side errors (e.g., validation failed)
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      showErrorDialog(context, responseData['message'], responseData['errors']);
    } else {
      debugPrint('[Signup/API] HTTP error status=${response.statusCode}');
      // Handle other HTTP errors
      showErrorDialog(context,
          "Signup failed with status code: ${response.statusCode}", []);
    }
  } on SocketException catch (_) {
    debugPrint('[Signup/API] SocketException — no network');
    showErrorDialog(context,
        "No internet connection. Please check your network settings.", []);
  } on TimeoutException catch (_) {
    debugPrint('[Signup/API] TimeoutException');
    showErrorDialog(context, "Request timed out. Please try again later.", []);
  } on FormatException catch (_) {
    debugPrint('[Signup/API] FormatException — bad JSON');
    showErrorDialog(context, "Invalid response format from server.", []);
  } catch (error) {
    debugPrint('[Signup/API] Unexpected error: $error');
    showErrorDialog(context, "Signup failed with error: $error", []);
  }
}
