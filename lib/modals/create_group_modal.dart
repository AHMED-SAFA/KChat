// import 'dart:io';
// import 'package:delightful_toast/delight_toast.dart';
// import 'package:delightful_toast/toast/components/toast_card.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/group_chat_service.dart';
//
// class CreateGroupModal extends StatefulWidget {
//   final List<Map<String, dynamic>> users;
//   final String loggedInUserId;
//   final String loggedInUserName;
//
//   const CreateGroupModal({
//     super.key,
//     required this.users,
//     required this.loggedInUserId,
//     required this.loggedInUserName,
//   });
//
//   @override
//   State<CreateGroupModal> createState() => _CreateGroupModalState();
// }
//
// class _CreateGroupModalState extends State<CreateGroupModal> {
//   final TextEditingController _groupNameController = TextEditingController();
//   final GetIt _getIt = GetIt.instance;
//   late GroupChatService _groupChatService;
//
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//
//   List<String> _selectedMemberIds = [];
//   List<String> _selectedMemberNames = [];
//   bool _isCreating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _groupChatService = _getIt.get<GroupChatService>();
//   }
//
//   @override
//   void dispose() {
//     _groupNameController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.gallery,
//       maxWidth: 800,
//       maxHeight: 800,
//       imageQuality: 85,
//     );
//
//     if (image != null) {
//       setState(() {
//         _selectedImage = File(image.path);
//       });
//     }
//   }
//
//   Future<void> _createGroup() async {
//     if (_groupNameController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please enter group name')));
//       return;
//     }
//
//     if (_selectedMemberIds.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least one member')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isCreating = true;
//     });
//
//     try {
//       String? groupImageUrl;
//
//       // Upload image if selected
//       if (_selectedImage != null) {
//         String tempGroupId = DateTime.now().millisecondsSinceEpoch.toString();
//         groupImageUrl = await _groupChatService.uploadGroupImage(
//           _selectedImage!,
//           tempGroupId,
//         );
//       }
//
//       // Create group
//       await _groupChatService.createGroup(
//         groupName: _groupNameController.text.trim(),
//         creatorId: widget.loggedInUserId,
//         creatorName: widget.loggedInUserName,
//         memberIds: _selectedMemberIds,
//         memberNames: _selectedMemberNames,
//         groupImageUrl: groupImageUrl,
//       );
//
//       Navigator.pop(context);
//
//       DelightToastBar(
//         builder: (context) => const ToastCard(
//           leading: Icon(Icons.check_circle, size: 28, color: Colors.green),
//           title: Text(
//             "Group created successfully!",
//             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
//           ),
//         ),
//       ).show(context);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
//     } finally {
//       setState(() {
//         _isCreating = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.85,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple.shade50,
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(20),
//               ),
//             ),
//             child: Row(
//               children: [
//                 const Text(
//                   'Create New Group',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//           ),
//
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Group Image Selection
//                   Center(
//                     child: GestureDetector(
//                       onTap: _pickImage,
//                       child: Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade200,
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: Colors.grey.shade300,
//                             width: 2,
//                           ),
//                         ),
//                         child: _selectedImage != null
//                             ? ClipOval(
//                                 child: Image.file(
//                                   _selectedImage!,
//                                   fit: BoxFit.cover,
//                                 ),
//                               )
//                             : const Icon(
//                                 Icons.camera_alt,
//                                 size: 40,
//                                 color: Colors.grey,
//                               ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Center(
//                     child: Text(
//                       'Tap to add group photo (optional)',
//                       style: TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Group Name Input
//                   const Text(
//                     'Group Name',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _groupNameController,
//                     decoration: InputDecoration(
//                       hintText: 'Enter group name',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Member Selection
//                   Row(
//                     children: [
//                       const Text(
//                         'Select Members',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const Spacer(),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.deepPurple.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '${_selectedMemberIds.length}/20',
//                           style: TextStyle(
//                             color: Colors.deepPurple.shade700,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//
//                   // Members List
//                   Container(
//                     height: 300,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ListView.builder(
//                       itemCount: widget.users.length,
//                       itemBuilder: (context, index) {
//                         final user = widget.users[index];
//                         final isSelected = _selectedMemberIds.contains(
//                           user['userId'],
//                         );
//
//                         return CheckboxListTile(
//                           value: isSelected,
//                           onChanged:
//                               _selectedMemberIds.length >= 20 && !isSelected
//                               ? null
//                               : (bool? value) {
//                                   setState(() {
//                                     if (value == true) {
//                                       _selectedMemberIds.add(user['userId']);
//                                       _selectedMemberNames.add(user['name']);
//                                     } else {
//                                       _selectedMemberIds.remove(user['userId']);
//                                       _selectedMemberNames.remove(user['name']);
//                                     }
//                                   });
//                                 },
//                           secondary: CircleAvatar(
//                             backgroundImage: NetworkImage(
//                               user['profileImageUrl'],
//                             ),
//                             radius: 20,
//                           ),
//                           title: Text(
//                             user['name'],
//                             style: const TextStyle(fontWeight: FontWeight.w500),
//                           ),
//                           activeColor: Colors.deepPurple,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Create Button
//           Container(
//             padding: const EdgeInsets.all(20),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isCreating ? null : _createGroup,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.deepPurple,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _isCreating
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Text(
//                         'Create Group',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
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

class _CreateGroupModalState extends State<CreateGroupModal> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); // For search
  final GetIt _getIt = GetIt.instance;
  late GroupChatService _groupChatService;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedMemberIds = [];
  List<String> _selectedMemberNames = [];
  bool _isCreating = false;

  List<Map<String, dynamic>> _filteredUsers = []; // Filtered user list

  @override
  void initState() {
    super.initState();
    _groupChatService = _getIt.get<GroupChatService>();
    _filteredUsers = List.from(widget.users); // Initialize with all users
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose(); // Dispose search controller
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter group name')));
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }
    setState(() {
      _isCreating = true;
    });
    try {
      String? groupImageUrl;
      // Upload image if selected
      if (_selectedImage != null) {
        String tempGroupId = DateTime.now().millisecondsSinceEpoch.toString();
        groupImageUrl = await _groupChatService.uploadGroupImage(
          _selectedImage!,
          tempGroupId,
        );
      }
      // Create group
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
        builder: (context) => const ToastCard(
          leading: Icon(Icons.check_circle, size: 28, color: Colors.green),
          title: Text(
            "Group created successfully!",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ).show(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  // Filter users based on search query
  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = widget.users.where((user) {
        final userName = user['name'].toLowerCase();
        final searchQuery = query.toLowerCase();
        return userName.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Create New Group',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Image Selection
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
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
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Tap to add group photo (optional)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Group Name Input
                  const Text(
                    'Group Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter group name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _filterUsers, // Trigger filtering on text change
                    decoration: InputDecoration(
                      hintText: 'Search members',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Member Selection
                  Row(
                    children: [
                      const Text(
                        'Select Members',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedMemberIds.length}/20',
                          style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Members List
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isSelected = _selectedMemberIds.contains(
                          user['userId'],
                        );
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged:
                              _selectedMemberIds.length >= 20 && !isSelected
                              ? null
                              : (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMemberIds.add(user['userId']);
                                      _selectedMemberNames.add(user['name']);
                                    } else {
                                      _selectedMemberIds.remove(user['userId']);
                                      _selectedMemberNames.remove(user['name']);
                                    }
                                  });
                                },
                          secondary: CircleAvatar(
                            backgroundImage: NetworkImage(
                              user['profileImageUrl'],
                            ),
                            radius: 20,
                          ),
                          title: Text(
                            user['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          activeColor: Colors.deepPurple,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Create Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
