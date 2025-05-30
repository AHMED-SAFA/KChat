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

class _ChatGroupPageState extends State<ChatGroupPage> {
  final GetIt _getIt = GetIt.instance;
  late GroupChatService _groupChatService;
  late CloudService _cloudService;
  late AuthService _authService;
  Map<String, dynamic>? _loggedInUserData;
  List<String> memberIds = [];
  List<Map<String, dynamic>> _membersData = [];
  late String _loggedInUserId;
  String? _loggedInUserName;
  ChatUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
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
    } catch (e) {
      // Handle error
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load members: $e')));
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

  // Helper method to check if URL is valid
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
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
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final memberCount = (data['memberIds'] as List).length;
                  return Text(
                    '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF293f61),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGroupInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _groupChatService.getGroupMessages(
                widget.groupData['groupId'],
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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

                  String messageText = data['text'] ?? data['content'] ?? '';
                  String senderName = data['senderName'] ?? 'Unknown';

                  return ChatMessage(
                    user: ChatUser(
                      id: data['senderId'],
                      firstName: senderName.split(' ').first,
                      lastName: senderName.split(' ').length > 1
                          ? senderName.split(' ').last
                          : '',
                    ),
                    text: messageText,
                    createdAt: messageTime,
                  );
                }).toList();

                return DashChat(
                  currentUser: _currentUser!,
                  messages: chatMessages,
                  onSend: (ChatMessage message) {
                    _sendMessage(message.text);
                  },
                  inputOptions: InputOptions(
                    textCapitalization: TextCapitalization.sentences,
                    inputDecoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    sendButtonBuilder: (Function onSend) {
                      return IconButton(
                        icon: const Icon(Icons.send),
                        color: const Color(0xFF293f61),
                        onPressed: () => onSend(),
                      );
                    },
                  ),
                  messageOptions: MessageOptions(
                    currentUserContainerColor: const Color(0xFF293f61),
                    containerColor: Colors.grey[300]!,
                    textColor: Colors.black,
                    currentUserTextColor: Colors.white,
                    showTime: true,
                    timeFormat: DateFormat('h:mm a'),
                  ),
                );
              },
            ),
          ),
        ],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Group avatar and name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.deepPurple.shade100,
                          backgroundImage:
                              _isValidImageUrl(
                                widget.groupData['groupImageUrl'],
                              )
                              ? NetworkImage(widget.groupData['groupImageUrl'])
                              : null,
                          child:
                              !_isValidImageUrl(
                                widget.groupData['groupImageUrl'],
                              )
                              ? Icon(
                                  Icons.group,
                                  color: Colors.deepPurple.shade700,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.groupData['groupName'] ?? 'Group',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Group Info
                  const Text(
                    'Group Info',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by: ${widget.groupData['creatorName'] ?? 'Unknown'}',
                  ),
                  Text(
                    'Created on: ${widget.groupData['createdAt'] != null ? DateFormat('MMM d, yyyy').format(widget.groupData['createdAt'].toDate()) : 'Unknown'}',
                  ),

                  const SizedBox(height: 24),

                  // Members List from _membersData
                  const Text(
                    'Members',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _membersData.isEmpty
                        ? const Center(child: Text('No members found'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _membersData.length,
                            itemBuilder: (context, index) {
                              final member = _membersData[index];
                              final isCreator =
                                  member['id'] == widget.groupData['creatorId'];

                              // Safe access to member data
                              final memberName =
                                  member['name'] ?? 'Unknown User';
                              final memberPhotoUrl =
                                  member['profileImageUrl'] ??
                                  member['photoUrl'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  backgroundImage:
                                      _isValidImageUrl(memberPhotoUrl)
                                      ? NetworkImage(memberPhotoUrl!)
                                      : null,
                                  child: !_isValidImageUrl(memberPhotoUrl)
                                      ? Text(
                                          memberName.isNotEmpty
                                              ? memberName[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple.shade700,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  memberName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: isCreator
                                    ? const Text(
                                        'Group Admin',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : null,
                                trailing: isCreator
                                    ? Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.deepPurple.shade700,
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
