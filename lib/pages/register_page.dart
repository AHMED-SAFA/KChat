import 'dart:io';
import 'package:kchat/services/cloud_service.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:toastification/toastification.dart';
import '../services/auth_service.dart';
import '../services/media_service.dart';
import '../services/navigation_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  File? selectedImage;
  String avatar =
      "https://media.istockphoto.com/id/1300845620/vector/user-icon-flat-isolated-on-white-background-user-symbol-vector-illustration.jpg?s=612x612&w=0&k=20&c=yBeyba0hUkh14_jgv1OKqIH0CCSWU_4ckRkAoy2p73o=";
  final GetIt _getIt = GetIt.instance;
  late CloudService _cloudService;
  late NavigationService _navigationService;
  final GlobalKey<FormState> _regFormKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AuthService _authService;
  late MediaService _mediaService;
  String? email, password, name, department;
  bool isLoading = false;
  bool _isPasswordVisible = false;

  // List of departments
  final List<String> _departments_name_available = [
    'CSE',
    'EEE',
    'ME',
    'CE',
    'BME',
    'Arch',
    'ECE',
    'URP'
  ];

  @override
  void initState() {
    super.initState();
    _authService = GetIt.I<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _mediaService = _getIt.get<MediaService>();
    _cloudService = _getIt.get<CloudService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF6366F1),
              size: 18,
            ),
          ),
          onPressed: () => _navigationService.goBack(),
        ),
      ),
      body: _regUI(),
    );
  }

  Widget _regUI() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isLoading) _regHeader(),
              const SizedBox(height: 30),
              if (!isLoading) _registrationCard(),
              const SizedBox(height: 30),
              if (!isLoading) _loginButtonText(),
              if (isLoading) _loadingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _regHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Create Account",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join ChatN and connect with your peers",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _registrationCard() {
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
          key: _regFormKey,
          child: Column(
            children: [
              _imagePicker(),
              const SizedBox(height: 32),
              _buildNameField(),
              const SizedBox(height: 20),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildDepartmentDropdown(),
              const SizedBox(height: 32),
              _registerButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.grey[200],
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : NetworkImage(avatar) as ImageProvider,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  File? file = await _mediaService.getImageFromGallery();
                  if (file != null) {
                    setState(() {
                      selectedImage = file;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          selectedImage == null
              ? "Tap to add profile photo"
              : "Tap to change photo",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          child: const Icon(
            Icons.person_outline,
            color: Color(0xFF000000),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
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
            color: Color(0xFF000000),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            color: Color(0xFF000000),
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
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: department,
      style: const TextStyle(fontSize: 16, color: Colors.black),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
      decoration: InputDecoration(
        labelText: 'Department',
        hintText: 'Select your department',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          child: const Icon(
            Icons.school_outlined,
            color: Color(0xFF000000),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      items: _departments_name_available.map((String dept) {
        return DropdownMenuItem<String>(
          value: dept,
          child: Text(dept),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          department = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your department';
        }
        return null;
      },
    );
  }

  Widget _registerButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (_regFormKey.currentState?.validate() ?? false) {
            if (selectedImage == null) {
              DelightToastBar(
                builder: (context) => const ToastCard(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    size: 28,
                    color: Colors.orange,
                  ),
                  title: Text(
                    "Please select a profile photo to continue",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ).show(context);
              return;
            }

            setState(() {
              isLoading = true;
            });

            try {
              email = _emailController.text;
              password = _passwordController.text;
              name = _nameController.text;
              String? selectedDepartment = department;

              // Firebase Authentication
              UserCredential userCredential =
                  await _authService.register(email!, password!);

              String? userId = userCredential.user?.uid;

              // Upload image to Firebase Storage
              String? imageUrl = await _mediaService.uploadImageToStorage(
                selectedImage!,
                userId!,
              );

              // Store user data in Firestore
              await _cloudService.storeUserData(
                activeStatus: true,
                userId: userId,
                name: name!,
                department: selectedDepartment!,
                profileImageUrl: imageUrl,
              );

              // Store user data in Realtime Database
              await _cloudService.storeUserDataInRealtimeDatabase(
                userId: userId,
                name: name!,
                email: email!,
                password: password!,
                department: selectedDepartment,
              );

              toastification.show(
                context: context,
                title: const Text(
                    'Account created successfully! Welcome to ChatN'),
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                autoCloseDuration: const Duration(seconds: 3),
                animationDuration: const Duration(milliseconds: 400),
                alignment: Alignment.bottomCenter,
                animationBuilder: (context, animation, alignment, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1.0), // Slide from bottom
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                showProgressBar: true,
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              );
              _navigationService.pushReplacementNamed("/home");
            } catch (error) {
              DelightToastBar(
                builder: (context) => const ToastCard(
                  leading: Icon(
                    Icons.error_outline,
                    size: 28,
                    color: Colors.red,
                  ),
                  title: Text(
                    "Registration failed. Please check your details and try again.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ).show(context);
            } finally {
              setState(() {
                isLoading = false;
              });
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
          "Create Account",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _loadingSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Creating your account...',
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

  Widget _loginButtonText() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          GestureDetector(
            onTap: () {
              _navigationService.goBack();
            },
            child: const Text(
              "Sign In",
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
