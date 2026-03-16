import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:async';

import '../constants/AppConstants.dart';
import '../utilities/dialogBoxes.dart';

Future<void> forgetPasswordApi(
    BuildContext context, String email, String password) async {
  final url = Uri.parse("${AppConstants.baseUrl}/reset-password");

  print('🔐 Forget Password API - Starting request');
  print('📡 URL: $url');
  print('📧 Email: $email');
  print(
      '🔑 Password: ${password.replaceAll(RegExp(r'.'), '*')}'); // Mask password for security

  final Map<String, dynamic> forgetPasswordData = {
    'email': email,
    'password': password,
  };

  print('📦 Request Data: ${jsonEncode(forgetPasswordData)}');

  try {
    print('🚀 Making HTTP POST request...');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(forgetPasswordData),
        )
        .timeout(const Duration(seconds: 30));

    print('📊 Response Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      print('✅ Response parsed successfully');
      print('📋 Response Status: ${responseData['status']}');
      print('💬 Response Message: ${responseData['message']}');

      // Check for success based on status field (server uses 'status' instead of 'code')
      if (responseData['status'] == 200) {
        print('🎉 Password reset successful!');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Password reset successfully! You can now login with your new password.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        // Navigate back to login
        Navigator.pop(context);
      } else {
        print('❌ Server returned error status: ${responseData['status']}');
        print('🚨 Error Message: ${responseData['message']}');
        // Server-side validation or other errors
        showErrorDialog(context, responseData['message'], []);
      }
    } else if (response.statusCode == 400) {
      print('❌ Bad Request (400) - Validation failed');
      // Handle client-side errors (e.g., validation failed)
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('🚨 400 Error Message: ${responseData['message']}');
      // Handle case where errors might be null
      final errors = responseData['errors'] ?? [];
      print('🔍 400 Error Details: $errors');
      showErrorDialog(context, responseData['message'], errors);
    } else if (response.statusCode == 404) {
      print('❌ Not Found (404) - Email not found');
      // Handle email not found
      showErrorDialog(
          context, "Email not found. Please check your email address.", []);
    } else {
      print('❌ HTTP Error - Status Code: ${response.statusCode}');
      print('📄 Error Response Body: ${response.body}');
      // Handle other HTTP errors
      showErrorDialog(context,
          "Password reset failed with status code: ${response.statusCode}", []);
    }
  } on TimeoutException catch (_) {
    print('⏰ Timeout Exception - Request timed out after 30 seconds');
    showErrorDialog(context, "Request timed out. Please try again later.", []);
  } on ClientException catch (e) {
    print('🌐 Client Exception: $e');
    final errorString = e.toString();
    if (errorString.contains('SocketException')) {
      print('🔌 Socket Exception - Network connectivity issue');
      showErrorDialog(
          context, "Network error. Please check your internet connection.", []);
    } else {
      print('🔗 Connection Error: $errorString');
      showErrorDialog(context, "Connection error: $errorString", []);
    }
  } catch (e) {
    print('💥 Unexpected Error: $e');
    print('📚 Error Type: ${e.runtimeType}');
    showErrorDialog(context, "An unexpected error occurred: $e", []);
  }
}
