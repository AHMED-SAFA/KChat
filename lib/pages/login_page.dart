import 'package:firebase_auth/firebase_auth.dart';
import 'package:kchat/services/activeUser_service.dart';
import 'package:kchat/services/auth_service.dart';
import 'package:kchat/services/navigation_service.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  late ActiveUserService _activeUserService;
  final GlobalKey<FormState> _loginFormKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AuthService _authService;
  String? email, password;
  bool isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _authService = GetIt.I<AuthService>();
    _activeUserService = GetIt.I<ActiveUserService>();
    _navigationService = _getIt.get<NavigationService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.grey[50], body: _loginUI());
  }

  Widget _loginUI() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              if (!isLoading) _headerSection(),
              const SizedBox(height: 50),
              if (!isLoading) _loginCard(),
              const SizedBox(height: 30),
              if (!isLoading) _signUpSection(),
              if (isLoading) _loadingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to continue to ChatN",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _loginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _loginFormKey,
          child: Column(
            children: [
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 12),
              _forgotPasswordButton(),
              const SizedBox(height: 32),
              _loginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          child: const Icon(
            Icons.email_outlined,
            color: Color(0xFF0A0A0A),
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          child: const Icon(
            Icons.lock_outline,
            color: Color(0xFF0A0A0A),
            size: 20,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  Widget _forgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Handle forgot password
          _showForgotPasswordDialog();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color(0xFF6366F1),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle password reset
                Navigator.of(context).pop();
                _showResetEmailSentToast();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetEmailSentToast() {
    Fluttertoast.showToast(
      msg: 'Password reset link sent to your email!',
      toastLength: Toast.LENGTH_LONG, // approximately 3 seconds
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Widget _loginButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 50,
  //     child: ElevatedButton(
  //       onPressed: () async {
  //         if (_loginFormKey.currentState?.validate() ?? false) {
  //           setState(() {
  //             isLoading = true;
  //           });
  //           email = _emailController.text;
  //           password = _passwordController.text;
  //           bool success = await _authService.login(email!, password!);
  //           if (success) {
  //             Fluttertoast.showToast(
  //               msg: 'Welcome back! Login successful',
  //               toastLength: Toast.LENGTH_LONG, // ~3 seconds
  //               gravity: ToastGravity.BOTTOM, // Position at bottom
  //               backgroundColor: Colors.green, // Success color
  //               textColor: Colors.white,
  //               fontSize: 14.0,
  //               timeInSecForIosWeb: 3, // Explicitly set duration for iOS/Web
  //             );
  //             _activeUserService.setActive(_authService.user!.uid);
  //             _navigationService.pushReplacementNamed("/home");
  //           } else {
  //             setState(() {
  //               isLoading = false;
  //             });
  //             DelightToastBar(
  //               builder: (context) => const ToastCard(
  //                 leading: Icon(
  //                   Icons.error_outline,
  //                   size: 28,
  //                   color: Colors.red,
  //                 ),
  //                 title: Text(
  //                   "Login failed. Please check your credentials and try again.",
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.w600,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ),
  //             ).show(context);
  //           }
  //         }
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: const Color(0xFF6366F1),
  //         foregroundColor: Colors.white,
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //       ),
  //       child: const Text(
  //         "Sign In",
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w600,
  //           letterSpacing: 0.5,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Replace your _loginButton method with this:

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          if (_loginFormKey.currentState?.validate() ?? false) {
            setState(() {
              isLoading = true;
            });
            email = _emailController.text;
            password = _passwordController.text;

            try {
              bool success = await _authService.login(email!, password!);
              if (success) {
                Fluttertoast.showToast(
                  msg: 'Welcome back! Login successful',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 14.0,
                  timeInSecForIosWeb: 3,
                );
                _activeUserService.setActive(_authService.user!.uid);
                _navigationService.pushReplacementNamed("/home");
              }
            } catch (e) {
              setState(() {
                isLoading = false;
              });

              String errorMessage =
                  "Login failed. Please check your credentials and try again.";

              if (e is FirebaseAuthException) {
                if (e.code == 'email-not-verified') {
                  // Show email verification dialog
                  _showEmailVerificationDialog();
                  return;
                } else if (e.code == 'user-not-found') {
                  errorMessage = "No account found with this email address.";
                } else if (e.code == 'wrong-password') {
                  errorMessage = "Incorrect password. Please try again.";
                } else if (e.code == 'invalid-email') {
                  errorMessage = "Invalid email address format.";
                }
              }

              DelightToastBar(
                builder: (context) => ToastCard(
                  leading: const Icon(
                    Icons.error_outline,
                    size: 28,
                    color: Colors.red,
                  ),
                  title: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ).show(context);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Sign In",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Add this method to your _LoginState class:
  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Email Verification Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 64,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 16),
              Text(
                'Please verify your email address before logging in. Check your inbox for the verification email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Use the email and password from the form controllers
                  await _authService.resendVerificationEmail(
                    _emailController.text,
                    _passwordController.text,
                  );
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(
                    msg:
                        'New verification email sent! Please check your inbox.',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.blue,
                    textColor: Colors.white,
                    fontSize: 14.0,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  String errorMsg =
                      'Failed to send verification email. Please try again.';
                  if (e is FirebaseAuthException) {
                    if (e.code == 'wrong-password') {
                      errorMsg =
                          'Incorrect password. Cannot send verification email.';
                    } else if (e.code == 'user-not-found') {
                      errorMsg = 'Account not found. Please check your email.';
                    }
                  }
                  Fluttertoast.showToast(
                    msg: errorMsg,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 14.0,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Resend Verification',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _loadingSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF070707)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Signing you in...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signUpSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: () {
              _navigationService.pushNamed("/register");
            },
            child: const Text(
              "Sign Up",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
