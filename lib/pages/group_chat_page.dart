import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/group_chat_service.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final GetIt _getIt = GetIt.instance;
  late GroupChatService _groupChatService;
  late AuthService _authService;
  late NavigationService _navigationService;
  late String _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _groupChatService = _getIt.get<GroupChatService>();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _loggedInUserId = _authService.user!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Groups',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF293f61),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupChatService.getUserGroups(_loggedInUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading groups: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create or join a group to start chatting',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
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
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage:
                        groupData['groupImageUrl'] != null &&
                            groupData['groupImageUrl'].isNotEmpty
                        ? NetworkImage(groupData['groupImageUrl'])
                        : null,
                    child:
                        groupData['groupImageUrl'] == null ||
                            groupData['groupImageUrl'].isEmpty
                        ? Icon(
                            Icons.group,
                            color: Colors.deepPurple.shade700,
                            size: 28,
                          )
                        : null,
                  ),
                  title: Text(
                    groupData['groupName'] ?? 'Unknown Group',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${(groupData['memberIds'] as List).length} members',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${groupData['creatorName']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created at: ${DateFormat('MMM d, yyyy').format(groupData['createdAt'].toDate())}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (groupData['lastMessage'] != null &&
                          groupData['lastMessage'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            groupData['lastMessage'],
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.deepPurple.shade700,
                      size: 16,
                    ),
                  ),
                  onTap: () => _navigateToGroupChat(groupData),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToGroupChat(Map<String, dynamic> groupData) {
    // _navigationService.push(
    //   MaterialPageRoute(
    //     builder: (context) => GroupChatDetailPage(
    //       groupId: groupData['groupId'],
    //       groupName: groupData['groupName'],
    //       currentUserId: _loggedInUserId,
    //     ),
    //   ),
    // );
  }
}
