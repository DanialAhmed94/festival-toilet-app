import 'package:flutter/material.dart';
import '../../services/firestore_chat_service.dart';
import '../../services/firestore_user_service.dart';
import '../resource_module/model/chat_models.dart';
import 'chat_detail_view.dart';

class CreateGroupView extends StatefulWidget {
  final Function(ChatListItem)? onGroupCreated;

  const CreateGroupView({Key? key, this.onGroupCreated}) : super(key: key);

  @override
  _CreateGroupViewState createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _currentUserId;
  List<ChatUser> _selectedUsers = [];
  bool _isLoading = false;
  bool _isCreatingGroup = false;
  bool _isSearching = false;
  bool _showSearchResult = false;
  ChatUser? _foundUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUserId = await FirestoreUserService.getUserId();
      if (_currentUserId != null) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_selectedUsers.any((selected) => selected.userId == user.userId)) {
        _selectedUsers.removeWhere((selected) => selected.userId == user.userId);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _performSearch() async {
    final number = _searchController.text.trim();
    if (number.isEmpty) return;

    // Validate phone number format (same as auth)
    if (!_isValidPhoneNumber(number)) {
      _showErrorSnackBar('Please enter a valid phone number (e.g., +447912345678)');
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _showSearchResult = false;
      _foundUser = null;
    });

    try {
      // Search for user by phone number
      final foundUser = await FirestoreUserService.searchUserByPhone(number);

      setState(() {
        _isLoading = false;
        _foundUser = foundUser;
        _showSearchResult = foundUser != null;
      });

      if (foundUser == null) {
        _showErrorSnackBar('No user found with this phone number');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error searching for user: $e');
    }
  }

  // Phone number validation (same as auth)
  bool _isValidPhoneNumber(String v) {
    // E.164 format validation: +[country code][number]
    // Minimum 7 digits, maximum 15 digits total
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(v);
  }

  Future<void> _createGroup() async {
    if (_currentUserId == null) {
      _showErrorSnackBar('Please login to create a group');
      return;
    }

    if (_groupNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a group name');
      return;
    }

    if (_selectedUsers.isEmpty) {
      _showErrorSnackBar('Please select at least one member');
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      // Create participant list including current user
      final participantIds = [_currentUserId!, ..._selectedUsers.map((u) => u.userId)];

      final chatId = await FirestoreChatService.createGroupChat(
        groupName: _groupNameController.text.trim(),
        creatorId: _currentUserId!,
        participantIds: participantIds,
        groupDescription: _groupDescriptionController.text.trim().isNotEmpty
            ? _groupDescriptionController.text.trim()
            : null,
      );

      // Create a ChatListItem for the new group
      final groupInfo = await FirestoreChatService.getGroupChatInfo(chatId);
      if (groupInfo != null) {
        final chatItem = ChatListItem(
          chatId: chatId,
          otherUserId: 'group_$chatId',
          otherUserName: groupInfo['groupName'] ?? 'Group Chat',
          otherUserAvatarColor: 'Colors.blue',
          otherUserAvatarIcon: '👥',
          lastMessage: '',
          lastMessageTime: null,
          lastMessageSender: '',
          unreadCount: 0,
          isOnline: false,
        );

        // Call the callback if provided
        if (widget.onGroupCreated != null) {
          widget.onGroupCreated!(chatItem);
        }

        // Navigate to the group chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              chatId: chatId,
              otherUserId: 'group_$chatId',
              otherUserName: groupInfo['groupName'] ?? 'Group Chat',
              otherUserAvatarColor: 'Colors.blue',
              otherUserAvatarIcon: '👥',
            ),
          ),
        );

        _showSuccessSnackBar('Group created successfully!');
      }
    } catch (e) {
      print('❌ Error creating group: $e');
      _showErrorSnackBar('Failed to create group. Please try again.');
    } finally {
      setState(() {
        _isCreatingGroup = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
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
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                height: kToolbarHeight + 40,
                child: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    "Create Group",
                    style: TextStyle(
                      fontFamily: "Ubuntu",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    if (_selectedUsers.isNotEmpty)
                      TextButton(
                        onPressed: _isCreatingGroup ? null : _createGroup,
                        child: _isCreatingGroup
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                          ),
                        )
                            : Text(
                          'Create',
                          style: TextStyle(
                            fontFamily: "Ubuntu",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // Group Info Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                            // Group Name Input
                            Text(
                              'Group Name',
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _groupNameController,
                              decoration: InputDecoration(
                                hintText: 'Enter group name...',
                                hintStyle: TextStyle(
                                  fontFamily: "Ubuntu",
                                  color: Colors.grey.shade500,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 16,
                              ),
                            ),

                            SizedBox(height: 16),

                            // Group Description Input
                            Text(
                              'Description (Optional)',
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _groupDescriptionController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Enter group description...',
                                hintStyle: TextStyle(
                                  fontFamily: "Ubuntu",
                                  color: Colors.grey.shade500,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selected Members Section
                      if (_selectedUsers.isNotEmpty) ...[
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Members (${_selectedUsers.length})',
                                style: TextStyle(
                                  fontFamily: "Ubuntu",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: 100,
                                  minHeight: 60,
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = _selectedUsers[index];
                                    return Container(
                                      margin: EdgeInsets.only(right: 12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _toggleUserSelection(user),
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.blue.shade300, width: 2),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Flexible(
                                            child: Text(
                                              user.userName,
                                              style: TextStyle(
                                                fontFamily: "Ubuntu",
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Search Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Members',
                              style: TextStyle(
                                fontFamily: "Ubuntu",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: "Enter phone number (e.g., +447912345678)",
                                        hintStyle: TextStyle(
                                          fontFamily: "Ubuntu",
                                          color: Colors.grey.shade500,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Search",
                                      style: TextStyle(
                                        fontFamily: "Ubuntu",
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Search Results and Selected Users
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Loading Indicator
                            if (_isLoading) ...[
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Searching...',
                                      style: TextStyle(
                                        fontFamily: "Ubuntu",
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Search Result
                            if (_showSearchResult && _foundUser != null) ...[
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Search Result',
                                      style: TextStyle(
                                        fontFamily: "Ubuntu",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    _buildSearchResultTile(_foundUser!),
                                  ],
                                ),
                              ),
                            ],

                            // Selected Users List
                            if (_selectedUsers.isNotEmpty) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Members (${_selectedUsers.length})',
                                    style: TextStyle(
                                      fontFamily: "Ubuntu",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  ...List.generate(_selectedUsers.length, (index) {
                                    final user = _selectedUsers[index];
                                    return _buildSelectedUserTile(user);
                                  }),
                                ],
                              ),
                            ] else ...[
                              // Empty state
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No members selected',
                                      style: TextStyle(
                                        fontFamily: "Ubuntu",
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Search for users by phone number to add them',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "Ubuntu",
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildSearchResultTile(ChatUser user) {
    final isAlreadySelected = _selectedUsers.any((selected) => selected.userId == user.userId);
    final isCurrentUser = user.userId == _currentUserId;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade300, width: 2),
            ),
            child: Center(
              child: Text(
                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userName,
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  user.phoneNumber,
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          if (isCurrentUser)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (isAlreadySelected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Added',
                style: TextStyle(
                  fontFamily: "Ubuntu",
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _toggleUserSelection(user),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedUserTile(ChatUser user) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleUserSelection(user),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove Button
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade300, width: 1),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
