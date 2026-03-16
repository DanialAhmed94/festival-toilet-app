import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../resource_module/model/chat_models.dart';
import 'firestore_user_service.dart';

class FirestoreChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';

  // Getter for firestore instance (for cleanup operations)
  static FirebaseFirestore get firestore => _firestore;

  // Helper method to safely convert unread counts from Firestore
  static Map<String, int> _parseUnreadCounts(dynamic unreadCountsData) {
    final result = <String, int>{};
    if (unreadCountsData != null && unreadCountsData is Map) {
      for (final entry in unreadCountsData.entries) {
        final key = entry.key.toString();
        final value = entry.value is int ? entry.value as int : 0;
        result[key] = value;
      }
    }
    return result;
  }

  // Create or get existing chat between two users
  static Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      // Validate input parameters
      if (userId1.isEmpty || userId2.isEmpty) {
        throw Exception('User IDs cannot be empty');
      }

      if (userId1 == userId2) {
        throw Exception('Cannot create chat with same user');
      }

      // Sort user IDs to ensure consistent chat ID
      final sortedUsers = [userId1, userId2]..sort();
      final chatId = '${sortedUsers[0]}_${sortedUsers[1]}';

      // Check if chat already exists
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat
        final chat = Chat(
          chatId: chatId,
          participants: sortedUsers,
          chatType: 'direct',
          unreadCounts: {userId1: 0, userId2: 0},
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .set(chat.toMap());

        print('✅ New chat created: $chatId');
      } else {
        print('✅ Existing chat found: $chatId');
      }

      return chatId;
    } catch (e) {
      print('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  // Create a new group chat
  static Future<String> createGroupChat({
    required String groupName,
    required String creatorId,
    required List<String> participantIds,
    String? groupDescription,
    String? groupAvatarUrl,
  }) async {
    try {
      // Validate input parameters
      if (groupName.isEmpty) {
        throw Exception('Group name cannot be empty');
      }

      if (participantIds.isEmpty) {
        throw Exception('Group must have at least one participant');
      }

      if (!participantIds.contains(creatorId)) {
        throw Exception('Creator must be a participant');
      }

      // Generate unique group chat ID
      final chatId =
          'group_${DateTime.now().millisecondsSinceEpoch}_${creatorId}';

      // Initialize unread counts for all participants
      final Map<String, int> unreadCounts = {};
      for (final participantId in participantIds) {
        unreadCounts[participantId] = 0;
      }

      // Create group chat
      final chat = Chat(
        chatId: chatId,
        participants: participantIds,
        chatType: 'group',
        unreadCounts: unreadCounts,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_chatsCollection).doc(chatId).set({
        ...chat.toMap(),
        'groupName': groupName,
        'groupDescription': groupDescription,
        'groupAvatarUrl': groupAvatarUrl,
        'creatorId': creatorId,
        'admins': [creatorId], // Creator is the first admin
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      print(
          '✅ New group chat created: $chatId with ${participantIds.length} participants');
      return chatId;
    } catch (e) {
      print('❌ Error creating group chat: $e');
      rethrow;
    }
  }

  // Add participants to group chat
  static Future<void> addParticipantsToGroup(
      String chatId, List<String> newParticipantIds) async {
    try {
      // Validate input parameters
      if (newParticipantIds.isEmpty) {
        throw Exception('No participants to add');
      }

      // Get current chat data
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final currentParticipants =
          List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCounts = _parseUnreadCounts(chatData['unreadCounts']);

      // Add new participants
      final updatedParticipants = [...currentParticipants];
      final updatedUnreadCounts = Map<String, int>.from(currentUnreadCounts);

      for (final participantId in newParticipantIds) {
        if (!updatedParticipants.contains(participantId)) {
          updatedParticipants.add(participantId);
          updatedUnreadCounts[participantId] = 0;
        }
      }

      // Update chat document
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': updatedParticipants,
        'unreadCounts': updatedUnreadCounts,
      });

      print(
          '✅ Added ${newParticipantIds.length} participants to group: $chatId');
    } catch (e) {
      print('❌ Error adding participants to group: $e');
      rethrow;
    }
  }

  // Remove participants from group chat
  static Future<void> removeParticipantsFromGroup(
      String chatId, List<String> participantIdsToRemove) async {
    try {
      // Validate input parameters
      if (participantIdsToRemove.isEmpty) {
        throw Exception('No participants to remove');
      }

      // Get current chat data
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final currentParticipants =
          List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCounts = Map<String, int>.from(
        (chatData['unreadCounts'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key.toString(), (value as int?) ?? 0),
            ) ??
            {},
      );
      final admins = List<String>.from(chatData['admins'] ?? []);

      // Remove participants
      final updatedParticipants = currentParticipants
          .where((id) => !participantIdsToRemove.contains(id))
          .toList();
      final updatedUnreadCounts = Map<String, int>.from(currentUnreadCounts);
      final updatedAdmins =
          admins.where((id) => !participantIdsToRemove.contains(id)).toList();

      // Remove from unread counts
      for (final participantId in participantIdsToRemove) {
        updatedUnreadCounts.remove(participantId);
      }

      // Check if group would be empty
      if (updatedParticipants.isEmpty) {
        throw Exception('Cannot remove all participants from group');
      }

      // Update chat document
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': updatedParticipants,
        'unreadCounts': updatedUnreadCounts,
        'admins': updatedAdmins,
      });

      print(
          '✅ Removed ${participantIdsToRemove.length} participants from group: $chatId');
    } catch (e) {
      print('❌ Error removing participants from group: $e');
      rethrow;
    }
  }

  // Leave group chat
  static Future<void> leaveGroupChat(String chatId, String userId) async {
    try {
      // Get current chat data
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final currentParticipants =
          List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCounts = Map<String, int>.from(
        (chatData['unreadCounts'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key.toString(), (value as int?) ?? 0),
            ) ??
            {},
      );
      final admins = List<String>.from(chatData['admins'] ?? []);

      // Check if user is a participant
      if (!currentParticipants.contains(userId)) {
        throw Exception('User is not a participant in this group');
      }

      // Remove user from participants, unread counts, and admins
      final updatedParticipants =
          currentParticipants.where((id) => id != userId).toList();
      final updatedUnreadCounts = Map<String, int>.from(currentUnreadCounts);
      final updatedAdmins = admins.where((id) => id != userId).toList();

      updatedUnreadCounts.remove(userId);

      // Check if group would be empty
      if (updatedParticipants.isEmpty) {
        throw Exception('Cannot leave group as the last participant');
      }

      // Update chat document
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': updatedParticipants,
        'unreadCounts': updatedUnreadCounts,
        'admins': updatedAdmins,
      });

      print('✅ User $userId left group: $chatId');
    } catch (e) {
      print('❌ Error leaving group chat: $e');
      rethrow;
    }
  }

  // Delete group chat (admin only)
  static Future<void> deleteGroupChat(String chatId, String adminId) async {
    try {
      // Get current chat data
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final admins = List<String>.from(chatData['admins'] ?? []);

      // Check if user is an admin
      if (!admins.contains(adminId)) {
        throw Exception('Only admins can delete group chat');
      }

      // Delete all messages in the group
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .get();

      final batch = _firestore.batch();

      // Delete all messages
      for (final messageDoc in messagesQuery.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the chat document
      batch.delete(chatDoc.reference);

      await batch.commit();

      print('✅ Group chat deleted: $chatId');
    } catch (e) {
      print('❌ Error deleting group chat: $e');
      rethrow;
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    try {
      // Validate input parameters
      if (chatId.isEmpty || senderId.isEmpty || message.isEmpty) {
        throw Exception('Chat ID, sender ID, and message cannot be empty');
      }

      if (message.length > 1000) {
        throw Exception('Message too long (max 1000 characters)');
      }

      // Validate message type
      if (!['text', 'image', 'video', 'audio', 'file'].contains(messageType)) {
        throw Exception('Invalid message type');
      }

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now();

      final chatMessage = ChatMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        message: message,
        messageType: messageType,
        mediaUrl: mediaUrl,
        timestamp: timestamp,
        readBy: [senderId], // Sender has read the message
      );

      // Add message to subcollection
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update chat document with last message info
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSender': senderId,
        // Increment unread count for other participants
        'unreadCounts.$senderId':
            FieldValue.increment(0), // Reset sender's count
      });

      // Increment unread count for other participants
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);

        for (final participantId in participants) {
          if (participantId != senderId) {
            await _firestore.collection(_chatsCollection).doc(chatId).update({
              'unreadCounts.$participantId': FieldValue.increment(1),
            });
          }
        }
      }

      print('✅ Message sent: $messageId');

      // Cloud Function will automatically trigger notification
      // when a new message is added to the subcollection
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Simple stream messages for a chat
  static Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      // Get current user ID to filter deleted messages
      final currentUserId = await FirestoreUserService.getUserId();

      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
          .where((message) {
        // Filter out hard deleted messages
        if (message.isDeleted) return false;

        // Filter out messages soft deleted for current user
        if (currentUserId != null && message.isDeletedForUser(currentUserId)) {
          return false;
        }

        return true;
      }).toList();

      return messages;
    });
  }

  // Simple delete message method
  static Future<void> deleteMessage(String chatId, String messageId,
      {bool deleteForEveryone = false}) async {
    try {
      if (deleteForEveryone) {
        await deleteMessageForEveryone(chatId, messageId);
      } else {
        await deleteMessageForMe(chatId, messageId);
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // Simple soft delete
  static Future<void> deleteMessageForMe(
      String chatId, String messageId) async {
    try {
      final currentUserId = await FirestoreUserService.getUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get the message first
      final messageDoc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data()!;
      final deletedFor = List<String>.from(messageData['deletedFor'] ?? []);

      if (!deletedFor.contains(currentUserId)) {
        deletedFor.add(currentUserId);

        await _firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .collection(_messagesCollection)
            .doc(messageId)
            .update({
          'deletedFor': deletedFor,
        });
      }

      print('✅ Message soft deleted for user: $currentUserId');

      // Update chat's last message if this was the last message
      await updateChatLastMessage(chatId, currentUserId);
    } catch (e) {
      print('❌ Error soft deleting message: $e');
      rethrow;
    }
  }

  // Simple hard delete
  static Future<void> deleteMessageForEveryone(
      String chatId, String messageId) async {
    try {
      final currentUserId = await FirestoreUserService.getUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get the message to verify sender
      final messageDoc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data()!;
      final message = ChatMessage.fromMap(messageData);

      // Only sender can delete for everyone
      if (message.senderId != currentUserId) {
        throw Exception('Only message sender can delete for everyone');
      }

      // Delete the message
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .delete();

      print('✅ Message deleted for everyone: $messageId');

      // Update chat's last message after deletion
      await updateChatLastMessage(chatId, currentUserId);
    } catch (e) {
      print('❌ Error deleting message for everyone: $e');
      rethrow;
    }
  }

  // Update chat's last message field
  static Future<void> updateChatLastMessage(
      String chatId, String currentUserId) async {
    try {
      // Get all messages in the chat (not filtered by user)
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .get();

      final allMessages = messagesQuery.docs
          .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
          .where((message) {
        // Only filter out hard deleted messages
        if (message.isDeleted) return false;
        return true;
      }).toList();

      // Update chat with new last message info (based on all visible messages)
      if (allMessages.isNotEmpty) {
        final lastMessage = allMessages.first;
        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'lastMessage': lastMessage.message,
          'lastMessageTime': Timestamp.fromDate(lastMessage.timestamp),
          'lastMessageSender': lastMessage.senderId,
        });
        print('✅ Updated chat last message: ${lastMessage.message}');
      } else {
        // No messages left - clear last message info
        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'lastMessage': '',
          'lastMessageTime': null,
          'lastMessageSender': '',
        });
        print('✅ Cleared chat last message - no messages remaining');
      }
    } catch (e) {
      print('❌ Error updating chat last message: $e');
    }
  }

  // Stream chat list for a user (filtered by deletion status)
  static Stream<List<ChatListItem>> streamUserChats(String userId) {
    print('🔍 Searching for chats with userId: $userId');

    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .where('isDeleted', isEqualTo: false) // Filter out hard deleted chats
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      print('📋 Found ${snapshot.docs.length} chat documents');
      final chatItems = <ChatListItem>[];

      for (final doc in snapshot.docs) {
        try {
          print('🔍 Processing chat document: ${doc.id}');
          final chatData = doc.data();
          print('📄 Chat data: $chatData');

          final participants =
              List<String>.from(chatData['participants'] ?? []);
          final deletedFor = List<String>.from(chatData['deletedFor'] ?? []);
          print('👥 Participants: $participants');
          print('🗑️ Deleted for: $deletedFor');

          // Skip if user has deleted this chat
          if (deletedFor.contains(userId)) {
            print('⚠️ Chat ${doc.id} deleted for user $userId, skipping');
            continue;
          }

          // Check chat type
          final chatType = chatData['chatType'] ?? 'direct';

          String otherUserId;
          if (chatType == 'group') {
            // Group chat - use group ID as other user ID
            otherUserId = 'group_${doc.id}';
            print('👥 Group chat detected: ${doc.id}');
          } else {
            // Handle direct chat cases
            if (participants.length == 1 && participants.first == userId) {
              // Self-message chat (single participant)
              otherUserId = userId;
              print('💬 Self-message chat detected (single participant)');
            } else if (participants.length == 2 &&
                participants.every((id) => id == userId)) {
              // Self-message chat (duplicate participants)
              otherUserId = userId;
              print('💬 Self-message chat detected (duplicate participants)');
            } else {
              // Get the other user's ID (skip current user)
              final otherUsers =
                  participants.where((id) => id != userId).toList();
              if (otherUsers.isEmpty) {
                print('⚠️ No other users found in chat ${doc.id}');
                continue; // Skip this chat
              }
              otherUserId = otherUsers.first;
              print('👤 Other user ID: $otherUserId');
            }
          }

          // Get user/group data
          print('🔍 Fetching data for: $otherUserId');
          final unreadCounts = <String, int>{};
          if (chatData['unreadCounts'] != null) {
            final unreadData =
                chatData['unreadCounts'] as Map<dynamic, dynamic>;
            for (final entry in unreadData.entries) {
              unreadCounts[entry.key.toString()] = (entry.value as int?) ?? 0;
            }
          }
          final unreadCount = unreadCounts[userId] ?? 0;

          // Get the actual last message visible to this user
          String lastMessage = '';
          DateTime? lastMessageTime;
          String lastMessageSender = '';

          // Check if the chat's last message is visible to this user
          final chatLastMessageId = chatData['lastMessageSender'] != null &&
                  chatData['lastMessageSender'].isNotEmpty
              ? await _getLastMessageIdForUser(doc.id, userId)
              : null;

          if (chatLastMessageId != null) {
            // Use the chat's last message info
            lastMessage = chatData['lastMessage'] ?? '';
            lastMessageTime = chatData['lastMessageTime'] != null
                ? (chatData['lastMessageTime'] as Timestamp).toDate()
                : null;
            lastMessageSender = chatData['lastMessageSender'] ?? '';
          } else {
            // Chat's last message is not visible to this user, find the actual last visible message
            final lastVisibleMessage =
                await _getLastVisibleMessageForUser(doc.id, userId);
            if (lastVisibleMessage != null) {
              lastMessage = lastVisibleMessage.message;
              lastMessageTime = lastVisibleMessage.timestamp;
              lastMessageSender = lastVisibleMessage.senderId;
            }
            // If no visible message found, lastMessageTime remains null
          }

          String displayName;
          bool isOnline = false;

          if (chatType == 'group') {
            // Group chat
            final groupName = chatData['groupName'] ?? 'Group Chat';
            final participantCount = participants.length;
            displayName = '$groupName ($participantCount members)';
            isOnline = false; // Groups don't have online status
            print('✅ Group found: $displayName');
          } else {
            // Direct chat
            final otherUser =
                await FirestoreUserService.getUserById(otherUserId);
            if (otherUser != null) {
              displayName = otherUser.userName;
              isOnline = otherUser.isOnline;
              print('✅ User found: $displayName');
            } else {
              print('⚠️ User not found: $otherUserId for chat ${doc.id}');
              continue; // Skip this chat
            }
          }

          final chatItem = ChatListItem(
            chatId: doc.id,
            otherUserId: otherUserId,
            otherUserName: displayName,
            otherUserAvatarColor: _getAvatarColor(otherUserId),
            otherUserAvatarIcon: _getAvatarIcon(otherUserId),
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            lastMessageSender: lastMessageSender,
            unreadCount: unreadCount,
            isOnline: isOnline,
            isBlock: chatData['isBlock'] ?? 0,
          );

          chatItems.add(chatItem);
          print('✅ Chat item added: $displayName');
        } catch (e) {
          print('❌ Error processing chat ${doc.id}: $e');
          continue; // Skip this chat and continue with others
        }
      }

      print('📊 Returning ${chatItems.length} chat items');
      return chatItems;
    });
  }

  // Helper method to get the last message ID for a user
  static Future<String?> _getLastMessageIdForUser(
      String chatId, String userId) async {
    try {
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        final lastMessage = ChatMessage.fromMap(
            messagesQuery.docs.first.data() as Map<String, dynamic>);
        // Check if this message is visible to the user
        if (!lastMessage.isDeleted && !lastMessage.isDeletedForUser(userId)) {
          return messagesQuery.docs.first.id;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting last message ID for user: $e');
      return null;
    }
  }

  // Helper method to get the last visible message for a user
  static Future<ChatMessage?> _getLastVisibleMessageForUser(
      String chatId, String userId) async {
    try {
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .get();

      for (final doc in messagesQuery.docs) {
        final message = ChatMessage.fromMap(doc.data() as Map<String, dynamic>);
        // Check if this message is visible to the user
        if (!message.isDeleted && !message.isDeletedForUser(userId)) {
          return message;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting last visible message for user: $e');
      return null;
    }
  }

  // Delete chat for current user (soft delete)
  static Future<void> deleteChatForMe(String chatId) async {
    try {
      final currentUserId = await FirestoreUserService.getUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get the chat to check if it exists
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final deletedFor = List<String>.from(chatData['deletedFor'] ?? []);

      // Add current user to deletedFor array
      if (!deletedFor.contains(currentUserId)) {
        deletedFor.add(currentUserId);

        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'deletedFor': deletedFor,
        });

        print('✅ Chat soft deleted for user: $currentUserId');

        // Check if all participants have deleted the chat
        if (deletedFor.length == participants.length) {
          print('🗑️ All participants deleted chat, performing hard delete');
          await deleteChatCompletely(chatId);
        }
      }
    } catch (e) {
      print('❌ Error soft deleting chat: $e');
      rethrow;
    }
  }

  // Delete chat completely (hard delete - removes chat and all messages)
  static Future<void> deleteChatCompletely(String chatId) async {
    try {
      print('🗑️ Starting hard delete for chat: $chatId');

      // Delete all messages in the chat
      final messages = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .get();

      final batch = _firestore.batch();

      // Delete all messages
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
        print('🗑️ Marked message for deletion: ${doc.id}');
      }

      // Delete the chat document
      batch.delete(_firestore.collection(_chatsCollection).doc(chatId));
      print('🗑️ Marked chat for deletion: $chatId');

      await batch.commit();
      print('✅ Chat and all messages deleted completely: $chatId');
    } catch (e) {
      print('❌ Error hard deleting chat: $e');
      rethrow;
    }
  }

  // Delete a chat (legacy method - now calls deleteChatForMe)
  static Future<void> deleteChat(String chatId) async {
    await deleteChatForMe(chatId);
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Reset unread count for this user
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'unreadCounts.$userId': 0,
      });

      // Mark all unread messages as read
      final unreadMessages = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .where('readBy', arrayContains: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        final messageData = doc.data();
        final readBy = List<String>.from(messageData['readBy'] ?? []);

        if (!readBy.contains(userId)) {
          readBy.add(userId);
          batch.update(doc.reference, {'readBy': readBy, 'isRead': true});
        }
      }

      await batch.commit();
      print('✅ Messages marked as read for user: $userId');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // Get total unread count for a user
  static Stream<int> streamTotalUnreadCount(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final unreadCounts = <String, int>{};
        if (doc.data()['unreadCounts'] != null) {
          final unreadData =
              doc.data()['unreadCounts'] as Map<dynamic, dynamic>;
          for (final entry in unreadData.entries) {
            unreadCounts[entry.key.toString()] = (entry.value as int?) ?? 0;
          }
        }
        totalUnread += unreadCounts[userId] ?? 0;
      }
      return totalUnread;
    });
  }

  // Get chat by ID
  static Future<Chat?> getChatById(String chatId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (docSnapshot.exists) {
        return Chat.fromMap(docSnapshot.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting chat by ID: $e');
      return null;
    }
  }

  // Stream chat data for real-time updates
  static Stream<Chat?> streamChat(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Chat.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Helper methods for avatar generation
  static String _getAvatarColor(String userId) {
    final colors = [
      'Colors.green',
      'Colors.blue',
      'Colors.orange',
      'Colors.purple',
      'Colors.red',
      'Colors.teal',
      'Colors.pink',
      'Colors.indigo',
      'Colors.amber',
    ];
    final index = userId.hashCode % colors.length;
    return colors[index];
  }

  static String _getAvatarIcon(String userId) {
    final icons = [
      '🐒',
      '💀',
      '🌈',
      '🐨',
      '⚔️',
      '👤',
      '🐸',
      '🎩',
      '🧛',
    ];
    final index = userId.hashCode % icons.length;
    return icons[index];
  }

  // Get messages with pagination
  static Future<List<ChatMessage>> getMessagesWithPagination(
    String chatId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final messages = querySnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Reverse to get chronological order
      return messages.reversed.toList();
    } catch (e) {
      print('❌ Error getting messages with pagination: $e');
      return [];
    }
  }

  // Get group chat information
  static Future<Map<String, dynamic>?> getGroupChatInfo(String chatId) async {
    try {
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        return null;
      }

      final chatData = chatDoc.data()!;
      final chatType = chatData['chatType'] ?? 'direct';

      if (chatType != 'group') {
        return null;
      }

      return {
        'chatId': chatId,
        'groupName': chatData['groupName'] ?? 'Group Chat',
        'groupDescription': chatData['groupDescription'],
        'groupAvatarUrl': chatData['groupAvatarUrl'],
        'creatorId': chatData['creatorId'],
        'admins': List<String>.from(chatData['admins'] ?? []),
        'participants': List<String>.from(chatData['participants'] ?? []),
        'createdAt': chatData['createdAt'],
        'lastMessage': chatData['lastMessage'],
        'lastMessageTime': chatData['lastMessageTime'],
        'lastMessageSender': chatData['lastMessageSender'],
      };
    } catch (e) {
      print('❌ Error getting group chat info: $e');
      return null;
    }
  }

  // Check if user is admin in group chat
  static Future<bool> isUserAdminInGroup(String chatId, String userId) async {
    try {
      final groupInfo = await getGroupChatInfo(chatId);
      if (groupInfo == null) return false;

      final admins = List<String>.from(groupInfo['admins'] ?? []);
      return admins.contains(userId);
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Add admin to group chat
  static Future<void> addAdminToGroup(String chatId, String userId) async {
    try {
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final admins = List<String>.from(chatData['admins'] ?? []);

      if (!admins.contains(userId)) {
        admins.add(userId);

        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'admins': admins,
        });

        print('✅ Added admin to group: $userId');
      }
    } catch (e) {
      print('❌ Error adding admin to group: $e');
      rethrow;
    }
  }

  // Remove admin from group chat
  static Future<void> removeAdminFromGroup(String chatId, String userId) async {
    try {
      final chatDoc =
          await _firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final admins = List<String>.from(chatData['admins'] ?? []);
      final creatorId = chatData['creatorId'];

      // Prevent removing the creator from admins
      if (userId == creatorId) {
        throw Exception('Cannot remove creator from admins');
      }

      if (admins.contains(userId)) {
        admins.remove(userId);

        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'admins': admins,
        });

        print('✅ Removed admin from group: $userId');
      }
    } catch (e) {
      print('❌ Error removing admin from group: $e');
      rethrow;
    }
  }
}
