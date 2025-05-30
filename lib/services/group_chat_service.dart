// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:io';
// import '../models/message.dart';
//
// class GroupChatService {
//
//   final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   Future<String> createGroup({
//     required String groupName,
//     required String creatorId,
//     required String creatorName,
//     required List<String> memberIds,
//     required List<String> memberNames,
//     String? groupImageUrl,
//   }) async {
//     try {
//       // Generate unique group ID
//       String groupId = _firebaseFirestore.collection('groups').doc().id;
//
//       // Add creator to members list if not already included
//       List<String> allMemberIds = [...memberIds];
//       List<String> allMemberNames = [...memberNames];
//
//       if (!allMemberIds.contains(creatorId)) {
//         allMemberIds.insert(0, creatorId);
//         allMemberNames.insert(0, creatorName);
//       }
//
//       // Create group document
//       await _firebaseFirestore.collection('groups').doc(groupId).set({
//         'groupId': groupId,
//         'groupName': groupName,
//         'groupImageUrl': groupImageUrl ?? '',
//         'creatorId': creatorId,
//         'creatorName': creatorName,
//         'memberIds': allMemberIds,
//         'memberNames': allMemberNames,
//         'createdAt': FieldValue.serverTimestamp(),
//         'lastMessageTime': FieldValue.serverTimestamp(),
//       });
//
//       return groupId;
//     } catch (e) {
//       throw Exception("Could not create group: $e");
//     }
//   }
//
//   Future<String?> uploadGroupImage(File imageFile, String groupId) async {
//     try {
//       final String fileName =
//           '${groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
//
//       final response = await _supabase.storage
//           .from('group-chat-img')
//           .upload(fileName, imageFile);
//
//       if (response.isNotEmpty) {
//         final String publicUrl = _supabase.storage
//             .from('group-chat-img')
//             .getPublicUrl(fileName);
//         return publicUrl;
//       }
//       return null;
//     } catch (e) {
//       throw Exception("Could not upload image: $e");
//     }
//   }
//
//   Future<void> addGroupMessage({
//     required String groupId,
//     required Message message,
//   }) async {
//     try {
//       // Add message to subcollection
//       await _firebaseFirestore
//           .collection('groups')
//           .doc(groupId)
//           .collection('messages')
//           .add(message.toJson());
//
//       // Update last message in group document
//       await _firebaseFirestore.collection('groups').doc(groupId).update({
//         'lastMessage': message.content,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       throw Exception("Could not send group message: $e");
//     }
//   }
//
//   Stream<QuerySnapshot> getGroupMessages(String groupId) {
//     return _firebaseFirestore
//         .collection('groups')
//         .doc(groupId)
//         .collection('messages')
//         .orderBy('sentAt', descending: true)
//         .snapshots();
//   }
//
//   Stream<QuerySnapshot> getUserGroups(String userId) {
//     return _firebaseFirestore
//         .collection('groups')
//         .where('memberIds', arrayContains: userId)
//         .orderBy('lastMessageTime', descending: true)
//         .snapshots();
//   }
//
//   Future<DocumentSnapshot> getGroupDetails(String groupId) async {
//     return await _firebaseFirestore.collection('groups').doc(groupId).get();
//   }
//
//   Future<void> leaveGroup(String groupId, String userId) async {
//     try {
//       DocumentSnapshot groupDoc = await _firebaseFirestore
//           .collection('groups')
//           .doc(groupId)
//           .get();
//
//       if (groupDoc.exists) {
//         Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
//         List<String> memberIds = List<String>.from(data['memberIds']);
//         List<String> memberNames = List<String>.from(data['memberNames']);
//
//         int userIndex = memberIds.indexOf(userId);
//         if (userIndex != -1) {
//           memberIds.removeAt(userIndex);
//           memberNames.removeAt(userIndex);
//
//           await _firebaseFirestore.collection('groups').doc(groupId).update({
//             'memberIds': memberIds,
//             'memberNames': memberNames,
//           });
//         }
//       }
//     } catch (e) {
//       throw Exception("Could not leave group: $e");
//     }
//   }
// }

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

  Future<String?> uploadMessageImage(File imageFile, String groupId) async {
    try {
      final String fileName =
          'msg_${groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await _supabase.storage
          .from('group-message-images')
          .upload(fileName, imageFile);

      if (response.isNotEmpty) {
        final String publicUrl = _supabase.storage
            .from('group-message-images')
            .getPublicUrl(fileName);
        return publicUrl;
      }
      return null;
    } catch (e) {
      throw Exception("Could not upload message image: $e");
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

  Future<void> addMemberToGroup({
    required String groupId,
    required String memberId,
    required String memberName,
    required String addedByName,
  }) async {
    try {
      DocumentSnapshot groupDoc = await _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        List<String> memberIds = List<String>.from(data['memberIds']);
        List<String> memberNames = List<String>.from(data['memberNames']);

        if (!memberIds.contains(memberId)) {
          memberIds.add(memberId);
          memberNames.add(memberName);

          await _firebaseFirestore.collection('groups').doc(groupId).update({
            'memberIds': memberIds,
            'memberNames': memberNames,
          });

          // Add system message about new member
          GroupMessage systemMessage = GroupMessage(
            id: '',
            senderId: 'system',
            senderName: 'System',
            content: '$memberName was added to the group by $addedByName',
            sentAt: DateTime.now(),
            messageType: GroupMessageType.system,
          );

          await addGroupMessage(groupId: groupId, message: systemMessage);
        }
      }
    } catch (e) {
      throw Exception("Could not add member to group: $e");
    }
  }

  Future<void> updateGroupName(String groupId, String newName) async {
    try {
      await _firebaseFirestore.collection('groups').doc(groupId).update({
        'groupName': newName,
      });
    } catch (e) {
      throw Exception("Could not update group name: $e");
    }
  }

  Future<void> updateGroupImage(String groupId, String imageUrl) async {
    try {
      await _firebaseFirestore.collection('groups').doc(groupId).update({
        'groupImageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception("Could not update group image: $e");
    }
  }

  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      await _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception("Could not delete message: $e");
    }
  }

  Future<List<GroupMessage>> getMessagesForPagination({
    required String groupId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => GroupMessage.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception("Could not load messages: $e");
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
}
