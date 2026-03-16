import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crapadvisor/resource_module/views/authViews/LoginView.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_chat_service.dart';
import '../../services/firestore_user_service.dart';
import '../constants/appConstants.dart';

import '../utilities/dialogBoxes.dart';
import '../utilities/sharedPrefs.dart';

Future<bool> deleteAccount(BuildContext context) async {
  final url = Uri.parse("${AppConstants.baseUrl}/delete_user");
  final int? userIdInt = await getUserId();
  final String? userId = userIdInt?.toString();

  final bearerToken = await getToken();
  print("bearerToken $bearerToken");

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    print("response.statusCode ${response.statusCode}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      // --- Firebase Cleanup ---
      if (userId != null) {
        await _cleanupUserChatData(userId);
        print('✅ Firebase chat data cleaned up successfully');

        await _cleanupUserPosts(userId);
        print('✅ User posts cleaned up successfully');
      }

      // --- Firebase Auth ---
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
        print('✅ Firebase Auth user deleted successfully');
      } else {
        print('ℹ️ No Firebase Auth user found to delete');
      }

      await FirebaseAuth.instance.signOut();
      print('✅ Firebase Auth sign out completed');

      // --- Success Dialog ---
      showSuccessDialog(
        context,
        "Your account has been deleted successfully!",
        null,
        LoginView(),
      );

      // --- Clear Local Data ---
      await saveToken("");
      await saveUserName("");
      await saveUserEmail("");
      await saveUserId(0);
      await setIsLogedIn(false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('verification_id');
      await prefs.remove('resend_token');
      await prefs.remove('phone_verified');
      await prefs.remove('signup_email');
      await prefs.remove('signup_phone');
      await prefs.remove('fcm_token');
      await prefs.remove('firebase_auth_token');
      await prefs.remove('firebase_user_id');
      await prefs.remove('firebase_phone_number');
      await prefs.remove('firebase_auth_state');
      await prefs.remove('firebase_auth_persistence');
      await prefs.remove('auth_state');
      await prefs.remove('user_session');
      await prefs.remove('login_state');

      return true;
    } else {
      // --- Server returned error ---
      print('🔍 Debug: Server deletion failed, parsing error response...');
      final data = json.decode(response.body);
      print('🔍 Debug: Error data: $data');
      showErrorDialog(
        context,
        data['message'] ?? "An error occurred while deleting your account.",
        data['errors'] ?? [],
      );
      return false;
    }
  } on TimeoutException {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      showErrorDialog(context, "No internet connection.", []);
    } else {
      final isInternetSlow = !(await _hasGoodConnection());
      if (isInternetSlow) {
        showErrorDialog(
            context, "Slow internet connection detected. Try again?", []);
      } else {
        showErrorDialog(context, "Server is taking too long to respond.", []);
      }
    }
    return false;
  } on SocketException {
    showErrorDialog(
      context,
      "No internet connection. Please check your connection and try again.",
      [],
    );
    return false;
  } on ClientException catch (e) {
    final errorString = e.toString();
    if (errorString.contains('SocketException')) {
      showErrorDialog(
        context,
        "Network error: failed to reach server. Please check your connection.",
        [],
      );
    } else {
      showErrorDialog(
        context,
        "A client error occurred: ${e.message}",
        [],
      );
    }
    return false;
  } catch (error) {
    print('🔍 Debug: Unexpected error occurred: $error');
    showErrorDialog(
      context,
      "Operation failed while deleting account: $error",
      [],
    );
    return false;
  }
}

Future<bool> _hasGoodConnection() async {
  try {
    final response = await http
        .get(
          Uri.parse('https://www.google.com'),
        )
        .timeout(Duration(seconds: 2));
    return true;
  } catch (_) {
    return false;
  }
}

// Clean up user's chat data when account is deleted
Future<void> _cleanupUserChatData(String userId) async {
  try {
    print('🧹 Starting chat data cleanup for user: $userId');

    // 1. Get all chats where user is a participant
    final chatsQuery = await FirestoreChatService.firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    print('📋 Found ${chatsQuery.docs.length} chats to process');

    for (final chatDoc in chatsQuery.docs) {
      final chatData = chatDoc.data();
      final participants = List<String>.from(chatData['participants'] ?? []);

      // 2. Handle different chat scenarios
      if (participants.length == 1 && participants.first == userId) {
        // Self-message chat - delete completely
        await FirestoreChatService.deleteChatCompletely(chatDoc.id);
        print('🗑️ Deleted self-message chat: ${chatDoc.id}');
      } else if (participants.length == 2) {
        // Direct chat with another user
        final otherUserId = participants.where((id) => id != userId).first;

        // Mark all user's messages as deleted for everyone
        await _deleteUserMessagesFromChat(chatDoc.id, userId);

        // Mark chat as deleted for this user
        await _markChatDeletedForUser(chatDoc.id, userId);

        // Update chat's last message if needed
        await FirestoreChatService.updateChatLastMessage(chatDoc.id, userId);

        print('✅ Processed direct chat: ${chatDoc.id} with user: $otherUserId');
      } else {
        // Group chat (if implemented in future)
        // Mark all user's messages as deleted for everyone
        await _deleteUserMessagesFromChat(chatDoc.id, userId);

        // Remove user from participants and unreadCounts
        await _removeUserFromGroupChat(chatDoc.id, userId);

        print('✅ Processed group chat: ${chatDoc.id}');
      }
    }

    // 3. Delete user document from Firestore
    await FirestoreUserService.deleteUser(userId);
    print('🗑️ Deleted user document: $userId');

    print('✅ Chat data cleanup completed for user: $userId');
  } catch (e) {
    print('❌ Error during chat data cleanup: $e');
    rethrow;
  }
}

