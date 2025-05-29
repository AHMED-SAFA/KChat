import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveUserService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Update user active status (true for online, false for offline)
  Future<void> setUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).update({
        'ActiveStatus': isActive,
      });
    } catch (e) {
      print('Failed to update user active status: $e');
    }
  }

  // Update user active status to true (online)
  Future<void> setActive(String userId) async {
    await setUserActiveStatus(userId, true);
  }

  // Update user active status to false (offline)
  Future<void> setInactive(String userId) async {
    await setUserActiveStatus(userId, false);
  }

  // Stream that listens to the active status of all users
  Stream<Map<String, bool>> getActiveUsersStream() {
    return _firebaseFirestore.collection('users').snapshots().map((snapshot) {
      Map<String, bool> activeUsers = {};
      for (var doc in snapshot.docs) {
        activeUsers[doc.id] = doc['ActiveStatus'] ?? false;
      }
      return activeUsers;
    });
  }

  Future<bool> getActiveUsersStatus({required String userID}) async {
    try {
      // Get the document of the user
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(userID).get();

      // Check
      if (userDoc.exists && userDoc.data() != null) {
        bool activeStat = userDoc['ActiveStatus'] ?? false;
        return activeStat;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
