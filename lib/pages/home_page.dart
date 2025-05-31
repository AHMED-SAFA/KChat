import 'dart:async';

import 'package:kchat/pages/group_chat_page.dart';
import 'package:kchat/services/activeUser_service.dart';
import 'package:kchat/services/auth_service.dart';
import 'package:kchat/services/navigation_service.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../modals/create_group_modal.dart';
import '../services/chat_service.dart';
import '../services/cloud_service.dart';
import '../services/notification_service.dart';
import 'chat_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  int _unreadNotificationCount = 0;
  StreamSubscription<int>? _notificationCountSubscription;
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late CloudService _cloudService;
  String? _profileImageUrl;
  String _searchQuery = '';
  late ChatService _chatService;
  late ActiveUserService _activeUserService;
  late String _loggedInUserId;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  TextEditingController _searchController = TextEditingController();

  List<dynamic> _filteredUsers = [];
  Map<String, dynamic>? _loggedInUserData;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _activeUsersList = [];
  Map<String, bool> _activeUsers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _cloudService = _getIt.get<CloudService>();
    _chatService = _getIt.get<ChatService>();
    _activeUserService = _getIt.get<ActiveUserService>();
    _loggedInUserId = _authService.user!.uid;
    _fetchLoggedInUserData();
    _listenToNotificationCount();

    // Listen to active status changes
    _activeUserService.getActiveUsersStream().listen((activeUsers) {
      setState(() {
        _activeUsers = activeUsers;
        _updateActiveUsersList();
      });
    });
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchUsers();
  }

  // Add this method
  void _listenToNotificationCount() {
    _notificationCountSubscription = _getIt
        .get<NotificationService>()
        .getUnreadCountStream(receiverId: _loggedInUserId)
        .listen((count) {
          if (mounted) {
            setState(() {
              _unreadNotificationCount = count;
            });
          }
        });
  }

  void _updateActiveUsersList() {
    _activeUsersList = _users.where((user) {
      return _activeUsers[user['userId']] == true;
    }).toList();
  }

  Future<void> _fetchUsers() async {
    if (_loggedInUserData != null) {
      String department = _loggedInUserData!['department'];
      _profileImageUrl = _loggedInUserData?['profileImageUrl'];

      _users = await _cloudService.fetchRegisteredUsers(
        department: department,
        loggedInUserId: _loggedInUserId,
      );

      _updateActiveUsersList();

      setState(() {
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    }
  }

  Future<void> _fetchLoggedInUserData() async {
    _loggedInUserData = await _cloudService.fetchLoggedInUserData(
      userId: _loggedInUserId,
    );
    await _fetchUsers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: Colors.black,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const SizedBox(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading your connections...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _homeUI(),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF293f61),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: Color(0xFF293f61)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Good to see you!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loggedInUserData != null
                        ? _loggedInUserData!['name']
                        : 'Welcome',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_loggedInUserData != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _loggedInUserData!['department'],
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
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                iconSize: 30,
                onPressed: () {
                  _navigationService.pushNamed('/notification');
                },
              ),
              // Notification count badge
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _homeUI() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActiveSection(),
              const SizedBox(height: 22),
              _buildAllUsersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Now',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Text(
                '${_activeUsersList.length} online',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActiveUsersRow(),
        ],
      ),
    );
  }

  Widget _buildAllUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'All Colleagues',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredUsers.isEmpty && _searchQuery.isEmpty ? _users.length : _filteredUsers.length} total',
                  style: TextStyle(
                    color: Colors.deepPurple.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Box
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                    _filterUsers();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search colleagues...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade500),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _filteredUsers.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        _availableList(),
      ],
    );
  }

  void _filterUsers() {
    _filteredUsers = _users.where((user) {
      // Assuming user has a 'name' property. Adjust the property name as needed
      String userName = user['name'].toLowerCase();
      return userName.contains(_searchQuery);
    }).toList();
  }

  Widget _buildActiveUsersRow() {
    if (_activeUsersList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        child: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey, size: 20),
            SizedBox(width: 12),
            Text(
              'No one is active right now',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activeUsersList.length,
        itemBuilder: (context, index) {
          final activeUser = _activeUsersList[index];
          return GestureDetector(
            onTap: () => _navigateToChat(activeUser),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Hero(
                    tag: 'avatar_${activeUser['userId']}',
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: NetworkImage(
                              activeUser['profileImageUrl'],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 64,
                    child: Text(
                      activeUser['name'],
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        _showCreateGroupModal();
      },
      icon: const Icon(Icons.group_add),
      label: const Text('New Group'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    );
  }

  void _showCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupModal(
        users: _users,
        loggedInUserId: _loggedInUserId,
        loggedInUserName: _loggedInUserData!['name'],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2c3e50), // Dark slate
              Color(0xFF34495e), // Medium slate
              Color(0xFF455a64), // Light indigo
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Enhanced Header
            Container(
              height: 260,
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Image with Shadow and Border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF1a237e),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User Name with Better Typography
                  Text(
                    _loggedInUserData != null
                        ? "${_loggedInUserData!['name']}"
                        : 'Welcome User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status or Email (optional)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildEnhancedDrawerItem(
                    Icons.home_rounded,
                    'Home',
                    () => Navigator.pop(context),
                    isFirst: true,
                  ),
                  _buildEnhancedDrawerItem(
                    Icons.person_rounded,
                    'Profile',
                    () => _navigationService.pushNamed('/profile'),
                  ),
                  _buildEnhancedDrawerItem(
                    Icons.group_rounded,
                    'Groups',
                    () => _navigationService.pushNamed('/groupchat'),
                  ),
                  _buildEnhancedDrawerItem(
                    Icons.smart_toy_rounded,
                    'AI Assistants',
                    () => _navigationService.pushNamed('/aichatpage'),
                  ),

                  // Elegant Divider
                  Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  _buildEnhancedDrawerItem(
                    Icons.logout_rounded,
                    'Sign Out',
                    () => _showLogoutDialog(),
                    isDestructive: true,
                  ),
                  _buildEnhancedDrawerItem(
                    Icons.delete_forever_rounded,
                    'Delete Account',
                    () => _showDeleteAccountDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isFirst = false,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 4, top: isFirst ? 8 : 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.15)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red.shade300 : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red.shade300 : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDestructive
                      ? Colors.red.shade300.withOpacity(0.5)
                      : Colors.white.withOpacity(0.4),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await _cloudService.deleteUserAccount(user.uid);
                  _navigationService.pushReplacementNamed("/login");
                  DelightToastBar(
                    builder: (context) => const ToastCard(
                      leading: Icon(
                        Icons.check_circle,
                        size: 28,
                        color: Colors.green,
                      ),
                      title: Text(
                        "Account deleted successfully",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ).show(context);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to Logout?'),
          actions: [
            // cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _activeUserService.setInactive(_loggedInUserId);
                bool result = await _authService.logout();
                if (result) {
                  _navigationService.pushReplacementNamed("/login");
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _availableList() {
    List<dynamic> usersToShow = _searchQuery.isEmpty ? _users : _filteredUsers;

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: Colors.deepPurple,
      child: usersToShow.isEmpty
          ? SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No colleagues found'
                          : 'No matches found',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: usersToShow.length,
              itemBuilder: (context, index) {
                final user = usersToShow[index];
                return FutureBuilder<bool>(
                  future: _activeUserService.getActiveUsersStatus(
                    userID: user['userId'],
                  ),
                  builder: (context, snapshot) {
                    bool isActive = snapshot.data ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Hero(
                          tag: 'list_avatar_${user['userId']}',
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(
                                  user['profileImageUrl'],
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          user['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          isActive ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                        ),
                        onTap: () => _navigateToChat(user),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _navigateToChat(Map<String, dynamic> user) async {
    String chatId = await _chatService.createOrGetChat(
      userId1: _loggedInUserId,
      name1: _loggedInUserData!['name'],
      userId2: user['userId'],
      name2: user['name'],
    );

    _navigationService.push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          loggedInUserName: _loggedInUserData!['name'],
          otherUserName: user['name'],
          chatId: chatId,
          currentUserId: _loggedInUserId,
          otherUserId: user['userId'],
        ),
      ),
    );
  }
}
