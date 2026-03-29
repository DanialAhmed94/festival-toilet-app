import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../resource_module/model/chat_models.dart';
import '../widgets/firebase_stream_ui.dart';
import 'chat_detail_view.dart';
import 'create_chat_view.dart';
import 'create_group_view.dart';
import '../../services/firestore_chat_service.dart';
import '../../services/firestore_user_service.dart';

class InboxView extends StatefulWidget {
  @override
  _InboxViewState createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  int _selectedTabIndex = 0;
  String? _currentUserId;
  List<ChatListItem> _chatList = [];
  int _totalUnreadCount = 0;
  bool _isNavigating = false; // Prevent multiple navigation
  String? _navigatingToChatId; // Track which chat is being navigated to
  bool _userIdResolved = false;
  String? _userIdLoadError;
  int _chatsStreamRetryKey = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;
    setState(() {
      _userIdLoadError = null;
      _userIdResolved = false;
    });
    try {
      _currentUserId = await FirestoreUserService.getUserId();
      print('🔍 Current user ID loaded: $_currentUserId');
    } catch (e) {
      print('❌ Error loading current user: $e');
      _userIdLoadError = userFriendlyFirebaseError(e);
    } finally {
      if (mounted) {
        setState(() {
          _userIdResolved = true;
        });
      }
    }
  }

  void _retryChatsStream() {
    setState(() => _chatsStreamRetryKey++);
  }

  void _addNewChat(ChatListItem newChat) {
    setState(() {
      _chatList.insert(0, newChat);
    });
  }

  void _addNewGroup(ChatListItem newGroup) {
    setState(() {
      _chatList.insert(0, newGroup);
    });
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Create New',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Direct Chat Option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                ),
                child: Icon(
                  Icons.person_add,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              title: Text(
                'Direct Chat',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Start a conversation with someone',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateChatView(onChatCreated: _addNewChat),
                  ),
                );
              },
            ),

            // Group Chat Option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Icon(
                  Icons.group_add,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
              title: Text(
                'Group Chat',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Create a group with multiple people',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateGroupView(onGroupCreated: _addNewGroup),
                  ),
                );
              },
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // App Bar
            Container(
              height: kToolbarHeight + 40,
              child: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: Colors.black87, size: 24),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                title: Text(
                  "Messages",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),

            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.blue.shade600
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          "Direct",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Ubuntu",
                            fontWeight: _selectedTabIndex == 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.blue.shade600
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          "Group",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Ubuntu",
                            fontWeight: _selectedTabIndex == 1
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Messages List
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: _selectedTabIndex == 0
                    ? _buildMessagesList()
                    : _buildGroupsList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            onPressed: () => _showCreateOptions(),
            backgroundColor: Colors.blue.shade600,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
          if (_totalUnreadCount > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  _totalUnreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (!_userIdResolved) {
      return firebaseStreamLoading(message: 'Loading your account…');
    }
    if (_userIdLoadError != null) {
      return firebaseStreamError(
        context: context,
        message: _userIdLoadError!,
        onRetry: _loadCurrentUser,
        icon: Icons.person_off_outlined,
      );
    }
    if (_currentUserId == null) {
      return Center(
        child: Text(
          'Please sign in to view chats',
          style: TextStyle(
            fontFamily: 'Ubuntu',
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    return StreamBuilder<List<ChatListItem>>(
      key: ValueKey(_chatsStreamRetryKey),
      stream: FirestoreChatService.streamUserChats(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return firebaseStreamError(
            context: context,
            message: userFriendlyFirebaseError(snapshot.error),
            onRetry: _retryChatsStream,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return firebaseStreamLoading(message: 'Loading conversations…');
        }

        final allChats = snapshot.data ?? [];

        // Filter direct chats (not group chats)
        final directChats = allChats
            .where((chat) =>
                !chat.otherUserId.startsWith('group_') && (chat.isBlock) == 0)
            .toList();

        // Update total unread count for all chats
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final totalUnread =
              allChats.fold(0, (sum, chat) => sum + chat.unreadCount);
          if (totalUnread != _totalUnreadCount) {
            setState(() {
              _totalUnreadCount = totalUnread;
            });
          }
        });

        if (directChats.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "No direct conversations yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: "Ubuntu",
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Start chatting with friends by tapping the + button",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: "Ubuntu",
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: directChats.length,
          itemBuilder: (context, index) {
            final chat = directChats[index];
            return _buildMessageTile(chat);
          },
        );
      },
    );
  }

  Widget _buildGroupsList() {
    if (!_userIdResolved) {
      return firebaseStreamLoading(message: 'Loading your account…');
    }
    if (_userIdLoadError != null) {
      return firebaseStreamError(
        context: context,
        message: _userIdLoadError!,
        onRetry: _loadCurrentUser,
        icon: Icons.person_off_outlined,
      );
    }
    if (_currentUserId == null) {
      return Center(
        child: Text(
          'Please sign in to view groups',
          style: TextStyle(
            fontFamily: 'Ubuntu',
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    return StreamBuilder<List<ChatListItem>>(
      key: ValueKey(_chatsStreamRetryKey),
      stream: FirestoreChatService.streamUserChats(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return firebaseStreamError(
            context: context,
            message: userFriendlyFirebaseError(snapshot.error),
            onRetry: _retryChatsStream,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return firebaseStreamLoading(message: 'Loading groups…');
        }

        final allChats = snapshot.data ?? [];

        // Filter group chats
        final groupChats = allChats
            .where((chat) => chat.otherUserId.startsWith('group_'))
            .toList();

        if (groupChats.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.green.shade100, width: 2),
                    ),
                    child: Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: Colors.green.shade400,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "No group conversations yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: "Ubuntu",
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Create a group by tapping the + button",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: "Ubuntu",
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: groupChats.length,
          itemBuilder: (context, index) {
            final chat = groupChats[index];
            return _buildMessageTile(chat);
          },
        );
      },
    );
  }

  Widget _buildMessageTile(ChatListItem chat) {
    final bool isUnread = chat.unreadCount > 0;

    return Dismissible(
      key: Key(chat.chatId),
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Text(
                'Delete Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Ubuntu",
                ),
              ),
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(chat);
      },
      onDismissed: (direction) {
        _deleteChat(chat);
      },
      child: GestureDetector(
        onTap: () async {
          // Prevent multiple taps to the same chat
          if (_isNavigating) {
            print('⚠️ Already navigating, ignoring tap');
            return;
          }

          print('🚀 Starting navigation to chat: ${chat.chatId}');
          setState(() {
            _isNavigating = true;
            _navigatingToChatId = chat.chatId;
          });

          // Small delay to ensure state is set
          await Future.delayed(Duration(milliseconds: 100));

          try {
            // Navigate to chat detail view
            if (mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailView(
                    chatId: chat.chatId,
                    otherUserId: chat.otherUserId,
                    otherUserName: chat.otherUserName,
                    otherUserAvatarColor: chat.otherUserAvatarColor,
                    otherUserAvatarIcon: chat.otherUserAvatarIcon,
                  ),
                ),
              );

              // Mark messages as read AFTER navigation (when user returns)
              if (_currentUserId != null) {
                await FirestoreChatService.markMessagesAsRead(
                    chat.chatId, _currentUserId!);
              }
            }
          } catch (e) {
            print('❌ Error navigating to chat: $e');
          } finally {
            // Reset navigation state when returning from chat detail
            if (mounted) {
              print('✅ Navigation completed, resetting state');
              setState(() {
                _isNavigating = false;
                _navigatingToChatId = null;
              });
            }
          }
        },
        onLongPress: () => _showChatOptions(chat),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? Colors.blue.shade100 : Colors.grey.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getAvatarColor(chat.otherUserAvatarColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isUnread ? Colors.blue.shade200 : Colors.grey.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getAvatarColor(chat.otherUserAvatarColor)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    chat.otherUserAvatarIcon ?? '👤',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat.otherUserName,
                            style: TextStyle(
                              fontFamily: "Ubuntu",
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessageTime != null) ...[
                          Text(
                            _formatTime(chat.lastMessageTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: "Ubuntu",
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage.isNotEmpty
                                ? chat.lastMessage
                                : 'No messages yet',
                            style: TextStyle(
                              fontFamily: "Ubuntu",
                              color: isUnread
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade500,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Ubuntu",
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }

  Color _getAvatarColor(String? colorString) {
    if (colorString == null) return Colors.grey;

    switch (colorString) {
      case 'Colors.green':
        return Colors.green;
      case 'Colors.blue':
        return Colors.blue;
      case 'Colors.orange':
        return Colors.orange;
      case 'Colors.purple':
        return Colors.purple;
      case 'Colors.red':
        return Colors.red;
      case 'Colors.teal':
        return Colors.teal;
      case 'Colors.pink':
        return Colors.pink;
      case 'Colors.indigo':
        return Colors.indigo;
      case 'Colors.amber':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showChatOptions(ChatListItem chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Chat info
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAvatarColor(chat.otherUserAvatarColor),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    chat.otherUserAvatarIcon ?? '👤',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              title: Text(
                chat.otherUserName,
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Chat with ${chat.otherUserName}',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            Divider(height: 1),

            // Delete option
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
              title: Text(
                'Delete chat',
                style: TextStyle(fontFamily: "Ubuntu", fontSize: 16),
              ),
              onTap: () async {
                Navigator.pop(context);
                final shouldDelete = await _showDeleteConfirmation(chat);
                if (shouldDelete) {
                  _deleteChat(chat);
                }
              },
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(ChatListItem chat) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.delete_forever,
                    color: Colors.red.shade600, size: 24),
                SizedBox(width: 12),
                Text(
                  'Delete Chat',
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete this chat?',
              style: TextStyle(
                fontFamily: "Ubuntu",
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Delete Chat',
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _deleteChat(ChatListItem chat) async {
    try {
      await FirestoreChatService.deleteChatForMe(chat.chatId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showMessageDialog(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          message['sender'],
          style: TextStyle(fontFamily: "Ubuntu"),
        ),
        content: Text(
          message['message'],
          style: TextStyle(fontFamily: "Ubuntu"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would typically navigate to a full chat screen
            },
            child: Text("Reply"),
          ),
        ],
      ),
    );
  }
}
