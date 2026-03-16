import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../resource_module/model/chat_models.dart';

class FirestoreUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Create or update user in Firestore after successful signup
  static Future<void> createOrUpdateUser({
    required String userId,
    required String phoneNumber,
    required String userName,
  }) async {
    try {
      // Get FCM token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');

      final user = ChatUser(
        userId: userId,
        phoneNumber: phoneNumber,
        userName: userName,
        fcmToken: fcmToken,
        createdAt: DateTime.now(),
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(user.toMap(), SetOptions(merge: true));

      print('✅ User created/updated in Firestore: $userId');
    } catch (e) {
      print('❌ Error creating/updating user in Firestore: $e');
      rethrow;
    }
  }

  // Update user's FCM token
  static Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'fcmToken': fcmToken,
        'lastSeen': Timestamp.now(),
      });
      print('✅ FCM token updated for user: $userId');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      rethrow;
    }
  }

  // Update user's online status
  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  // Search user by phone number
  static Future<ChatUser?> searchUserByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return ChatUser.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('❌ Error searching user by phone: $e');
      return null;
    }
  }

  // Get user by ID
  static Future<ChatUser?> getUserById(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        return ChatUser.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // Get current user from SharedPreferences
  static Future<ChatUser?> getCurrentUser() async {
    try {
      final userId = await getUserId();
      if (userId != null) {
        return await getUserById(userId);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Get user ID from SharedPreferences
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id'); // Get as int
      return userId?.toString(); // Convert to string
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }

  // Stream user data for real-time updates
  static Stream<ChatUser?> streamUser(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ChatUser.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Get multiple users by IDs
  static Future<List<ChatUser>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting users by IDs: $e');
      return [];
    }
  }

  // Delete user (for cleanup purposes)
  static Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();
      print('✅ User deleted from Firestore: $userId');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // Check if user exists
  static Future<bool> userExists(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      print('❌ Error checking if user exists: $e');
      return false;
    }
  }

  // Get all users (for admin purposes - use with caution)
  static Stream<List<ChatUser>> streamAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatUser.fromMap(doc.data()))
        .toList());
  }

  // Get all users as a Future (for one-time fetching)
  static Future<List<ChatUser>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }
}
