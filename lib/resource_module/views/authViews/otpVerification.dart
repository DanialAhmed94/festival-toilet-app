import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import '../../apis/signupApi.dart';
import '../../constants/AppConstants.dart';
import 'LoginView.dart';

class PhoneOtpView extends StatefulWidget {
  final String email;
  final String fullName;
  final String phoneE164;
  final String password;

  const PhoneOtpView({
    Key? key,
    required this.email,
    required this.fullName,
    required this.phoneE164,
    required this.password,
  }) : super(key: key);

  @override
  State<PhoneOtpView> createState() => _PhoneOtpViewState();
}

class _PhoneOtpViewState extends State<PhoneOtpView>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;
  bool _loading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _clearStoredVerificationData();
    _sendOtp();
  }

  Future<void> _clearStoredVerificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('verification_id');
      await prefs.remove('resend_token');
      print('🔍 Debug: Cleared stored verification data');
    } catch (e) {
      print('🔍 Debug: Error clearing stored verification data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    print('🔍 Debug: Starting OTP verification for ${widget.phoneE164}');
    print('🔍 Debug: Firebase Auth instance: ${_auth.app.name}');
    print(
        '🔍 Debug: Current Firebase user: ${_auth.currentUser?.uid ?? 'None'}');
    print('🔍 Debug: Is resend: $isResend, Resend token: $_resendToken');
    print('🔍 Debug: Phone number format: ${widget.phoneE164}');

    // Check if Firebase is properly initialized
    try {
      await _auth.app.options;
      print('🔍 Debug: Firebase app options: ${_auth.app.options.apiKey}');
    } catch (e) {
      print('🔍 Debug: Error getting Firebase app options: $e');
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential cred) async {
          print('🔍 Debug: Auto-verification completed with code: ${cred.smsCode}');
          // On Android, auto-verification may silently sign in.
          // Delete any auto-created Firebase Auth user immediately.
          try {
            final firebaseUser = _auth.currentUser;
            if (firebaseUser != null) {
              await firebaseUser.delete();
              print('🔍 Debug: Deleted auto-created Firebase Auth user from auto-verification');
            }
          } catch (e) {
            try { await _auth.signOut(); } catch (_) {}
            print('🔍 Debug: Auto-verification cleanup error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔍 Debug: Verification failed - ${e.code}: ${e.message}');
          print(
              '🔍 Debug: Error details - code: ${e.code}, message: ${e.message}');
          print(
              '🔍 Debug: Error email: ${e.email}, phoneNumber: ${e.phoneNumber}');
          print(
              '🔍 Debug: Error tenantId: ${e.tenantId}, credential: ${e.credential}');

          setState(() {
            String errorMessage = 'Verification failed';
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = 'Invalid phone number format';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many attempts. Please try again later';
                break;
              case 'quota-exceeded':
                errorMessage = 'SMS quota exceeded. Please try again later';
                break;
              case 'app-not-authorized':
                errorMessage =
                    'App not authorized. Please check Firebase configuration.';
                break;
              case 'invalid-app-credential':
                errorMessage =
                    'Invalid app credentials. Please check Firebase configuration.';
                break;
              case 'recaptcha-not-enabled':
                errorMessage =
                    'reCAPTCHA not properly configured. Please contact support.';
                break;
              case 'recaptcha-site-key-missing':
                errorMessage =
                    'reCAPTCHA configuration issue. Please try again.';
                break;
              case 'unknown':
                errorMessage =
                    'Unknown error occurred. Please check your internet connection and try again.';
                break;
              default:
                errorMessage =
                    '${e.message ?? 'Verification failed'} (Code: ${e.code})';
            }
            _error = errorMessage;
          });
        },
        codeSent: (String verId, int? resendToken) async {
          print('🔍 Debug: Code sent successfully');
          print('🔍 Debug: Verification ID: $verId');
          print('🔍 Debug: Resend token: $resendToken');

          setState(() {
            _verificationId = verId;
            _resendToken = resendToken;
          });

          // Store verificationId in SharedPreferences for potential clearing
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('verification_id', verId);
          if (resendToken != null) {
            await prefs.setInt('resend_token', resendToken);
          }

          print('🔍 Debug: Verification ID stored in SharedPreferences');

          if (isResend) {
            _startResendCountdown();
          }
        },
        codeAutoRetrievalTimeout: (String verId) {
          print('🔍 Debug: Auto-retrieval timeout');
          print('🔍 Debug: Timeout verification ID: $verId');
          setState(() {
            _verificationId = verId;
          });
        },
      );
    } catch (e) {
      print('🔍 Debug: Exception during OTP send: $e');
      setState(() {
        _error = 'Failed to send verification code. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _verify(String code) async {
    final verId = _verificationId;
    if (verId == null) {
      print('🔍 Debug: No verification ID available');
      setState(() {
        _error = 'Code not sent yet. Tap Resend.';
      });
      return;
    }

    print('🔍 Debug: Starting OTP verification with code: $code');
    print('🔍 Debug: Verification ID: $verId');
    print('🔍 Debug: Code length: ${code.length}');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create credential to validate OTP
      final cred =
          PhoneAuthProvider.credential(verificationId: verId, smsCode: code);
      print('🔍 Debug: Credential created successfully');

      print('🔍 Debug: Attempting to sign in with credential...');
      try {
        final userCredential = await _auth.signInWithCredential(cred);
        print('🔍 Debug: OTP verification successful');
        print('🔍 Debug: User signed in: ${userCredential.user?.uid}');

        // Delete the Firebase Auth user to prevent ghost users.
        // We only use phone auth for OTP validation, not as a permanent account.
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.delete();
          print('🔍 Debug: Deleted temporary Firebase Auth user to prevent ghost user');
        }
      } catch (error) {
        print('🔍 Debug: Error during verification: $error');
        print('🔍 Debug: Error type: ${error.runtimeType}');
        print('🔍 Debug: Error toString: ${error.toString()}');

        if (error.toString().contains('PigeonUserDetails') ||
            error
                .toString()
                .contains('type \'List<Object?>\' is not a subtype')) {
          print('🔍 Debug: Pigeon error detected - assuming OTP is valid');

          try {
            final firebaseUser = _auth.currentUser;
            if (firebaseUser != null) {
              await firebaseUser.delete();
              print('🔍 Debug: Deleted temporary Firebase Auth user after pigeon error');
            }
          } catch (e) {
            // If delete fails, fall back to sign out
            try { await _auth.signOut(); } catch (_) {}
            print('🔍 Debug: Error deleting user, signed out instead: $e');
          }
        } else {
          print('🔍 Debug: Non-pigeon error - likely invalid OTP, rethrowing');
          rethrow;
        }
      }

      debugPrint(
        '[Signup/OTP] PhoneAuth credential validated → _onVerified() / backend signup',
      );
      _onVerified();
    } on FirebaseAuthException catch (e) {
      print('🔍 Debug: FirebaseAuthException caught: ${e.code} - ${e.message}');
      print(
          '🔍 Debug: Exception details - email: ${e.email}, phoneNumber: ${e.phoneNumber}');

      setState(() {
        String errorMessage = 'Invalid or expired code';
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Invalid verification code';
            break;
          case 'invalid-verification-id':
            errorMessage =
                'Verification session expired. Please request a new code';
            break;
          case 'session-expired':
            errorMessage =
                'Verification session has expired. Please request a new code';
            break;
          default:
            errorMessage =
                '${e.message ?? 'Invalid or expired code'} (Code: ${e.code})';
        }
        _error = errorMessage;
      });
    } catch (e) {
      print('🔍 Debug: General error during verification: $e');
      print('🔍 Debug: Error type: ${e.runtimeType}');
      setState(() {
        _error = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _onVerified() async {
    debugPrint(
      '[Signup/OTP] Firebase phone OTP verified — starting backend signup',
    );
    debugPrint(
      '[Signup/OTP] email=${widget.email} phone=${widget.phoneE164} name=${widget.fullName}',
    );

    // Delete any leftover Firebase Auth user to prevent ghost accounts
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.delete();
        debugPrint(
          '[Signup/OTP] Deleted leftover Firebase Auth user in _onVerified cleanup',
        );
      }
    } catch (e) {
      // If delete fails (e.g. already deleted), sign out as fallback
      try { await _auth.signOut(); } catch (_) {}
      debugPrint('[Signup/OTP] Firebase cleanup error (delete/signout): $e');
    }

    // Clear verification data
    await _clearStoredVerificationData();

    // Save the verified phone number locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signup_email', widget.email);
    await prefs.setString('signup_phone', widget.phoneE164);
    await prefs.setBool('phone_verified', true); // Mark phone as verified

    debugPrint('[Signup/OTP] SharedPreferences: signup_email, signup_phone, phone_verified=true');

    if (!mounted) return;

    // Call the signup API with verified data
    try {
      setState(() => _loading = true);

      debugPrint('[Signup/OTP] Calling signUp() → POST /authup');
      await signUp(
        context,
        widget.fullName,
        widget.email,
        widget.password,
        widget.phoneE164,
      );

      debugPrint('[Signup/OTP] signUp() finished (success dialog / navigation if applicable)');
    } catch (e) {
      debugPrint('[Signup/OTP] signUp() threw: $e (${e.runtimeType})');
      setState(() {
        _error = 'Signup failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.center,
              onPressed: () => Navigator.pop(context),
              icon: Transform.translate(
                offset: const Offset(3, 0),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            )),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              AppConstants.signupBG,
              fit: BoxFit.cover,
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1),

                        // Header Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Verify Phone Number",
                                style: TextStyle(
                                  fontFamily: "Poppins-Bold",
                                  fontSize: 32,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "We've sent a verification code to ${widget.phoneE164}",
                                style: TextStyle(
                                  fontFamily: "Poppins-Regular",
                                  fontSize: 16,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // OTP Input Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enter Verification Code",
                                style: TextStyle(
                                  fontFamily: "Poppins-SemiBold",
                                  fontSize: 18,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // OTP Input
                              Pinput(
                                controller: _otpController,
                                length: 6,
                                defaultPinTheme: PinTheme(
                                  width: 50,
                                  height: 50,
                                  textStyle: TextStyle(
                                    fontFamily: "Poppins-SemiBold",
                                    fontSize: 20,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 50,
                                  height: 50,
                                  textStyle: TextStyle(
                                    fontFamily: "Poppins-SemiBold",
                                    fontSize: 20,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF45A3D9),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF45A3D9)
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                onCompleted: (pin) {
                                  _verify(pin);
                                },
                              ),

                              // Error Message
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            fontFamily: "Poppins-Regular",
                                            fontSize: 14,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Verify Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          if (_otpController.text.length == 6) {
                                            _verify(_otpController.text);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF45A3D9),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    shadowColor: const Color(0xFF45A3D9)
                                        .withOpacity(0.3),
                                  ),
                                  child: _loading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Verifying...',
                                              style: TextStyle(
                                                fontFamily: "Poppins-SemiBold",
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Verify Code',
                                          style: TextStyle(
                                            fontFamily: "Poppins-SemiBold",
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Resend Code Button
                              Center(
                                child: TextButton(
                                  onPressed: _resendCountdown > 0 || _loading
                                      ? null
                                      : () {
                                          _sendOtp(isResend: true);
                                          _startResendCountdown();
                                        },
                                  child: Text(
                                    _resendCountdown > 0
                                        ? 'Resend code in $_resendCountdown seconds'
                                        : 'Resend verification code',
                                    style: TextStyle(
                                      fontFamily: "Poppins-SemiBold",
                                      fontSize: 14,
                                      color: _resendCountdown > 0 || _loading
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF45A3D9),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF3B82F6),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Enter the 6-digit code sent to your phone number to verify your account.",
                                  style: TextStyle(
                                    fontFamily: "Poppins-Regular",
                                    fontSize: 14,
                                    color: const Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
