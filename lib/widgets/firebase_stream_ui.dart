import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Short, user-facing text for Firestore / network failures.
String userFriendlyFirebaseError(Object? error) {
  if (error == null) return "Something went wrong. Please try again.";
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return "You don't have permission to view this.";
      case 'unavailable':
        return "Service is temporarily unavailable. Check your connection and try again.";
      case 'deadline-exceeded':
        return "The request took too long. Check your connection and try again.";
      case 'resource-exhausted':
        return "Too many requests. Please wait a moment and try again.";
      default:
        return "Couldn't load data. Please try again.";
    }
  }
  final s = error.toString().toLowerCase();
  if (s.contains('socket') ||
      s.contains('network') ||
      s.contains('failed host lookup') ||
      s.contains('connection')) {
    return "No internet connection. Check your network and try again.";
  }
  return "Couldn't load data. Please try again.";
}

Widget firebaseStreamLoading({
  required String message,
  Color? indicatorColor,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: indicatorColor ?? Colors.blue.shade600,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Ubuntu",
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget firebaseStreamError({
  required BuildContext context,
  required String message,
  VoidCallback? onRetry,
  IconData icon = Icons.cloud_off_outlined,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Ubuntu",
              fontSize: 15,
              height: 1.35,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text("Try again"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
