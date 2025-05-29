import 'package:kchat/services/cloud_service.dart';
import 'package:flutter/material.dart';
import 'package:kchat/services/chat_service.dart';
import 'package:get_it/get_it.dart';

class CreateGroupChatPage extends StatefulWidget {
  final String currentUserId;

  const CreateGroupChatPage({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  State<CreateGroupChatPage> createState() => _CreateGroupChatPageState();
}

class _CreateGroupChatPageState extends State<CreateGroupChatPage> {
  final GetIt _getIt = GetIt.instance;
  late ChatService _chatService;
  late CloudService _cloudService;
  late String _loggedInUserId;
  Map<String, dynamic>? _loggedInUserData;
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _selectedUserIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatService = _getIt.get<ChatService>();
    _cloudService = _getIt.get<CloudService>();
    _fetchUsers();
    _fetchLoggedInUserData();
  }

  Future<void> _fetchLoggedInUserData() async {
    _loggedInUserData =
        await _cloudService.fetchLoggedInUserData(userId: _loggedInUserId);
    await _fetchUsers();
    setState(() {});
  }

  Future<void> _fetchUsers() async {
    _allUsers = await _cloudService.fetchUsersForGroup(_loggedInUserId);
    setState(() {
      _isLoading = false;
    });
  }

  void _onUserChecked(bool? value, String userId) {
    setState(() {
      if (value == true) {
        _selectedUserIds.add(userId);
      } else {
        _selectedUserIds.remove(userId);
      }
    });
  }

  Future<void> _createGroupChat() async {
    if (_selectedUserIds.isEmpty) return;

    // Create a group chat with the selected users
    String groupId = await _chatService.createGroupChat(
      userIds: _selectedUserIds..add(widget.currentUserId),
    );

    // Navigate to the group chat page
    Navigator.pop(context, groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createGroupChat,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allUsers.length,
              itemBuilder: (context, index) {
                final user = _allUsers[index];
                final userId = user['userId'];

                return CheckboxListTile(
                  title: Text(user['name']),
                  value: _selectedUserIds.contains(userId),
                  onChanged: (value) => _onUserChecked(value, userId),
                );
              },
            ),
    );
  }
}
