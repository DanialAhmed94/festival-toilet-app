import 'package:flutter/material.dart';

/// Utility function that returns a styled TextFormField
Widget customTextField({
  required String hintText,
  TextEditingController? controller,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  FocusNode? focusNode,
  TextInputAction? textInputAction,
  Function(String)? onFieldSubmitted,
  String? Function(String?)? validator,
  IconData? postfixIcon, // Optional postfix icon
  Widget? suffixIcon, // Optional suffix icon (e.g., for visibility toggle)
  /// Extra space the scrollable keeps below the field when scrolling it into view
  /// (use bottom >= keyboard height when [resizeToAvoidBottomInset] is false).
  EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    focusNode: focusNode,
    textInputAction: textInputAction,
    onFieldSubmitted: onFieldSubmitted,
    validator: validator,
    scrollPadding: scrollPadding,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.5), // Hint text with 50% opacity
      ),
      fillColor: Colors.white,
      filled: true, // White background
      suffixIcon: suffixIcon ?? (postfixIcon != null ? Icon(postfixIcon) : null), // Display suffixIcon if provided; otherwise, show postfixIcon
      border: InputBorder.none, // No border by default
      enabledBorder: InputBorder.none, // No border when enabled
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // Border when focused
        borderSide: BorderSide(color: Colors.blue, width: 2.0), // Border color and width when focused
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
