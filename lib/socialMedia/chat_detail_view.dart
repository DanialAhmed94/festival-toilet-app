import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_chat_service.dart';
import '../../services/firestore_user_service.dart';
import '../resource_module/model/chat_models.dart';
import '../widgets/firebase_stream_ui.dart';

class ChatDetailView extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarColor;
  final String? otherUserAvatarIcon;

  const ChatDetailView({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarColor,
    this.otherUserAvatarIcon,
  }) : super(key: key);

  @override
  _ChatDetailViewState createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  List<ChatMessage> _messages = [];
  DateTime _currentDisplayDate = DateTime.now();
  bool _isFirstLoad = true;
  bool _isUserTyping = false;
  int _previousMessageCount = 0;
  bool _shouldAutoScroll = true;
  double _lastScrollPosition = 0;
  bool _isSendingMessage = false;
  String _lastSentMessage = '';
  DateTime? _lastSendTime;
  bool _isDeletingMessage = false;
  Map<String, String> _senderNames =
      {}; // Cache for sender names in group chats
  bool _isGroupChat = false; // Flag to identify group chats
  bool _userIdResolved = false;
  String? _userIdLoadError;
  int _messagesStreamRetryKey = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _setupScrollListener();
    _checkIfGroupChat();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final currentPosition = _scrollController.position.pixels;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

        // Check if user is near the bottom (within 100 pixels)
        _shouldAutoScroll = (maxScrollExtent - currentPosition) < 100;
        _lastScrollPosition = currentPosition;
      }
    });
  }

  void _checkIfGroupChat() {
    _isGroupChat = widget.otherUserId.startsWith('group_');
  }

  Future<String> _getSenderName(String senderId) async {
    // Return cached name if available
    if (_senderNames.containsKey(senderId)) {
      return _senderNames[senderId]!;
    }

    try {
      // Get user info from Firestore
      final user = await FirestoreUserService.getUserById(senderId);
      if (user != null) {
        final senderName = user.userName;
        _senderNames[senderId] = senderName; // Cache the name
        return senderName;
      }
    } catch (e) {
      print('❌ Error getting sender name for $senderId: $e');
    }

    // Return a fallback name if user not found
    return 'Unknown User';
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;
    setState(() {
      _userIdLoadError = null;
      _userIdResolved = false;
    });
    try {
      _currentUserId = await FirestoreUserService.getUserId();
      if (_currentUserId != null) {
        await FirestoreChatService.markMessagesAsRead(
            widget.chatId, _currentUserId!);
      }
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

  void _retryMessagesStream() {
    setState(() => _messagesStreamRetryKey++);
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      final duration = animate ? Duration(milliseconds: 300) : Duration.zero;
      final curve = animate ? Curves.easeOut : Curves.linear;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // With reverse: true, scrolling to 0 shows the latest messages
          _scrollController.animateTo(
            0,
            duration: duration,
            curve: curve,
          );
        }
      });
    }
  }

  void _handleNewMessages(List<ChatMessage> messages) {
    final newMessageCount = messages.length;

    // Check if this is the first load
    if (_isFirstLoad && messages.isNotEmpty) {
      _isFirstLoad = false;
      // With reverse: true, the latest messages are already visible at the bottom
      // No need to scroll on first load
      return;
    }

    // Check if new messages arrived
    if (newMessageCount > _previousMessageCount) {
      // New message arrived
      if (_isUserTyping && _shouldAutoScroll) {
        // User is typing and was near the bottom - scroll to show new message
        Future.delayed(Duration(milliseconds: 50), () {
          _scrollToBottom(animate: true);
        });
      } else if (_isUserTyping && !_shouldAutoScroll) {
        // User is typing but scrolled up - don't auto-scroll, let them see the new message count
        // We could show a "new message" indicator here if needed
      } else if (!_isUserTyping) {
        // User is not typing - auto-scroll to show new message
        Future.delayed(Duration(milliseconds: 50), () {
          _scrollToBottom(animate: true);
        });
      }
    }

    _previousMessageCount = newMessageCount;
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
            // Header
            _buildHeader(),

            // Messages
            Expanded(
              child: _buildMessagesList(),
            ),

            // Message input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0, // keeps avatar close to leading
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _getAvatarColor(widget.otherUserAvatarColor),
                  child: Text(
                    widget.otherUserAvatarIcon ?? '🐒',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Ubuntu",
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Online",
                        style: TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87, size: 24),
            onPressed: _showChatOptions,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // iOS defaults to true
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.shade400,
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateForDisplay(_currentDisplayDate),
              style: TextStyle(
                fontFamily: "Ubuntu",
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.shade400,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'TODAY, ${_getMonthAbbreviation(date.month)} ${date.day.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'YESTERDAY, ${_getMonthAbbreviation(date.month)} ${date.day.toString().padLeft(2, '0')}';
    } else {
      return '${_getMonthAbbreviation(date.month)} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }

  Widget _buildMessagesList() {
    if (!_userIdResolved) {
      return firebaseStreamLoading(message: 'Loading messages…');
    }
    if (_userIdLoadError != null) {
      return firebaseStreamError(
        context: context,
        message: _userIdLoadError!,
        onRetry: _loadCurrentUser,
        icon: Icons.person_off_outlined,
      );
    }

    return StreamBuilder<List<ChatMessage>>(
      key: ValueKey(_messagesStreamRetryKey),
      stream: FirestoreChatService.streamMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return firebaseStreamError(
            context: context,
            message: userFriendlyFirebaseError(snapshot.error),
            onRetry: _retryMessagesStream,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return firebaseStreamLoading(message: 'Loading messages…');
        }

        final messages = snapshot.data ?? [];

        // Handle new messages
        _handleNewMessages(messages);

        // Update current display date based on the most recent message
        if (messages.isNotEmpty) {
          final latestMessage = messages.last;
          final messageDate = DateTime(
            latestMessage.timestamp.year,
            latestMessage.timestamp.month,
            latestMessage.timestamp.day,
          );
          if (_currentDisplayDate != messageDate) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _currentDisplayDate = messageDate;
              });
            });
          }
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // This will show latest messages at the bottom
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // Since we're using reverse: true, we need to reverse the index
            final reversedIndex = messages.length - 1 - index;
            final message = messages[reversedIndex];
            final showDateSeparator =
                _shouldShowDateSeparator(messages, reversedIndex);

            return Column(
              children: [
                if (showDateSeparator)
                  _buildMessageDateSeparator(message.timestamp),
                _buildMessageBubble(message),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateSeparator(List<ChatMessage> messages, int index) {
    if (index == 0) return true; // Always show for first message

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );

    return currentDate != previousDate;
  }

  Widget _buildMessageDateSeparator(DateTime messageDate) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.shade400,
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateForDisplay(messageDate),
              style: TextStyle(
                fontFamily: "Ubuntu",
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.shade400,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isOutgoing = message.senderId == _currentUserId;
    final bool isRead = message.isRead;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name for group chats (only for incoming messages)
            if (_isGroupChat && !isOutgoing) ...[
              FutureBuilder<String>(
                future: _getSenderName(message.senderId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      margin: EdgeInsets.only(
                          left: 48, bottom: 4), // Align with message bubble
                      child: Text(
                        snapshot.data!,
                        style: TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],

            Row(
              mainAxisAlignment:
                  isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isOutgoing) ...[
                  // Avatar for incoming messages
                  Container(
                    width: 36,
                    height: 36,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _getAvatarColor(widget.otherUserAvatarColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: _getAvatarColor(widget.otherUserAvatarColor)
                              .withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.otherUserAvatarIcon ?? '🐒',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],

                // Message bubble
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOutgoing ? Colors.blue.shade600 : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(isOutgoing ? 20 : 4),
                        bottomRight: Radius.circular(isOutgoing ? 4 : 20),
                      ),
                      border: isOutgoing
                          ? null
                          : Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: isOutgoing
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.message,
                          style: TextStyle(
                            fontFamily: "Ubuntu",
                            fontSize: 16,
                            color: isOutgoing ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMessageTime(message.timestamp),
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 11,
                                color: isOutgoing
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isOutgoing) ...[
                              SizedBox(width: 6),
                              Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: isRead
                                    ? Colors.blue.shade200
                                    : Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                onTap: () {
                  setState(() {
                    _isUserTyping = true;
                  });
                  // Scroll to bottom when user starts typing
                  Future.delayed(Duration(milliseconds: 100), () {
                    _scrollToBottom(animate: true);
                  });
                },
                onChanged: (value) {
                  setState(() {
                    _isUserTyping = value.isNotEmpty;
                  });
                },
                onEditingComplete: () {
                  setState(() {
                    _isUserTyping = false;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontFamily: "Ubuntu",
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Send button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isSendingMessage
                  ? Colors.grey.shade400
                  : Colors.blue.shade600,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (_isSendingMessage ? Colors.grey : Colors.blue)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isSendingMessage
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isSendingMessage ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    // Prevent multiple sends of the same message
    if (_isSendingMessage) return;

    // Check if this is the same message sent recently (within 2 seconds)
    final now = DateTime.now();
    if (text == _lastSentMessage && _lastSendTime != null) {
      final timeDifference = now.difference(_lastSendTime!).inMilliseconds;
      if (timeDifference < 2000) {
        // 2 seconds debounce
        return;
      }
    }

    setState(() {
      _isSendingMessage = true;
    });

    try {
      // Send message to Firestore
      await FirestoreChatService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUserId!,
        message: text,
      );

      // Update last sent message info
      _lastSentMessage = text;
      _lastSendTime = now;

      _messageController.clear();

      // Reset typing state
      setState(() {
        _isUserTyping = false;
        _isSendingMessage = false;
      });

      // Scroll to bottom after sending
      _scrollToBottom(animate: true);
    } catch (e) {
      setState(() {
        _isSendingMessage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMessageOptions(ChatMessage message) {
    final bool isOutgoing = message.senderId == _currentUserId;

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

            // Message preview
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.message, color: Colors.grey.shade600, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.message,
                      style: TextStyle(
                        fontFamily: "Ubuntu",
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Delete options
            if (isOutgoing) ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade600),
                title: Text(
                  'Delete from me',
                  style: TextStyle(fontFamily: "Ubuntu", fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message, deleteForEveryone: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red.shade800),
                title: Text(
                  'Delete from everyone',
                  style: TextStyle(fontFamily: "Ubuntu", fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message, deleteForEveryone: true);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade600),
                title: Text(
                  'Delete from me',
                  style: TextStyle(fontFamily: "Ubuntu", fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message, deleteForEveryone: false);
                },
              ),
            ],

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(ChatMessage message,
      {bool deleteForEveryone = false}) {
    final bool isOutgoing = message.senderId == _currentUserId;
    final String title =
        deleteForEveryone ? 'Delete from Everyone' : 'Delete from Me';
    final String content = deleteForEveryone
        ? 'Are you sure you want to delete this message from everyone? This action cannot be undone and will remove the message for all participants.'
        : 'Are you sure you want to delete this message? This will only remove it from your view.';
    final String buttonText =
        deleteForEveryone ? 'Delete from Everyone' : 'Delete from Me';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(deleteForEveryone ? Icons.delete_forever : Icons.delete,
                color: Colors.red.shade600, size: 24),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: "Ubuntu",
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(
            fontFamily: "Ubuntu",
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: _isDeletingMessage
                ? null
                : () => _deleteMessage(message,
                    deleteForEveryone: deleteForEveryone),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isDeletingMessage
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: TextStyle(
                      fontFamily: "Ubuntu",
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(ChatMessage message,
      {bool deleteForEveryone = false}) async {
    setState(() {
      _isDeletingMessage = true;
    });

    try {
      await FirestoreChatService.deleteMessage(widget.chatId, message.messageId,
          deleteForEveryone: deleteForEveryone);

      Navigator.pop(context); // Close dialog

      final successMessage = deleteForEveryone
          ? 'Message deleted for everyone'
          : 'Message deleted for you';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close dialog

      final errorMessage = deleteForEveryone
          ? 'Error deleting message for everyone: $e'
          : 'Error deleting message: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isDeletingMessage = false;
      });
    }
  }

  void _showChatOptions() {
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
                  color: _getAvatarColor(widget.otherUserAvatarColor),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.otherUserAvatarIcon ?? '🐒',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              title: Text(
                widget.otherUserName,
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Chat with ${widget.otherUserName}',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            Divider(height: 1),

            // Delete chat option
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
              title: Text(
                'Delete chat',
                style: TextStyle(fontFamily: "Ubuntu", fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat();
              },
            ),

            ListTile(
              leading: Icon(Icons.block, color: Colors.red.shade600),
              title: const Text(
                'Block User',
                style: TextStyle(fontFamily: "Ubuntu", fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmBlockUser();
              },
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBlockUser() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Block User"),
        content: const Text(
          "Are you sure you want to block this user? You won’t receive any more messages from them.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Block",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({'isBlock': 1});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User has been blocked.")),
        );

        // ✅ Go back after blocking
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to block user: $e")),
        );
      }
    }
  }

  void _confirmDeleteChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600, size: 24),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this chat?',
              style: TextStyle(
                fontFamily: "Ubuntu",
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This will permanently delete all messages and cannot be undone.',
              style: TextStyle(
                fontFamily: "Ubuntu",
                fontSize: 14,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () => _deleteChat(),
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
    );
  }

  void _deleteChat() async {
    try {
      await FirestoreChatService.deleteChat(widget.chatId);

      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to chat list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_setupScrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}
