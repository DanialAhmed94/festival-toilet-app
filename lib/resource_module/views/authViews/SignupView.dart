import 'package:crapadvisor/resource_module/constants/appConstants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../annim/transiton.dart';
import '../../apis/signupApi.dart';
import '../../utilities/customTextField.dart';
import 'LoginView.dart';
import 'otpVerification.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _fullNameController = TextEditingController();
  final FocusNode _fullNameFocus = FocusNode();

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  bool _isLoading = false;

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  /// 👇 Track Terms agreement
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _fullNameFocus.addListener(() => _scrollToFocusedField());
    _emailFocus.addListener(() => _scrollToFocusedField());
    _phoneFocus.addListener(() => _scrollToFocusedField());
    _passwordFocus.addListener(() => _scrollToFocusedField());
    _confirmPasswordFocus.addListener(() => _scrollToFocusedField());
  }

  void _scrollToFocusedField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent * 0.3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _fullNameFocus.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocus.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(phone);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _proceedToOtpVerification() async {
    if (!_formKey.currentState!.validate()) {
      _formKey.currentState!.validate();
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phone = _phoneController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        phone.isEmpty ||
        fullName.isEmpty) {
      _showMessage('Please fill all required fields', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    if (!_isValidPhone(phone)) {
      _showMessage(
          'Please enter a valid phone number in E.164 format (e.g., +1234567890)',
          isError: true);
      return;
    }

    if (!_agreedToTerms) {
      _showMessage('You must agree to the Terms of Use.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Navigator.push(
        context,
        FadePageRouteBuilder(
          widget: PhoneOtpView(
            email: email,
            fullName: fullName,
            phoneE164: phone,
            password: password,
          ),
        ),
      );
    } catch (e) {
      _showMessage('An unexpected error occurred', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitForm() async {
    _proceedToOtpVerification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _SignupBody(
        scrollController: _scrollController,
        formKey: _formKey,
        fullNameController: _fullNameController,
        fullNameFocus: _fullNameFocus,
        emailController: _emailController,
        emailFocus: _emailFocus,
        phoneController: _phoneController,
        phoneFocus: _phoneFocus,
        passwordController: _passwordController,
        passwordFocus: _passwordFocus,
        confirmPasswordController: _confirmPasswordController,
        confirmPasswordFocus: _confirmPasswordFocus,
        isPasswordObscured: _isPasswordObscured,
        isConfirmPasswordObscured: _isConfirmPasswordObscured,
        isLoading: _isLoading,
        agreedToTerms: _agreedToTerms,
        onAgreedChanged: (val) {
          setState(() => _agreedToTerms = val);
        },
        onSubmitForm: _submitForm,
        onPasswordVisibilityChanged: (value) {
          setState(() {
            _isPasswordObscured = value;
          });
        },
        onConfirmPasswordVisibilityChanged: (value) {
          setState(() {
            _isConfirmPasswordObscured = value;
          });
        },
      ),
    );
  }
}

class _SignupBody extends StatelessWidget {
  final ScrollController scrollController;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final FocusNode fullNameFocus;
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final TextEditingController confirmPasswordController;
  final FocusNode confirmPasswordFocus;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final bool isLoading;
  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onSubmitForm;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final ValueChanged<bool> onConfirmPasswordVisibilityChanged;

  const _SignupBody({
    required this.scrollController,
    required this.formKey,
    required this.fullNameController,
    required this.fullNameFocus,
    required this.emailController,
    required this.emailFocus,
    required this.phoneController,
    required this.phoneFocus,
    required this.passwordController,
    required this.passwordFocus,
    required this.confirmPasswordController,
    required this.confirmPasswordFocus,
    required this.isPasswordObscured,
    required this.isConfirmPasswordObscured,
    required this.isLoading,
    required this.agreedToTerms,
    required this.onAgreedChanged,
    required this.onSubmitForm,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundImage(),
        _MainContent(
          scrollController: scrollController,
          formKey: formKey,
          fullNameController: fullNameController,
          fullNameFocus: fullNameFocus,
          emailController: emailController,
          emailFocus: emailFocus,
          phoneController: phoneController,
          phoneFocus: phoneFocus,
          passwordController: passwordController,
          passwordFocus: passwordFocus,
          confirmPasswordController: confirmPasswordController,
          confirmPasswordFocus: confirmPasswordFocus,
          isPasswordObscured: isPasswordObscured,
          isConfirmPasswordObscured: isConfirmPasswordObscured,
          agreedToTerms: agreedToTerms,
          onAgreedChanged: onAgreedChanged,
          onSubmitForm: onSubmitForm,
          onPasswordVisibilityChanged: onPasswordVisibilityChanged,
          onConfirmPasswordVisibilityChanged:
              onConfirmPasswordVisibilityChanged,
        ),
        if (isLoading) _LoadingOverlay(),
      ],
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        AppConstants.signupBG,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final ScrollController scrollController;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final FocusNode fullNameFocus;
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final TextEditingController confirmPasswordController;
  final FocusNode confirmPasswordFocus;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onSubmitForm;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final ValueChanged<bool> onConfirmPasswordVisibilityChanged;

  const _MainContent({
    required this.scrollController,
    required this.formKey,
    required this.fullNameController,
    required this.fullNameFocus,
    required this.emailController,
    required this.emailFocus,
    required this.phoneController,
    required this.phoneFocus,
    required this.passwordController,
    required this.passwordFocus,
    required this.confirmPasswordController,
    required this.confirmPasswordFocus,
    required this.isPasswordObscured,
    required this.isConfirmPasswordObscured,
    required this.agreedToTerms,
    required this.onAgreedChanged,
    required this.onSubmitForm,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SingleChildScrollView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.35,
                left: 0,
                right: 0,
              ),
              child: Column(
                children: [
                  _SignupForm(
                    formKey: formKey,
                    fullNameController: fullNameController,
                    fullNameFocus: fullNameFocus,
                    emailController: emailController,
                    emailFocus: emailFocus,
                    phoneController: phoneController,
                    phoneFocus: phoneFocus,
                    passwordController: passwordController,
                    passwordFocus: passwordFocus,
                    confirmPasswordController: confirmPasswordController,
                    confirmPasswordFocus: confirmPasswordFocus,
                    isPasswordObscured: isPasswordObscured,
                    isConfirmPasswordObscured: isConfirmPasswordObscured,
                    onPasswordVisibilityChanged: onPasswordVisibilityChanged,
                    onConfirmPasswordVisibilityChanged:
                        onConfirmPasswordVisibilityChanged,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: agreedToTerms,
                          onChanged: (value) {
                            onAgreedChanged(value ?? false);
                          },
                        ),
                        Flexible(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: "Ubuntu",
                              ),
                              children: [
                                const TextSpan(text: "I agree to the "),
                                TextSpan(
                                  text: "Terms of Use (EULA)",
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final Uri url = Uri.parse(
                                          "https://crapadvisor.semicolonstech.com/privacy.html");
                                      if (!await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      )) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Could not open Terms of Use link.")),
                                        );
                                      }
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SubmitButton(onSubmitForm: onSubmitForm),
                  _LoginLink(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final FocusNode fullNameFocus;
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final TextEditingController confirmPasswordController;
  final FocusNode confirmPasswordFocus;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final ValueChanged<bool> onConfirmPasswordVisibilityChanged;

  const _SignupForm({
    required this.formKey,
    required this.fullNameController,
    required this.fullNameFocus,
    required this.emailController,
    required this.emailFocus,
    required this.phoneController,
    required this.phoneFocus,
    required this.passwordController,
    required this.passwordFocus,
    required this.confirmPasswordController,
    required this.confirmPasswordFocus,
    required this.isPasswordObscured,
    required this.isConfirmPasswordObscured,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.lightBlueAccent.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _FullNameField(
                controller: fullNameController,
                focusNode: fullNameFocus,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(emailFocus);
                },
              ),
              const SizedBox(height: 8),
              _EmailField(
                controller: emailController,
                focusNode: emailFocus,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(phoneFocus);
                },
              ),
              const SizedBox(height: 8),
              _PhoneField(
                controller: phoneController,
                focusNode: phoneFocus,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
              ),
              const SizedBox(height: 8),
              _PasswordField(
                controller: passwordController,
                focusNode: passwordFocus,
                isObscured: isPasswordObscured,
                onVisibilityChanged: onPasswordVisibilityChanged,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(confirmPasswordFocus);
                },
              ),
              const SizedBox(height: 8),
              _ConfirmPasswordField(
                controller: confirmPasswordController,
                focusNode: confirmPasswordFocus,
                isObscured: isConfirmPasswordObscured,
                onVisibilityChanged: onConfirmPasswordVisibilityChanged,
                passwordController: passwordController,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onFieldSubmitted;

  const _FullNameField({
    required this.controller,
    required this.focusNode,
    required this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return customTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: "Full Name",
      postfixIcon: Icons.person,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onFieldSubmitted;

  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return customTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: "Email",
      postfixIcon: Icons.email,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onFieldSubmitted;

  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return customTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: "Phone Number (e.g., +1234567890)",
      postfixIcon: Icons.phone,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.phone,
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value.trim())) {
          return 'Please enter a valid phone number in E.164 format (e.g., +1234567890)';
        }
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isObscured;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onFieldSubmitted;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.isObscured,
    required this.onVisibilityChanged,
    required this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return customTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: "Password",
      postfixIcon: Icons.lock,
      obscureText: isObscured,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () {
          onVisibilityChanged(!isObscured);
        },
      ),
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}

class _ConfirmPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isObscured;
  final ValueChanged<bool> onVisibilityChanged;
  final TextEditingController passwordController;
  final ValueChanged<String> onFieldSubmitted;

  const _ConfirmPasswordField({
    required this.controller,
    required this.focusNode,
    required this.isObscured,
    required this.onVisibilityChanged,
    required this.passwordController,
    required this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return customTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: "Confirm Password",
      postfixIcon: Icons.lock,
      obscureText: isObscured,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () {
          onVisibilityChanged(!isObscured);
        },
      ),
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onSubmitForm;

  const _SubmitButton({required this.onSubmitForm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSubmitForm,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        child: Image.asset(AppConstants.nextButon),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: 'Already a member? ',
        style: const TextStyle(color: Colors.black),
        children: <TextSpan>[
          TextSpan(
            text: 'Login',
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  FadePageRouteBuilder(widget: LoginView()),
                );
              },
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
