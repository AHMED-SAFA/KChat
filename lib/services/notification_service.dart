import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<String> storeNotificationForMessage({
    required String chatId,
    required String loggedInUserId,
    required String loggedInUserName,
    required String receiverId,
  }) async {
    try {
      // Create a new document reference
      DocumentReference notificationDoc = _firebaseFirestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc();

      // Store the notification data
      await notificationDoc.set({
        'chatId': chatId,
        'senderName': loggedInUserName,
        'senderId': loggedInUserId,
        'isRead': false, // Add this line
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Return the document ID for future reference
      return notificationDoc.id;
    } catch (e) {
      throw Exception("Could not store notification: $e");
    }
  }

  Future<List<Map<String, dynamic>>> retrieveNotifications({
    required String receiverId,
  }) async {
    try {
      QuerySnapshot notificationsSnapshot = await _firebaseFirestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      // Map the data to a list of notifications
      List<Map<String, dynamic>> notifications =
          notificationsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'senderName': doc['senderName'] + '\n' + "sent you a message!\n",
          'timestamp': (doc['timestamp'] as Timestamp).toDate(),
        };
      }).toList();

      return notifications;
    } catch (e) {
      throw Exception("Could not retrieve notifications: $e");
    }
  }

  //delete respective notification
  Future<void> deleteNotification({
    required String receiverId,
    required String notificationId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception("Could not delete notification: $e");
    }
  }

  // Add this method to get unread notification count
  Future<int> getUnreadNotificationCount({required String receiverId}) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Add this method to mark notifications as read
  Future<void> markNotificationsAsRead({required String receiverId}) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firebaseFirestore.batch();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Stream for real-time unread count
  Stream<int> getUnreadCountStream({required String receiverId}) {
    return _firebaseFirestore
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