// Delete all messages sent by the user from a specific chat
Future<void> _deleteUserMessagesFromChat(String chatId, String userId) async {
  try {
    final messagesQuery = await FirestoreChatService.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .get();

    final batch = FirestoreChatService.firestore.batch();

    for (final doc in messagesQuery.docs) {
      // Hard delete all messages sent by the user
      batch.delete(doc.reference);
    }

    await batch.commit();
    print(
        '🗑️ Deleted ${messagesQuery.docs.length} messages from user: $userId in chat: $chatId');
  } catch (e) {
    print('❌ Error deleting user messages: $e');
    rethrow;
  }
}

// Mark chat as deleted for the user
Future<void> _markChatDeletedForUser(String chatId, String userId) async {
  try {
    await FirestoreChatService.firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'deletedFor': FieldValue.arrayUnion([userId]),
    });
    print('✅ Marked chat as deleted for user: $userId');
  } catch (e) {
    print('❌ Error marking chat as deleted: $e');
    rethrow;
  }
}

// Remove user from group chat participants and unreadCounts
Future<void> _removeUserFromGroupChat(String chatId, String userId) async {
  try {
    // Get current chat data to check if it's a group chat
    final chatDoc = await FirestoreChatService.firestore
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      print('⚠️ Chat document not found: $chatId');
      return;
    }

    final chatData = chatDoc.data()!;
    final chatType = chatData['chatType'] ?? 'direct';
    final currentParticipants =
        List<String>.from(chatData['participants'] ?? []);
    final currentUnreadCounts =
        Map<String, int>.from(chatData['unreadCounts'] ?? {});
    final admins = List<String>.from(chatData['admins'] ?? []);

    if (chatType == 'group') {
      // Remove user from participants, unread counts, and admins
      final updatedParticipants =
          currentParticipants.where((id) => id != userId).toList();
      final updatedUnreadCounts = Map<String, int>.from(currentUnreadCounts);
      final updatedAdmins = admins.where((id) => id != userId).toList();

      updatedUnreadCounts.remove(userId);

      // Check if group would be empty after user removal
      if (updatedParticipants.isEmpty) {
        // Delete the entire group chat if it would be empty
        await FirestoreChatService.deleteGroupChat(chatId, userId);
        print('🗑️ Deleted empty group chat: $chatId');
      } else {
        // Update chat document with removed user
        await FirestoreChatService.firestore
            .collection('chats')
            .doc(chatId)
            .update({
          'participants': updatedParticipants,
          'unreadCounts': updatedUnreadCounts,
          'admins': updatedAdmins,
        });
        print('✅ Removed user from group chat: $userId');
      }
    } else {
      // For direct chats, use the original logic
      await FirestoreChatService.firestore
          .collection('chats')
          .doc(chatId)
          .update({
        'participants': FieldValue.arrayRemove([userId]),
        'unreadCounts.$userId': FieldValue.delete(),
      });
      print('✅ Removed user from direct chat: $userId');
    }
  } catch (e) {
    print('❌ Error removing user from group chat: $e');
    rethrow;
  }
}

// Clean up user's posts when account is deleted
Future<void> _cleanupUserPosts(String userId) async {
  try {
    print('🧹 Starting posts cleanup for user: $userId');

    // Get all posts created by the user
    final postsQuery = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .get();

    print('📋 Found ${postsQuery.docs.length} posts to delete');

    if (postsQuery.docs.isNotEmpty) {
      // Use batch delete for better performance
      final batch = FirebaseFirestore.instance.batch();

      for (final postDoc in postsQuery.docs) {
        // Delete the post document
        batch.delete(postDoc.reference);

        // Also delete all comments for this post
        final commentsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .get();

        for (final commentDoc in commentsQuery.docs) {
          batch.delete(commentDoc.reference);
        }

        print(
            '🗑️ Queued post and ${commentsQuery.docs.length} comments for deletion: ${postDoc.id}');
      }

      // Commit all deletions
      await batch.commit();
      print(
          '✅ Successfully deleted ${postsQuery.docs.length} posts and their comments');
    } else {
      print('ℹ️ No posts found for user: $userId');
    }

    print('✅ Posts cleanup completed for user: $userId');
  } catch (e) {
    print('❌ Error during posts cleanup: $e');
    rethrow;
  }
}
