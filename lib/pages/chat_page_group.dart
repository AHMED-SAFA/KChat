import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:intl/intl.dart';
import '../services/cloud_service.dart';
import '../services/group_chat_service.dart';
import '../services/auth_service.dart';

class ChatGroupPage extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const ChatGroupPage({super.key, required this.groupData});

  @override
  State<ChatGroupPage> createState() => _ChatGroupPageState();
}

class _ChatGroupPageState extends State<ChatGroupPage>
    with TickerProviderStateMixin {
  final GetIt _getIt = GetIt.instance;
  late GroupChatService _groupChatService;
  late CloudService _cloudService;
  late AuthService _authService;
  Map<String, dynamic>? _loggedInUserData;
  List<String> memberIds = [];
  List<Map<String, dynamic>> _membersData = [];
  Map<String, String?> _userProfileImages = {};
  late String _loggedInUserId;
  String? _loggedInUserName;
  ChatUser? _currentUser;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Initialize services
      _groupChatService = _getIt.get<GroupChatService>();
      _cloudService = _getIt.get<CloudService>();
      _authService = _getIt.get<AuthService>();

      // Get user ID
      _loggedInUserId = _authService.user!.uid;
      await fetchAndStoreMemberIds(widget.groupData['groupId']);
      await _loadMembersData();
      await _cacheUserProfileImages();

      // Fetch user data
      _loggedInUserData = await _cloudService.fetchLoggedInUserData(
        userId: _loggedInUserId,
      );

      if (_loggedInUserData != null) {
        _loggedInUserName = _loggedInUserData!['name'];

        // Initialize current user
        _currentUser = ChatUser(
          id: _loggedInUserId,
          firstName: _loggedInUserName!.split(' ').first,
          lastName: _loggedInUserName!.split(' ').length > 1
              ? _loggedInUserName!.split(' ').last
              : '',
          profileImage: _authService.user!.photoURL,
        );
      }
      _animationController.forward();
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cacheUserProfileImages() async {
    for (var member in _membersData) {
      String userId = member['id'];
      String? profileImageUrl = member['profileImageUrl'] ?? member['photoUrl'];
      _userProfileImages[userId] = profileImageUrl;
    }
  }

  Future<void> _loadMembersData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final membersData = await _groupChatService.getCompleteUserDataForMembers(
        memberIds,
      );
      setState(() {
        _membersData = membersData;
        print("member datas are:");
        print(_membersData);
      });

      await _cacheUserProfileImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load members: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAndStoreMemberIds(String groupId) async {
    try {
      memberIds.clear();

      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        memberIds = List<String>.from(groupDoc['memberIds']);
        print('Fetched member IDs: $memberIds');
      }
    } catch (e) {
      print('Error fetching member IDs: $e');
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading chat...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              // borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'group_avatar_${widget.groupData['groupId']}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage:
                      _isValidImageUrl(widget.groupData['groupImageUrl'])
                      ? NetworkImage(widget.groupData['groupImageUrl'])
                      : null,
                  child: !_isValidImageUrl(widget.groupData['groupImageUrl'])
                      ? Icon(Icons.group, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupData['groupName'] ?? 'Group Chat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _groupChatService.getGroupStream(
                      widget.groupData['groupId'],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final memberCount = (data['memberIds'] as List).length;
                        return Text(
                          '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => _showGroupInfo(),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _groupChatService.getGroupMessages(
                    widget.groupData['groupId'],
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Something went wrong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data?.docs ?? [];
                    List<ChatMessage> chatMessages = messages.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      DateTime messageTime;
                      if (data['timestamp'] != null) {
                        messageTime = (data['timestamp'] as Timestamp).toDate();
                      } else if (data['sentAt'] != null) {
                        messageTime = (data['sentAt'] as Timestamp).toDate();
                      } else {
                        messageTime = DateTime.now();
                      }

                      String messageText =
                          data['text'] ?? data['content'] ?? '';
                      String senderName = data['senderName'] ?? 'Unknown';
                      String senderId = data['senderId'];
                      String? profileImageUrl = _userProfileImages[senderId];

                      return ChatMessage(
                        user: ChatUser(
                          id: senderId,
                          firstName: senderName.split(' ').first,
                          lastName: senderName.split(' ').length > 1
                              ? senderName.split(' ').last
                              : '',
                          profileImage: _isValidImageUrl(profileImageUrl)
                              ? profileImageUrl
                              : null,
                        ),
                        text: messageText,
                        createdAt: messageTime,
                      );
                    }).toList();

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: DashChat(
                        currentUser: _currentUser!,
                        messages: chatMessages,
                        onSend: (ChatMessage message) {
                          _sendMessage(message.text);
                        },
                        inputOptions: InputOptions(
                          textCapitalization: TextCapitalization.sentences,
                          inputDecoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          sendButtonBuilder: (Function onSend) {
                            return Container(
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF667EEA,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => onSend(),
                              ),
                            );
                          },
                        ),
                        messageOptions: MessageOptions(
                          currentUserContainerColor: const Color(0xFF667EEA),
                          containerColor: Colors.white,
                          textColor: Colors.grey.shade800,
                          currentUserTextColor: Colors.white,
                          showTime: true,
                          timeFormat: DateFormat('h:mm a'),
                          showOtherUsersAvatar: true,
                          showCurrentUserAvatar: true,
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                          borderRadius: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _groupChatService.sendGroupMessage(
        groupId: widget.groupData['groupId'],
        senderId: _loggedInUserId,
        senderName: _loggedInUserName ?? 'Unknown',
        text: text,
      );

      await _groupChatService.updateGroupLastMessage(
        widget.groupData['groupId'],
        text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle and header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Group Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Group header card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0F2027),
                              Color(0xFF203A43),
                              Color(0xFF2C5364),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Hero(
                              tag:
                                  'group_info_avatar_${widget.groupData['groupId']}',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  backgroundImage:
                                      _isValidImageUrl(
                                        widget.groupData['groupImageUrl'],
                                      )
                                      ? NetworkImage(
                                          widget.groupData['groupImageUrl'],
                                        )
                                      : null,
                                  child:
                                      !_isValidImageUrl(
                                        widget.groupData['groupImageUrl'],
                                      )
                                      ? Icon(
                                          Icons.group,
                                          color: Colors.white,
                                          size: 40,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.groupData['groupName'] ?? 'Group',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_membersData.length} members',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Group info section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Group Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Created by',
                              widget.groupData['creatorName'] ?? 'Unknown',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today_outlined,
                              'Created on',
                              widget.groupData['createdAt'] != null
                                  ? DateFormat('MMM d, yyyy').format(
                                      widget.groupData['createdAt'].toDate(),
                                    )
                                  : 'Unknown',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Members section
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Members (${_membersData.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Members list
                      _membersData.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No members found',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: _membersData.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final member = entry.value;
                                final isCreator =
                                    member['id'] ==
                                    widget.groupData['creatorId'];
                                final memberName =
                                    member['name'] ?? 'Unknown User';
                                final memberPhotoUrl =
                                    member['profileImageUrl'] ??
                                    member['photoUrl'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'member_avatar_${member['id']}',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: isCreator
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFFFD700),
                                                      Color(0xFFFFA500),
                                                    ],
                                                  )
                                                : null,
                                            border: Border.all(
                                              color: isCreator
                                                  ? Colors.amber.shade300
                                                  : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            backgroundImage:
                                                _isValidImageUrl(memberPhotoUrl)
                                                ? NetworkImage(memberPhotoUrl!)
                                                : null,
                                            child:
                                                !_isValidImageUrl(
                                                  memberPhotoUrl,
                                                )
                                                ? Text(
                                                    memberName.isNotEmpty
                                                        ? memberName[0]
                                                              .toUpperCase()
                                                        : 'U',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontSize: 18,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              memberName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (isCreator) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFFD700),
                                                          Color(0xFFFFA500),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'Group Admin',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isCreator)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.admin_panel_settings,
                                            color: Colors.amber.shade600,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
