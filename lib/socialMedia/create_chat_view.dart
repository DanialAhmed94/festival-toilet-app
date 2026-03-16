import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../resource_module/model/chat_models.dart';
import 'chat_detail_view.dart';
import '../../services/firestore_user_service.dart';
import '../../services/firestore_chat_service.dart';

class CreateChatView extends StatefulWidget {
  final Function(ChatListItem)? onChatCreated;

  const CreateChatView({Key? key, this.onChatCreated}) : super(key: key);

  @override
  _CreateChatViewState createState() => _CreateChatViewState();
}

class _CreateChatViewState extends State<CreateChatView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  bool _showSearchResult = false;
  ChatUser? _foundUser;
  String? _currentUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUserId = await FirestoreUserService.getUserId();
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
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
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                height: kToolbarHeight + 20,
                child: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(
                    "Direct",
                    style: TextStyle(
                      fontFamily: "Ubuntu",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // Enhanced UI Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Icon and Title
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue.shade300, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_add_rounded,
                                size: 40,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Start a Direct Chat",
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Search for someone by their phone number to start chatting",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Section
                      _buildDirectSearch(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectSearch() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Enhanced Search Input
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Search for User",
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                // Responsive search row
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 400) {
                      // Wide screen - horizontal layout
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200, width: 1),
                              ),
                              child: TextField(
                                controller: _searchController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: "Enter phone number (e.g., +447912345678)",
                                  hintStyle: TextStyle(
                                    fontFamily: "Ubuntu",
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  prefixIcon: Icon(
                                    Icons.phone,
                                    color: Colors.grey.shade500,
                                    size: 20,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isSearching = value.isNotEmpty;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: _performSearch,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Search",
                                    style: TextStyle(
                                      fontFamily: "Ubuntu",
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Narrow screen - vertical layout
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200, width: 1),
                            ),
                            child: TextField(
                              controller: _searchController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: "Enter phone number (e.g., +447912345678)",
                                hintStyle: TextStyle(
                                  fontFamily: "Ubuntu",
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isSearching = value.isNotEmpty;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: _performSearch,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Search",
                                    style: TextStyle(
                                      fontFamily: "Ubuntu",
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Loading Indicator
          if (_isLoading) _buildLoadingIndicator(),

          // Search Result or Not Found
          if (_showSearchResult) _buildSearchResult(),
          if (_isSearching && !_showSearchResult && !_isLoading) _buildNotFound(),
        ],
      ),
    );
  }



  Widget _buildSearchResult() {
    if (_foundUser == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 350) {
            // Wide screen - horizontal layout
            return Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(_foundUser!.userId),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _getAvatarIcon(_foundUser!.userId),
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _foundUser!.userName,
                        style: TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        _foundUser!.phoneNumber,
                        style: TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // Message button
                GestureDetector(
                  onTap: _startChat,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      "Message",
                      style: TextStyle(
                        fontFamily: "Ubuntu",
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Narrow screen - vertical layout
            return Column(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(_foundUser!.userId),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _getAvatarIcon(_foundUser!.userId),
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // User info
                Column(
                  children: [
                    Text(
                      _foundUser!.userName,
                      style: TextStyle(
                        fontFamily: "Ubuntu",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _foundUser!.phoneNumber,
                      style: TextStyle(
                        fontFamily: "Ubuntu",
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Message button
                GestureDetector(
                  onTap: _startChat,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Start Chat",
                          style: TextStyle(
                            fontFamily: "Ubuntu",
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Searching...",
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Looking for user with this phone number",
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            "User Not Found",
            style: TextStyle(
              fontFamily: "Ubuntu",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "No user found with this phone number. Please check the number and try again.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Ubuntu",
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSearchResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _performSearch() async {
    final number = _searchController.text.trim();
    if (number.isEmpty) return;

    // Validate phone number format (same as auth)
    if (!_isValidPhoneNumber(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number (e.g., +447912345678)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _showSearchResult = false;
      _foundUser = null;
    });

    // Scroll to show loading indicator
    _scrollToSearchResult();

    try {
      // Search for user by phone number
      final foundUser = await FirestoreUserService.searchUserByPhone(number);

      setState(() {
        _isLoading = false;
        _foundUser = foundUser;
        _showSearchResult = foundUser != null;
      });

      // Scroll to search result if found
      if (foundUser != null) {
        _scrollToSearchResult();
      }

      if (foundUser == null) {
        // Show not found message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user found with this phone number'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching for user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Phone number validation (same as auth)
  bool _isValidPhoneNumber(String v) {
    // E.164 format validation: +[country code][number]
    // Minimum 7 digits, maximum 15 digits total
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(v);
  }

  void _startChat() async {
    if (_foundUser == null || _currentUserId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Create or get existing chat
      final chatId = await FirestoreChatService.createOrGetChat(_currentUserId!, _foundUser!.userId);

      // Create chat list item for the inbox
      final newChat = ChatListItem(
        chatId: chatId,
        otherUserId: _foundUser!.userId,
        otherUserName: _foundUser!.userName,
        otherUserAvatarColor: _getAvatarColorString(_foundUser!.userId),
        otherUserAvatarIcon: _getAvatarIcon(_foundUser!.userId),
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSender: '',
        unreadCount: 0,
        isOnline: _foundUser!.isOnline,
      );

      // Call the callback to add the chat to inbox
      widget.onChatCreated?.call(newChat);

      setState(() {
        _isLoading = false;
      });

      // Navigate to chat detail view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailView(
            chatId: chatId,
            otherUserId: _foundUser!.userId,
            otherUserName: _foundUser!.userName,
            otherUserAvatarColor: _getAvatarColorString(_foundUser!.userId),
            otherUserAvatarIcon: _getAvatarIcon(_foundUser!.userId),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final index = userId.hashCode % colors.length;
    return colors[index];
  }

  String _getAvatarColorString(String userId) {
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

  String _getAvatarIcon(String userId) {
    final icons = [
      '🐒', '💀', '🌈', '🐨', '⚔️', '👤', '🐸', '🎩', '🧛',
    ];
    final index = userId.hashCode % icons.length;
    return icons[index];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

