import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crapadvisor/annim/transiton.dart';
import 'package:crapadvisor/resource_module/appSelectionView.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../constants/AppConstants.dart';
import '../utilities/sharedPrefs.dart';

Future<void> LogoutApi(BuildContext context) async {
  final url = Uri.parse("${AppConstants.baseUrl}/logout");
  final bearerToken = await getToken();

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (responseBody['code'] == 200) {
        // Clear FCM token from Firestore before clearing local data
        final int? userIdInt = await getUserId();
        final String? userId = userIdInt?.toString();
        if (userId != null && userId != "0") {
          try {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .update({"fcmToken": FieldValue.delete()});
          } catch (_) {}
        }

        // Clear local data
        await saveToken("");
        await saveUserName("");
        await setIsLogedIn(false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');

        Navigator.pushReplacement(
            context, FadePageRouteBuilder(widget: AppSelectionView()));
      } else {
        showErrorDialog(
            context, 'Unexpected response code: ${responseBody['code']}');
      }
    } else {
      showErrorDialog(context, 'Server error: ${response.statusCode}');
    }
  } on SocketException catch (_) {
    showErrorDialog(
      context,
      "No internet connection. Please check your network settings.",
    );
  } on TimeoutException catch (_) {
    showErrorDialog(
      context,
      "Request timed out. Please try again later.",
    );
  } on FormatException catch (_) {
    showErrorDialog(
      context,
      "Invalid response format from server.",
    );
  } catch (error) {
    showErrorDialog(context, 'An error occurred: $error');
  }
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
