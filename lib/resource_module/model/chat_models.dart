import 'package:cloud_firestore/cloud_firestore.dart';

// User model for Firestore
class ChatUser {
  final String userId;
  final String phoneNumber;
  final String userName;
  final String? fcmToken;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.userId,
    required this.phoneNumber,
    required this.userName,
    this.fcmToken,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'userName': userName,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      userId: map['userId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      userName: map['userName'] ?? '',
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }
}

// Chat model for Firestore
class Chat {
  final String chatId;
  final List<String> participants;
  final String chatType; // 'direct' or 'group'
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final List<String> deletedFor; // Users who deleted this chat
  final bool isDeleted; // Hard delete flag
  final int isBlock; // 0 = not blocked, 1 = blocked

  Chat({
    required this.chatId,
    required this.participants,
    this.chatType = 'direct',
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    required this.unreadCounts,
    required this.createdAt,
    this.deletedFor = const [],
    this.isDeleted = false,
    this.isBlock = 0, // ✅ default 0
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'chatType': chatType,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSender': lastMessageSender,
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'deletedFor': deletedFor,
      'isDeleted': isDeleted,
      'isBlock': isBlock, // ✅ added
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      chatType: map['chatType'] ?? 'direct',
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSender: map['lastMessageSender'],
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
      isBlock: map['isBlock'] ?? 0, // ✅ default 0
    );
  }

  // Helper method to check if chat is deleted for a specific user
  bool isDeletedForUser(String userId) {
    return deletedFor.contains(userId);
  }

  // Helper method to create a copy with updated fields
  Chat copyWith({
    String? chatId,
    List<String>? participants,
    String? chatType,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
    List<String>? deletedFor,
    bool? isDeleted,
    int? isBlock,
  }) {
    return Chat(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      chatType: chatType ?? this.chatType,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
      deletedFor: deletedFor ?? this.deletedFor,
      isDeleted: isDeleted ?? this.isDeleted,
      isBlock: isBlock ?? this.isBlock, // ✅ handled in copyWith
    );
  }
}

// Message model for Firestore
class ChatMessage {
  final String messageId;
  final String chatId;
  final String senderId;
  final String message;
  final String messageType; // 'text', 'image', 'video', 'document'
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final List<String> deletedFor; // Soft delete - users who deleted this message
  final bool isDeleted; // Hard delete flag

  ChatMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.messageType = 'text',
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
    required this.readBy,
    this.deletedFor = const [],
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'deletedFor': deletedFor,
      'isDeleted': isDeleted,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      messageType: map['messageType'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // Helper method to check if message is deleted for a specific user
  bool isDeletedForUser(String userId) {
    return deletedFor.contains(userId);
  }

  // Helper method to create a copy with updated deletion status
  ChatMessage copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? message,
    String? messageType,
    String? mediaUrl,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    List<String>? deletedFor,
    bool? isDeleted,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      deletedFor: deletedFor ?? this.deletedFor,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

// Chat list item model for UI
class ChatListItem {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarColor;
  final String? otherUserAvatarIcon;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSender;
  final int unreadCount;
  final bool isOnline;
  final int isBlock;

  ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarColor,
    this.otherUserAvatarIcon,
    required this.lastMessage,
    this.lastMessageTime,
    required this.lastMessageSender,
    required this.unreadCount,
    this.isOnline = false,
    this.isBlock = 0,
  });
}
