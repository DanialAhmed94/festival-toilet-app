
import 'package:flutter/material.dart';

import '../../apis/forgetPassword_api.dart';
import '../../constants/appConstants.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  _ForgotPasswordViewState createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // Enhanced validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final email = value.trim();

    // Check for basic email format
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Check for common email issues
    if (email.startsWith('.') || email.endsWith('.') || email.contains('..')) {
      return 'Email address contains invalid characters';
    }

    if (email.length > 254) {
      return 'Email address is too long';
    }

    // Check for valid domain
    final parts = email.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }

    final domain = parts[1];
    if (domain.length < 3 || !domain.contains('.')) {
      return 'Invalid domain in email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (value.length > 128) {
      return 'Password is too long (max 128 characters)';
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password',
      '123456',
      'qwerty',
      'admin',
      'letmein',
      'welcome',
      'monkey',
      'dragon',
      'master',
      'hello'
    ];

    if (weakPasswords.contains(value.toLowerCase())) {
      return 'Please choose a stronger password';
    }

    // Check for repeated characters
    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
      return 'Password cannot contain repeated characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  void _resetPassword() async {
    // Clear any existing validation errors
    _formKey.currentState?.reset();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Additional server-side validation checks
        final email = _emailController.text.trim();
        final newPassword = _newPasswordController.text;
        final confirmPassword = _confirmPasswordController.text;

        // Final validation before API call
        if (email.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
          throw Exception('All fields are required');
        }

        if (newPassword != confirmPassword) {
          throw Exception('Passwords do not match');
        }

        // Call the forget password API
        await forgetPasswordApi(context, email, newPassword);
      } catch (e) {
        String errorMessage = 'Failed to reset password. Please try again.';

        final err = e.toString().toLowerCase();
        if (err.contains('network')) {
          errorMessage =
          'Network error. Please check your internet connection.';
        } else if (err.contains('email')) {
          errorMessage = 'Email not found. Please check your email address.';
        } else if (err.contains('password')) {
          errorMessage =
          'Invalid password format. Please follow the requirements.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Show validation error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please fix the validation errors above',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  double calculateTotalHeight(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double totalHeight = screenHeight * 1.2; // kept if you need it elsewhere
    return totalHeight;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      // Real AppBar to avoid overlap with content and handle SafeArea correctly
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Reset Password",
          style: TextStyle(fontSize: 16, fontFamily: "UbuntuBold"),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              color: Colors.grey[100],
            ),
          ),

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, kToolbarHeight + 16, 16, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFC),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: const [
                        Text(
                          "Forgot Password?",
                          style:
                          TextStyle(fontFamily: "UbuntuBold", fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Enter your email and new password to reset your account password",
                          style: TextStyle(
                              fontFamily: "UbuntuRegular", fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logo (auto scales with layout, no fixed Positioned)
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFC),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Address
                          const Text(
                            "Email Address",
                            style: TextStyle(
                              fontFamily: "UbuntuRegular",
                              fontSize: 14,
                              color: Color(0xFF7A849C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade300,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.red.shade500,
                                  width: 2,
                                ),
                              ),
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              suffixIcon: Icon(
                                Icons.email,
                                color: _validateEmail(_emailController.text) ==
                                    null &&
                                    _emailController.text.isNotEmpty
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            validator: _validateEmail,
                            textInputAction: TextInputAction.next,
                          ),

                          const SizedBox(height: 16),

                          // New Password
                          const Text(
                            "New Password",
                            style: TextStyle(
                              fontFamily: "UbuntuRegular",
                              fontSize: 14,
                              color: Color(0xFF7A849C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade300,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.red.shade500,
                                  width: 2,
                                ),
                              ),
                              hintText: 'Enter new password (min 8 characters)',
                              hintStyle: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_newPasswordController.text.isNotEmpty)
                                    Icon(
                                      _validatePassword(_newPasswordController
                                          .text) ==
                                          null
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      color: _validatePassword(
                                          _newPasswordController
                                              .text) ==
                                          null
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  GestureDetector(
                                    onTap: _toggleNewPasswordVisibility,
                                    child: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            validator: _validatePassword,
                            textInputAction: TextInputAction.next,
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password
                          const Text(
                            "Confirm Password",
                            style: TextStyle(
                              fontFamily: "UbuntuRegular",
                              fontSize: 14,
                              color: Color(0xFF7A849C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade300,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Colors.red.shade500,
                                  width: 2,
                                ),
                              ),
                              hintText: 'Confirm new password',
                              hintStyle: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_confirmPasswordController
                                      .text.isNotEmpty)
                                    Icon(
                                      _validateConfirmPassword(
                                          _confirmPasswordController
                                              .text) ==
                                          null
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      color: _validateConfirmPassword(
                                          _confirmPasswordController
                                              .text) ==
                                          null
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  GestureDetector(
                                    onTap: _toggleConfirmPasswordVisibility,
                                    child: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            validator: _validateConfirmPassword,
                            textInputAction: TextInputAction.done,
                          ),

                          const SizedBox(height: 16),

                          // Password Requirements
                          if (_newPasswordController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      fontFamily: "UbuntuMedium",
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRequirementItem(
                                    'At least 8 characters',
                                    _newPasswordController.text.length >= 8,
                                  ),
                                  _buildRequirementItem(
                                    'One uppercase letter',
                                    RegExp(r'[A-Z]')
                                        .hasMatch(_newPasswordController.text),
                                  ),
                                  _buildRequirementItem(
                                    'One lowercase letter',
                                    RegExp(r'[a-z]')
                                        .hasMatch(_newPasswordController.text),
                                  ),
                                  _buildRequirementItem(
                                    'One number',
                                    RegExp(r'[0-9]')
                                        .hasMatch(_newPasswordController.text),
                                  ),
                                  _buildRequirementItem(
                                    'One special character',
                                    RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                        .hasMatch(_newPasswordController.text),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                                                     // Submit Button
                           GestureDetector(
                             onTap: _resetPassword,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                                                             decoration: BoxDecoration(
                                 color: const Color(0xFF45A3D9),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                              child: Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2.5,
                                )
                                    : const Text(
                                  "Reset Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: "UbuntuRegular",
              fontSize: 11,
              color: isMet ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
