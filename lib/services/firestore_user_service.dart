import 'dart:async' show unawaited;
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../resource_module/constants/appConstants.dart';
import '../resource_module/model/chat_models.dart';

class FirestoreUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Writes the chat user doc when a **new** account is created (signup).
  /// [registeredFromApp] is applied via [set] plus an explicit [update] so it is
  /// not lost to merge/replace races (e.g. backend writing the same doc).
  static Future<void> createOrUpdateUser({
    required String userId,
    required String phoneNumber,
    required String userName,
    String registeredFromApp = AppConstants.firebaseRegistrationAppId,
  }) async {
    try {
      log(
        'createOrUpdateUser start userId=$userId phone=$phoneNumber '
        'registeredFromApp=$registeredFromApp',
        name: 'FirestoreUser',
      );
      // Get FCM token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');

      final now = DateTime.now();
      final ts = Timestamp.fromDate(now);

      // Build payload explicitly so `registeredFromApp` is never dropped by map/toMap paths.
      final data = <String, dynamic>{
        'userId': userId,
        'phoneNumber': phoneNumber,
        'userName': userName,
        'createdAt': ts,
        'isOnline': true,
        'lastSeen': ts,
        'registeredFromApp': registeredFromApp,
      };
      if (fcmToken != null && fcmToken.isNotEmpty) {
        data['fcmToken'] = fcmToken;
      }

      final docRef =
          _firestore.collection(_usersCollection).doc(userId);

      await docRef.set(data, SetOptions(merge: true));
      await docRef.update({'registeredFromApp': registeredFromApp});

      unawaited(
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            await docRef.update({'registeredFromApp': registeredFromApp});
          } catch (e) {
            log(
              'registeredFromApp delayed patch failed userId=$userId: $e',
              name: 'FirestoreUser',
            );
          }
        }),
      );

      log(
        'createOrUpdateUser done users/$userId keys=${data.keys.toList()} '
        'registeredFromApp=$registeredFromApp',
        name: 'FirestoreUser',
      );
    } catch (e) {
      log(
        'createOrUpdateUser failed userId=$userId error=$e',
        name: 'FirestoreUser',
      );
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

  /// Search by phone; only matches users with [registeredFromApp] equal to this app
  /// (new signups include that field). Docs without it are ignored.
  static Future<ChatUser?> searchUserByPhone(
    String phoneNumber, {
    String registeredFromApp = AppConstants.firebaseRegistrationAppId,
  }) async {
    try {
      log(
        'searchUserByPhone query phone=$phoneNumber '
        'requiredRegisteredFromApp=$registeredFromApp',
        name: 'ChatSearch',
      );
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      log(
        'searchUserByPhone Firestore returned ${querySnapshot.docs.length} doc(s)',
        name: 'ChatSearch',
      );
      for (final doc in querySnapshot.docs) {
        final user = ChatUser.fromMap(doc.data());
        log(
          'searchUserByPhone doc id=${doc.id} userId=${user.userId} '
          'registeredFromApp=${user.registeredFromApp ?? "(null)"}',
          name: 'ChatSearch',
        );
        if (user.registeredFromApp == registeredFromApp) {
          log(
            'searchUserByPhone MATCH userId=${user.userId}',
            name: 'ChatSearch',
          );
          return user;
        }
      }
      log(
        'searchUserByPhone no doc matches registeredFromApp=$registeredFromApp',
        name: 'ChatSearch',
      );
      return null;
    } catch (e) {
      log('searchUserByPhone error: $e', name: 'ChatSearch');
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
