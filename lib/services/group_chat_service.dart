import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/GroupMessage.dart';

class GroupChatService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createGroup({
    required String groupName,
    required String creatorId,
    required String creatorName,
    required List<String> memberIds,
    required List<String> memberNames,
    String? groupImageUrl,
  }) async {
    try {
      // Generate unique group ID
      String groupId = _firebaseFirestore.collection('groups').doc().id;

      // Add creator to members list if not already included
      List<String> allMemberIds = [...memberIds];
      List<String> allMemberNames = [...memberNames];

      if (!allMemberIds.contains(creatorId)) {
        allMemberIds.insert(0, creatorId);
        allMemberNames.insert(0, creatorName);
      }

      // Create group document
      await _firebaseFirestore.collection('groups').doc(groupId).set({
        'groupId': groupId,
        'groupName': groupName,
        'groupImageUrl': groupImageUrl ?? '',
        'creatorId': creatorId,
        'creatorName': creatorName,
        'memberIds': allMemberIds,
        'memberNames': allMemberNames,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': '',
      });

      return groupId;
    } catch (e) {
      throw Exception("Could not create group: $e");
    }
  }

  Future<String?> uploadGroupImage(File imageFile, String groupId) async {
    try {
      final String fileName =
          '${groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await _supabase.storage
          .from('group-chat-img')
          .upload(fileName, imageFile);

      if (response.isNotEmpty) {
        final String publicUrl = _supabase.storage
            .from('group-chat-img')
            .getPublicUrl(fileName);
        return publicUrl;
      }
      return null;
    } catch (e) {
      throw Exception("Could not upload image: $e");
    }
  }

  Future<void> addGroupMessage({
    required String groupId,
    required GroupMessage message,
  }) async {
    try {
      // Generate message ID if not provided
      String messageId = message.id.isEmpty
          ? _firebaseFirestore
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .doc()
                .id
          : message.id;

      GroupMessage messageWithId = message.copyWith(id: messageId);

      // Add message to subcollection
      await _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(messageWithId.toJson());

      // Update last message in group document
      await _firebaseFirestore.collection('groups').doc(groupId).update({
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': message.senderName,
      });
    } catch (e) {
      throw Exception("Could not send group message: $e");
    }
  }

  Stream<QuerySnapshot> getUserGroups(String userId) {
    return _firebaseFirestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getGroupDetails(String groupId) async {
    return await _firebaseFirestore.collection('groups').doc(groupId).get();
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      DocumentSnapshot groupDoc = await _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        List<String> memberIds = List<String>.from(data['memberIds']);
        List<String> memberNames = List<String>.from(data['memberNames']);

        int userIndex = memberIds.indexOf(userId);
        if (userIndex != -1) {
          String userName = memberNames[userIndex];
          memberIds.removeAt(userIndex);
          memberNames.removeAt(userIndex);

          await _firebaseFirestore.collection('groups').doc(groupId).update({
            'memberIds': memberIds,
            'memberNames': memberNames,
          });

          // Add system message about user leaving
          GroupMessage systemMessage = GroupMessage(
            id: '',
            senderId: 'system',
            senderName: 'System',
            content: '$userName left the group',
            sentAt: DateTime.now(),
            messageType: GroupMessageType.system,
          );

          await addGroupMessage(groupId: groupId, message: systemMessage);
        }
      }
    } catch (e) {
      throw Exception("Could not leave group: $e");
    }
  }

  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'senderName': senderName,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateGroupLastMessage(
    String groupId,
    String lastMessage,
  ) async {
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getGroupStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots();
  }

  Future<List<Map<String, dynamic>>> getGroupMembersInfo(
    List<String> memberIds,
  ) async {
    final members = await Future.wait(
      memberIds.map((id) async {
        final doc = await _firestore.collection('users').doc(id).get();
        return {
          'id': id,
          'name': doc.data()?['displayName'] ?? 'Unknown',
          'photoUrl': doc.data()?['photoURL'],
        };
      }),
    );
    return members;
  }

  Future<List<Map<String, dynamic>>> getCompleteUserDataForMembers(
    List<String> memberIds,
  ) async {
    try {
      final members = await Future.wait(
        memberIds.map((id) async {
          final doc = await _firestore.collection('users').doc(id).get();
          if (doc.exists) {
            return {
              'id': id,
              'name': doc.data()?['name'] ?? 'Unknown',
              'profileImageUrl': doc.data()?['profileImageUrl'],
              'activeStatus': doc.data()?['ActiveStatus'] ?? false,
              'userId': doc.data()?['userId'],
            };
          }
          return {
            'id': id,
            'name': 'Unknown',
            'profileImageUrl': null,
            'activeStatus': false,
            'userId': id,
          };
        }),
      );
      return members;
    } catch (e) {
      throw Exception("Could not fetch user data: $e");
    }
  }
}
