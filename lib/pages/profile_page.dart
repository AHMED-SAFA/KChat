import 'package:kchat/services/media_service.dart';
import 'package:kchat/services/navigation_service.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/cloud_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late CloudService _cloudService;
  late MediaService _mediaService;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Storing original values before editing
  late String _originalName = '';
  late String _originalEmail = '';
  late String _originalPassword = '';
  late String _originalDepartment = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  File? _newProfileImage;
  String? _profileImageUrl;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _cloudService = _getIt.get<CloudService>();
    _navigationService = _getIt.get<NavigationService>();
    _mediaService = _getIt.get<MediaService>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? currentUser = _authService.user!;

    Map<String, dynamic>? userData = await _cloudService.fetchLoggedInUserData(
      userId: currentUser.uid,
    );
    if (userData != null) {
      setState(() {
        _nameController.text = userData['name'];
        _emailController.text = currentUser.email ?? '';
        _departmentController.text = userData['department'];
        _profileImageUrl = userData['profileImageUrl'];
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _updateUserData() async {
    User? currentUser = _authService.user!;

    if (_passwordController.text.isEmpty) {
      _showToast(
        'Password Required',
        'Enter your current password to save changes',
        Icons.lock_outline,
        Colors.grey,
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating profile...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Reauthenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _passwordController.text,
      );
      await currentUser.reauthenticateWithCredential(credential);

      String? newImageUrl;
      if (_newProfileImage != null) {
        newImageUrl = await _mediaService.uploadImageToStorage(
          _newProfileImage!,
          currentUser.uid,
        );

        setState(() {
          _profileImageUrl = newImageUrl;
        });
      }

      // Update data in Firestore
      await _cloudService.storeUserData(
        userId: currentUser.uid,
        name: _nameController.text,
        department: _departmentController.text,
        profileImageUrl: _profileImageUrl ?? '',
        activeStatus: true,
      );

      // Update email if modified
      if (_emailController.text != currentUser.email) {
        await currentUser.verifyBeforeUpdateEmail(_emailController.text);
      }

      // Update real-time database
      await _cloudService.storeUserDataInRealtimeDatabase(
        userId: currentUser.uid,
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        department: _departmentController.text,
      );

      Navigator.of(context).pop(); // Close loading dialog

      setState(() {
        _isEditing = false;
        _passwordController.clear();
      });

      _showToast(
        'Success!',
        'Your profile has been updated successfully',
        Icons.check_circle,
        Colors.white,
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showToast(
        'Error',
        'Failed to update profile. Please try again.',
        Icons.error,
        Colors.white,
      );
    }
  }

  void _showToast(String title, String message, IconData icon, Color color) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: Icon(icon, size: 28, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(message, style: const TextStyle(fontSize: 12)),
      ),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              'Loading your profile...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildProfileForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfileImage(),
                const SizedBox(height: 16),
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _departmentController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                _updateUserData();
              } else {
                _startEditing();
              }
            },
          ),
        ),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _selectProfileImage : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[800],
              backgroundImage: _newProfileImage != null
                  ? FileImage(_newProfileImage!)
                  : (_profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null)
                        as ImageProvider?,
              child: _profileImageUrl == null && _newProfileImage == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildElegantTextField(
              'Full Name',
              _nameController,
              Icons.person_outline,
              enabled: _isEditing,
            ),
            const SizedBox(height: 20),
            _buildElegantTextField(
              'Email Address',
              _emailController,
              Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 20),
            _buildElegantTextField(
              'Department',
              _departmentController,
              Icons.business_outlined,
              enabled: false,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildElegantTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? Colors.grey : Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(
          fontSize: 16,
          color: enabled ? Colors.black87 : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.black : Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? Colors.black : Colors.grey.shade400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Current Password (Required)',
          labelStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.black),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildElegantButton(
            'Cancel',
            Icons.close,
            Colors.grey.shade400,
            Colors.white,
            _cancelEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildElegantButton(
            'Save',
            Icons.check,
            Colors.black,
            Colors.white,
            _updateUserData,
          ),
        ),
      ],
    );
  }

  Widget _buildElegantButton(
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _originalName = _nameController.text;
      _originalEmail = _emailController.text;
      _originalPassword = _passwordController.text;
      _originalDepartment = _departmentController.text;
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _nameController.text = _originalName;
      _emailController.text = _originalEmail;
      _passwordController.text = _originalPassword;
      _departmentController.text = _originalDepartment;
      _newProfileImage = null;
      _isEditing = false;
      _showPassword = false;
    });
  }

  Future<void> _selectProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  'Camera',
                  Icons.camera_alt,
                  () => _pickImage(ImageSource.camera),
                ),
                _buildImageSourceOption(
                  'Gallery',
                  Icons.photo_library,
                  () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }
}
