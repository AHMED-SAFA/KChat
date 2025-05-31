import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/group_chat_service.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import 'chat_page_group.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage>
    with TickerProviderStateMixin {
  final GetIt _getIt = GetIt.instance;
  late GroupChatService _groupChatService;
  late AuthService _authService;
  late NavigationService _navigationService;
  late String _loggedInUserId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _groupChatService = _getIt.get<GroupChatService>();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _loggedInUserId = _authService.user!.uid;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF), // Light background
      appBar: AppBar(
        title: const Text(
          'Groups',
          style: TextStyle(
            color: Color(0xFF333366), // Darker text for contrast
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFE6E6FA), // Light purple background
        iconTheme: const IconThemeData(color: Color(0xFF666699)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE6E6FA), Color(0xFFF5F5FF)], // Light gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupChatService.getUserGroups(_loggedInUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6FA), // Light container
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF9370DB), // Medium purple
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading groups...',
                    style: TextStyle(color: Color(0xFF666699), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6FA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        color: Color(0xFF333366),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading groups: ${snapshot.error}',
                      style: const TextStyle(
                        color: Color(0xFF666699),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6FA),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9370DB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 64,
                        color: Color(0xFF9370DB),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No groups yet',
                      style: TextStyle(
                        fontSize: 22,
                        color: Color(0xFF333366),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Create or join a group to start\nchatting with friends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666699),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Create group functionality
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9370DB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          List<DocumentSnapshot> groups = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> groupData =
                  groups[index].data() as Map<String, dynamic>;

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE6E6FA),
                        const Color(0xFFF0F0FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF9370DB).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _navigateToGroupChat(groupData),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Group Avatar
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF9370DB,
                                    ).withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient:
                                        groupData['groupImageUrl'] == null ||
                                            groupData['groupImageUrl'].isEmpty
                                        ? LinearGradient(
                                            colors: [
                                              const Color(0xFF9370DB),
                                              const Color(0xFFB19CD9),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                  ),
                                  child:
                                      groupData['groupImageUrl'] != null &&
                                          groupData['groupImageUrl'].isNotEmpty
                                      ? Image.network(
                                          groupData['groupImageUrl'],
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.groups_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Group Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupData['groupName'] ?? 'Unknown Group',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF333366),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF9370DB,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.people_rounded,
                                              size: 14,
                                              color: Color(0xFF9370DB),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${(groupData['memberIds'] as List).length}',
                                              style: const TextStyle(
                                                color: Color(0xFF9370DB),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'by ${groupData['creatorName']}',
                                          style: const TextStyle(
                                            color: Color(0xFF666699),
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat(
                                      'MMM d, yyyy',
                                    ).format(groupData['createdAt'].toDate()),
                                    style: const TextStyle(
                                      color: Color(0xFF666699),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9370DB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF9370DB),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToGroupChat(Map<String, dynamic> groupData) {
    _navigationService.push(
      MaterialPageRoute(
        builder: (context) => ChatGroupPage(groupData: groupData),
      ),
    );
  }
}
