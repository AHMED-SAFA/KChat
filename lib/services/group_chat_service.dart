import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/message.dart';

class GroupChatService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

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
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
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
    required Message message,
  }) async {
    try {
      // Add message to subcollection
      await _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(message.toJson());

      // Update last message in group document
      await _firebaseFirestore.collection('groups').doc(groupId).update({
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Could not send group message: $e");
    }
  }

  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firebaseFirestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();
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
          memberIds.removeAt(userIndex);
          memberNames.removeAt(userIndex);

          await _firebaseFirestore.collection('groups').doc(groupId).update({
            'memberIds': memberIds,
            'memberNames': memberNames,
          });
        }
      }
    } catch (e) {
      throw Exception("Could not leave group: $e");
    }
  }
}
