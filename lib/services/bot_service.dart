import 'package:cloud_firestore/cloud_firestore.dart';

class BotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save individual chat message
  Future<void> saveBotChatMessage({
    required String userId,
    required Map<String, dynamic> message,
  }) async {
    try {
      await _firestore
          .collection('aibotchats') // Changed to generic name
          .doc('botchat')
          .collection(userId)
          .doc('messages')
          .set(message, SetOptions(merge: true));
      print('Message saved successfully');
    } catch (e) {
      print('Error saving message: $e');
      rethrow;
    }
  }

  /// Save messages in a subcollection (better for querying)
  Future<String> saveBotChatMessageToSubcollection({
    required String userId,
    required Map<String, dynamic> messageData,
  }) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('aibotchats')
          .doc('botchat')
          .collection(userId)
          .add({
        ...messageData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Message saved to subcollection successfully');
      return docRef.id;
    } catch (e) {
      print('Error saving message to subcollection: $e');
      rethrow;
    }
  }

  /// Fetch all bot chat messages for a user
  Future<List<Map<String, dynamic>>> getBotChatMessages({
    required String userId,
    String? model, // Filter by AI model
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('aibotchats')
          .doc('botchat')
          .collection(userId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();

      List<Map<String, dynamic>> messages = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      // Filter by model if specified
      if (model != null) {
        messages = messages.where((msg) => msg['model'] == model).toList();
      }

      return messages;
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Get messages from the array structure
  Future<List<dynamic>> getBotChatMessagesFromArray({
    required String userId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('aibotchats')
          .doc('botchat')
          .collection(userId)
          .doc('messages')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['messages'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching messages from array: $e');
      return [];
    }
  }

  /// Delete all bot chat messages for a user
  Future<void> deleteBotChatMessages({
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('aibotchats')
          .doc('botchat')
          .collection(userId)
          .doc('messages')
          .delete();

      print('Messages deleted successfully');
    } catch (e) {
      print('Error deleting messages: $e');
      rethrow;
    }
  }

  /// Delete a specific message by document ID
  Future<void> deleteSpecificMessage({
    required String userId,
    required String docId,
  }) async {
    try {
      await _firestore
          .collection('aibotchats')
          .doc('botchat')
          .collection(userId)
          .doc(docId)
          .delete();

      print('Specific message deleted successfully');
    } catch (e) {
      print('Error deleting specific message: $e');
      rethrow;
    }
  }

  /// Delete all messages in subcollection
  Future<void> deleteAllBotChatMessages({
    required String userId,
    String? model, // Optional: delete only messages from specific model
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('aibotchats')
          .doc('botchat')
          .collection(userId)
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // If model is specified, only delete messages from that model
        if (model == null || data['model'] == model) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      print('All messages deleted successfully');
    } catch (e) {
      print('Error deleting all messages: $e');
      rethrow;
    }
  }
}
