import 'dart:io';
import 'dart:ui';
import 'package:delightful_toast/delight_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../services/group_chat_service.dart';

class CreateGroupModal extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final String loggedInUserId;
  final String loggedInUserName;

  const CreateGroupModal({
    super.key,
    required this.users,
    required this.loggedInUserId,
    required this.loggedInUserName,
  });

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal>
    with TickerProviderStateMixin {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late GroupChatService _groupChatService;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedMemberIds = [];
  List<String> _selectedMemberNames = [];
  bool _isCreating = false;
  List<Map<String, dynamic>> _filteredUsers = [];

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _groupChatService = _getIt.get<GroupChatService>();
    _filteredUsers = List.from(widget.users);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      _showGlassSnackBar(
        'Please enter group name',
        Icons.warning,
        Colors.orange,
      );
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      _showGlassSnackBar(
        'Please select at least one member',
        Icons.group_add,
        Colors.blue,
      );
      return;
    }
    setState(() {
      _isCreating = true;
    });
    try {
      String? groupImageUrl;
      if (_selectedImage != null) {
        String tempGroupId = DateTime.now().millisecondsSinceEpoch.toString();
        groupImageUrl = await _groupChatService.uploadGroupImage(
          _selectedImage!,
          tempGroupId,
        );
      }
      await _groupChatService.createGroup(
        groupName: _groupNameController.text.trim(),
        creatorId: widget.loggedInUserId,
        creatorName: widget.loggedInUserName,
        memberIds: _selectedMemberIds,
        memberNames: _selectedMemberNames,
        groupImageUrl: groupImageUrl,
      );
      Navigator.pop(context);
      DelightToastBar(
        builder: (context) => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.9),
                Colors.teal.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, size: 28, color: Colors.white),
              SizedBox(width: 12),
              Text(
                "Group created successfully!",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ).show(context);
    } catch (e) {
      _showGlassSnackBar('Error creating group: $e', Icons.error, Colors.red);
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showGlassSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = widget.users.where((user) {
        final userName = user['name'].toLowerCase();
        final searchQuery = query.toLowerCase();
        return userName.contains(searchQuery);
      }).toList();
    });
  }

  Widget _buildGlassContainer({
    required Widget child,
    double opacity = 0.1,
    double blur = 10,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(opacity * 0.5),
              ],
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
            const Color(0xFF0f3460),
            const Color(0xFF533483),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Animated Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: _buildGlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withOpacity(0.3),
                              Colors.pink.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create Group',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.3),
                              Colors.pink.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Image Selection with Glow Effect
                      Center(
                        child: _buildGlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.withOpacity(0.3),
                                        Colors.blue.withOpacity(0.3),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: _selectedImage != null
                                      ? ClipOval(
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 48,
                                          color: Colors.white70,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tap to add group photo',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Group Name Input
                      _buildGlassContainer(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Group Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _groupNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter group name',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.purpleAccent,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search Bar
                      _buildGlassContainer(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterUsers,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search members...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Colors.purpleAccent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Member Selection Header
                      _buildGlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Select Members',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.6),
                                    Colors.pink.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_selectedMemberIds.length}/20',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Members List
                      _buildGlassContainer(
                        child: Container(
                          height: 340,
                          padding: const EdgeInsets.all(8),
                          child: ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final isSelected = _selectedMemberIds.contains(
                                user['userId'],
                              );

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            Colors.purple.withOpacity(0.3),
                                            Colors.blue.withOpacity(0.3),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.purple.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged:
                                      _selectedMemberIds.length >= 20 &&
                                          !isSelected
                                      ? null
                                      : (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedMemberIds.add(
                                                user['userId'],
                                              );
                                              _selectedMemberNames.add(
                                                user['name'],
                                              );
                                            } else {
                                              _selectedMemberIds.remove(
                                                user['userId'],
                                              );
                                              _selectedMemberNames.remove(
                                                user['name'],
                                              );
                                            }
                                          });
                                        },
                                  secondary: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user['profileImageUrl'],
                                      ),
                                      radius: 22,
                                    ),
                                  ),
                                  title: Text(
                                    user['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  activeColor: Colors.purpleAccent,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Create Button with Gradient
              Container(
                padding: const EdgeInsets.all(24),
                child: _buildGlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.deepPurple,
                          Colors.indigo,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group_add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Create Group',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
