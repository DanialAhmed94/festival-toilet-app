import 'package:crapadvisor/resource_module/constants/appConstants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../annim/transiton.dart';
import '../../HomeView.dart';
import '../../apis/loginApi.dart';
import '../../utilities/customTextField.dart';
import 'SignupView.dart';
import 'ForgotPasswordView.dart';

EdgeInsets _loginFieldScrollPadding(BuildContext context) {
  final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(20, 20, 20, keyboardBottom + 24);
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false; // Added loading state variable
  bool _isPasswordObscured = true; // Toggle for password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });
      try {
        // Call your API here
        print('Form is valid, proceed to call API');
        await LogInApi(context, _emailController.text, _passwordController.text);
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    } else {
      print('Form is invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Image covering the entire screen
          Positioned.fill(
            child: Image.asset(
              AppConstants.loginBG,
              fit: BoxFit.cover,
            ),
          ),
          // SingleChildScrollView for content
          Positioned.fill(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.4,
                  left: 16.0,
                  right: 16.0,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16.0,
                ),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Container(
                        // Removed fixed height to allow dynamic resizing
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.lightBlueAccent.withOpacity(0.1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding here
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 28),
                              Text(
                                "Email Address",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              customTextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                hintText: "Email",
                                postfixIcon: Icons.email,
                                textInputAction: TextInputAction.next,
                                scrollPadding: _loginFieldScrollPadding(context),
                                onFieldSubmitted: (value) {
                                  FocusScope.of(context).requestFocus(_passwordFocus);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Password",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              customTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                hintText: "Password",
                                postfixIcon: Icons.lock,
                                obscureText: _isPasswordObscured,
                                textInputAction: TextInputAction.done,
                                scrollPadding: _loginFieldScrollPadding(context),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordObscured = !_isPasswordObscured;
                                    });
                                  },
                                ),
                                onFieldSubmitted: (value) {
                                  FocusScope.of(context).unfocus();
                                  _submitForm();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  print('Forgot Password tapped - attempting navigation');
                                  try {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ForgotPasswordView()),
                                    );
                                    print('Navigation to ForgotPasswordView successful');
                                  } catch (e) {
                                    print('Navigation error: $e');
                                    // Show error message to user
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Navigation error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  "Forgot Password",
                                  style: TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    GestureDetector(
                      onTap: _submitForm,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: Image.asset(AppConstants.loginButon),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          FadePageRouteBuilder(widget: SignupView()),
                        );
                        print('Register Instead tapped');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Register Instead',
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          // Loading Indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Semi-transparent background
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
