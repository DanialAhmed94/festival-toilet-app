import 'dart:convert'; // For decoding base64
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

// Import your custom transition and utilities

import '../../annim/transiton.dart';

import '../../services/firestore_chat_service.dart';
import '../../services/firestore_user_service.dart';
import '../resource_module/constants/AppConstants.dart';
import '../resource_module/utilities/sharedPrefs.dart';
import 'createPost.dart';
import 'inbox_view.dart';

class SocialMediaHomeView extends StatefulWidget {
  const SocialMediaHomeView({Key? key}) : super(key: key);

  @override
  _SocialMediaHomeViewState createState() => _SocialMediaHomeViewState();
}

class _SocialMediaHomeViewState extends State<SocialMediaHomeView> {
  String? bearerToken;

  // Pagination state for posts
  final List<DocumentSnapshot> _postDocs = [];
  DocumentSnapshot? _lastPostDoc;
  bool _isLoadingPosts = false;
  bool _hasMorePosts = true;

  // NEW: Keep track of whether a like/unlike transaction is in-progress per post
  final Map<String, bool> _likeInProgressMap = {};

  static const int _postsPageSize = 10;

  // ADDED: Track the timestamp of the most recent post we have
  // so we only listen for truly new posts that come in after that time.
  Timestamp _mostRecentPostTimestamp = Timestamp(0, 0);

  // ADDED: Track current carousel index for each post
  final Map<String, int> _currentCarouselIndices = {};

  @override
  void initState() {
    super.initState();
    loadToken();
    // After we finish initial pagination fetch, we start listening for new posts
    _fetchPosts().then((_) {
      _listenForNewPosts();
    });
  }

  Future<void> loadToken() async {
    bearerToken = await getToken(); // Fetch the bearer token
    setState(() {}); // Update UI after token is loaded
  }

  /// Fetch a page of posts
  Future<void> _fetchPosts() async {
    if (_isLoadingPosts || !_hasMorePosts) return;
    setState(() {
      _isLoadingPosts = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(_postsPageSize);

    if (_lastPostDoc != null) {
      query = query.startAfterDocument(_lastPostDoc!);
    }

    final snap = await query.get();
    print('Fetched ${snap.docs.length} docs');
    for (var d in snap.docs) {
      print(d.data());
    }

    if (snap.docs.isNotEmpty) {
      _lastPostDoc = snap.docs.last;
      _postDocs.addAll(snap.docs);

      // Update _mostRecentPostTimestamp if these fetched docs are newer
      // (the first doc in snap.docs is the newest because we order desc)
      final newestDoc = snap.docs.first;
      final newestData = newestDoc.data() as Map<String, dynamic>;
      final newestCreatedAt = newestData['createdAt'] as Timestamp;
      if (newestCreatedAt.compareTo(_mostRecentPostTimestamp) > 0) {
        _mostRecentPostTimestamp = newestCreatedAt;
      }
    }

    if (snap.docs.length < _postsPageSize) {
      _hasMorePosts = false;
    }

    setState(() {
      _isLoadingPosts = false;
    });
  }

  /// ADDED: Listen for newly created posts in real time (createdAt > the newest we know).
  /// Inserts them at index 0 so they appear at the top of the feed.
  void _listenForNewPosts() {
    // If we never fetched anything, _mostRecentPostTimestamp is (0,0).
    // That means we'll pick up *all* posts, so let's handle that logic:
    // if we truly fetched some docs, we have a real timestamp; if not, we keep 0,0 as is.
    FirebaseFirestore.instance
        .collection('posts')
        .where('createdAt', isGreaterThan: _mostRecentPostTimestamp)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final newPostDoc = change.doc;
          setState(() {
            _postDocs.insert(0, newPostDoc);
            // Initialize carousel index for the new post
            _currentCarouselIndices[newPostDoc.id] = 0;
          });

          // Update _mostRecentPostTimestamp if this newly added doc is the newest
          final newData = newPostDoc.data() as Map<String, dynamic>;
          final newCreatedAt = newData['createdAt'] as Timestamp;
          if (newCreatedAt.compareTo(_mostRecentPostTimestamp) > 0) {
            _mostRecentPostTimestamp = newCreatedAt;
          }
        }
      }
    });
  }

  /// Refresh posts (used for pull-to-refresh and after adding a new post)
  Future<void> _refreshPosts() async {
    setState(() {
      _postDocs.clear();
      _lastPostDoc = null;
      _hasMorePosts = true;
      // Reset so that _listenForNewPosts can pick from scratch
      _mostRecentPostTimestamp = Timestamp(0, 0);
      _currentCarouselIndices.clear();
    });
    await _fetchPosts();
  }

  /// Formats the post time based on the difference from the current time.
  String _formatPostTime(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt);

    if (difference.inHours < 24) {
      return '${difference.inHours} Hr${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      // Format the date as per your preference, e.g., Aug 25, 2023
      return '${_getMonthName(createdAt.month)} ${createdAt.day}, ${createdAt.year}';
    }
  }

  /// Returns the month name based on the month number.
  String _getMonthName(int monthNumber) {
    const List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return monthNames[monthNumber - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPosts, // Enables pull-to-refresh
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppConstants.homeBG,
                fit: BoxFit.fill,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  title: const Text(
                    "Feed",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Ubuntu",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leadingWidth:
                  100, // Adjust the width to accommodate both widgets
                  leading: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      // Optional: Add spacing between the back button and avatar
                      const SizedBox(width: 8),
                      GestureDetector(
                        child: CircleAvatar(
                          backgroundImage: AssetImage(AppConstants.crapLogo),
                          radius: 16, // Adjust the size as needed
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.message,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadePageRouteBuilder(
                            widget: InboxView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Positioned fill - show list of paginated posts
            Positioned.fill(
              top: kToolbarHeight + 30, // Adjusted to account for AppBar height
              child: _buildPostList(),
            ),
          ],
        ),
      ),

      // FloatingActionButton to create a new post
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            FadePageRouteBuilder(widget: CreatePostPage()),
          );
          await _refreshPosts(); // Refresh posts after creating a new one
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Builds a ListView of currently loaded posts + a load-more row at the end
  Widget _buildPostList() {
    if (_postDocs.isEmpty && _isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_postDocs.isEmpty && !_isLoadingPosts) {
      return const Center(child: Text("No posts yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _postDocs.length + 1, // extra item for load-more indicator
      itemBuilder: (context, index) {
        if (index == _postDocs.length) {
          // The "Load More" or "No more posts" row
          if (_hasMorePosts) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _isLoadingPosts
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _fetchPosts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text(
                    "Load More Posts",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("No more posts."),
              ),
            );
          }
        }

        final doc = _postDocs[index];
        final postId = doc.id;
        // Grab postData statically here (so no real-time streaming for everything):
        final postData = doc.data() as Map<String, dynamic>;

        return PostItemWidget(
          postId: postId,
          bearerToken: bearerToken,
          parentState: this,
          postData: postData, // pass the static data
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Methods below are called by PostItemWidget (for building post UI, etc.)
  // -------------------------------------------------------------------------
  Widget buildPostItemUI(
      BuildContext context,
      Map<String, dynamic> postData,
      String postId,
      ) {
    final String description = postData['description'] ?? '';

    // CHANGED: Now reading 'imageUrls', 'videoUrls', 'imageThumbnailUrls', & 'videoThumbnailUrls' from Firestore
    final List imageUrls = postData['imageUrls'] ?? [];
    final List videoUrls = postData['videoUrls'] ?? [];
    final List imageThumbnailUrls = postData['imageThumbnailUrls'] ?? [];
    final List videoThumbnailUrls = postData['videoThumbnailUrls'] ?? [];

    final int likesCount = postData['likesCount'] ?? 0;
    final List likes = postData['likes'] ?? [];
    final String userName = postData['userName'].toString();

    // Ensure 'createdAt' is a Timestamp and convert to DateTime
    final Timestamp timestamp = postData['createdAt'] as Timestamp;
    final DateTime createdAt = timestamp.toDate();

    // CHANGED: Combine imageUrls and videoUrls with their respective thumbnail URLs
    final List<Map<String, String>> mediaList = [];

    for (int i = 0; i < imageUrls.length; i++) {
      mediaList.add({
        'type': 'image',
        'thumbnailUrl': imageThumbnailUrls.length > i
            ? imageThumbnailUrls[i]
            : imageUrls[i],
        'fullUrl': imageUrls[i],
      });
    }

    for (int i = 0; i < videoUrls.length; i++) {
      mediaList.add({
        'type': 'video',
        'thumbnailUrl': videoThumbnailUrls.length > i
            ? videoThumbnailUrls[i]
            : videoUrls[i],
        'fullUrl': videoUrls[i],
      });
    }

    // Initialize carousel index for the post if not already
    if (!_currentCarouselIndices.containsKey(postId)) {
      _currentCarouselIndices[postId] = 0;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 4,
      // margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        // Some padding to give breathing room on all screens
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info + Time
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(AppConstants.crapLogo),
              ),
              title: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: Text(
                _formatPostTime(createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            // CHANGED: Show media (images/videos) using CarouselSlider with caching
            if (mediaList.isNotEmpty)
              Column(
                children: [
                  CarouselSlider(
                    items: mediaList.map((media) {
                      if (media['type'] == 'image') {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadePageRouteBuilder(
                                widget: FullScreenView(
                                  url: media['fullUrl']!,
                                  isVideo: false,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                            child: CachedNetworkImage(
                              imageUrl: media['thumbnailUrl']!,
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * 0.3,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                            ),
                          ),
                        );
                      } else if (media['type'] == 'video') {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadePageRouteBuilder(
                                widget: FullScreenView(
                                  url: media['fullUrl']!,
                                  isVideo: true,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: media['thumbnailUrl']!,
                                  fit: BoxFit.cover,
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                  MediaQuery.of(context).size.height * 0.3,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.blueAccent,
                                    size: 60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height * 0.3,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: true,
                      viewportFraction: 1.0, // Added to ensure full visibility

                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentCarouselIndices[postId] = index;
                        });
                      },
                    ),
                  ),
                  // Dot Indicators
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(mediaList.length, (index) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentCarouselIndices[postId] == index
                              ? Colors.blueAccent
                              : Colors.grey,
                        ),
                      );
                    }),
                  ),
                ],
              ),

            // Description
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: "Ubuntu",
                    fontSize: 16,
                  ),
                ),
              ),

            // Like and Comment Row (REPLACED with LikeSectionWidget to see real-time likes)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: LikeSectionWidget(
                      postId: postId,
                      bearerToken: bearerToken,
                      parentState: this,
                    ),
                  ),
                  // Report button
                  InkWell(
                    onTap: () => _showReportDialog(context, postId),
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Comments inside an ExpansionTile with customized divider
            Theme(
              data:
              Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  'View/Add Comments',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                children: [
                  CommentSectionWidget(postId: postId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Report post functionality
  Future<void> _showReportDialog(BuildContext context, String postId) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon and Title
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.report_problem,
                      size: 36,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Report Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontFamily: "Ubuntu",
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Flexible(
                    child: Text(
                      'Are you sure you want to report this post? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.3,
                        fontFamily: "Ubuntu",
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons Row
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.grey.shade700,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "Ubuntu",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Report Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _reportPost(postId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.report, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Report',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "Ubuntu",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle post reporting
  Future<void> _reportPost(String postId) async {
    try {
      final postRef =
      FirebaseFirestore.instance.collection('posts').doc(postId);

      // Use a transaction to safely increment report count and check if it should be deleted
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentReportCount = postDoc.data()?['reportCount'] ?? 0;
        final newReportCount = currentReportCount + 1;

        if (newReportCount >= 1) {
          // Delete the post if report count reaches 1 or more
          transaction.delete(postRef);
        } else {
          // Just increment the report count
          transaction.update(postRef, {'reportCount': newReportCount});
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Success!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: "Ubuntu",
                      ),
                    ),
                    Text(
                      'Post has been reported and removed',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontFamily: "Ubuntu",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
          elevation: 8,
        ),
      );

      // Refresh the posts list to reflect the changes
      await _refreshPosts();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: "Ubuntu",
                      ),
                    ),
                    Text(
                      'Failed to report post. Please try again.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontFamily: "Ubuntu",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
          elevation: 8,
        ),
      );
    }
  }

  /// Like / Unlike logic (updated to prevent spam-tapping and ensure >= 0)
  Future<void> handleLike(
      BuildContext context,
      String postId,
      List likes,
      ) async {
    String? currentUserId = bearerToken;
    if (currentUserId == null) {
      // Optionally, prompt user to log in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like posts.')),
      );
      return;
    }

    // If a like/unlike transaction is already in progress, return
    if (_likeInProgressMap[postId] == true) return;
    _likeInProgressMap[postId] = true;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    // Use a Firestore transaction to handle concurrency and avoid negative counts
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List currentLikes = data['likes'] ?? [];
      final int currentLikesCount = data['likesCount'] ?? 0;

      if (currentLikes.contains(currentUserId)) {
        // Unlike
        final newCount = currentLikesCount > 0 ? currentLikesCount - 1 : 0;
        transaction.update(postRef, {
          'likes': FieldValue.arrayRemove([currentUserId]),
          'likesCount': newCount,
        });
      } else {
        // Like
        transaction.update(postRef, {
          'likes': FieldValue.arrayUnion([currentUserId]),
          'likesCount': currentLikesCount + 1,
        });
      }
    }).whenComplete(() {
      _likeInProgressMap[postId] = false;
    }).catchError((_) {
      _likeInProgressMap[postId] = false;
    });
  }

  /// Add a comment to Firestore
  Future<void> addComment(String postId, String commentText) async {
    if (commentText.isEmpty) return;

    final commentsRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments');

    final token = await getToken();

    await commentsRef.add({
      'userId': token,
      'commentText': commentText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// -------------------------------------------------------------------
// PostItemWidget: REMOVED the original full-post StreamBuilder
// -------------------------------------------------------------------
class PostItemWidget extends StatelessWidget {
  final String postId;
  final String? bearerToken;
  final _SocialMediaHomeViewState parentState;

  // We now also receive static 'postData' from _buildPostList
  final Map<String, dynamic> postData;

  const PostItemWidget({
    Key? key,
    required this.postId,
    required this.bearerToken,
    required this.parentState,
    required this.postData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Instead of streaming the entire post,
    // we simply build the UI with the static postData
    return parentState.buildPostItemUI(context, postData, postId);
  }
}

// -------------------------------------------------------------------
// CommentSectionWidget: Combined real-time + load-more pagination
// -------------------------------------------------------------------
class CommentSectionWidget extends StatefulWidget {
  final String postId;

  const CommentSectionWidget({Key? key, required this.postId})
      : super(key: key);

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  // Pagination state for comments (from the original code)
  final List<DocumentSnapshot> _commentDocs = [];
  DocumentSnapshot? _lastCommentDoc;
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;

  static const int _commentsPageSize = 10;

  final TextEditingController _commentController = TextEditingController();

  // Prevent multiple identical comment submissions if tapped repeatedly
  bool _isAddingComment = false;

  // NEW: Real-time pagination
  int _currentLimit = 10; // Start with 10 comments
  // (We keep _fetchComments(), etc., from the original code,
  // but rely on the stream below for the actual UI display.)

  @override
  void initState() {
    super.initState();
    // We keep the original fetch, but the UI will come from the stream.
    _fetchComments();
  }

  /// Fetch a page of comments (from the original code)
  Future<void> _fetchComments() async {
    if (_isLoadingComments || !_hasMoreComments) return;
    setState(() {
      _isLoadingComments = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(_commentsPageSize);

    if (_lastCommentDoc != null) {
      query = query.startAfterDocument(_lastCommentDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      _lastCommentDoc = snap.docs.last;
      _commentDocs.addAll(snap.docs);
    }

    if (snap.docs.length < _commentsPageSize) {
      _hasMoreComments = false;
    }

    setState(() {
      _isLoadingComments = false;
    });
  }

  /// Adds a new comment
  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // If a comment add is already in progress, do nothing
    if (_isAddingComment) return;
    _isAddingComment = true;

    final token = await getToken();
    final userName = await getUserName();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("fcm_token");

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userName': userName,
      'fcmToken': deviceId,
      'userId': token,
      'commentText': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    // We keep the original refresh to keep everything else consistent
    await _refreshComments();

    // Allow next comment
    _isAddingComment = false;
  }

  /// Refresh from scratch (e.g., after adding a comment)
  Future<void> _refreshComments() async {
    setState(() {
      _commentDocs.clear();
      _lastCommentDoc = null;
      _hasMoreComments = true;
    });
    await _fetchComments();
  }

  /// Increase the limit to load more real-time comments
  void _loadMoreComments() {
    setState(() {
      _currentLimit += 10; // fetch 10 more in the real-time stream
    });
  }

  /// Builds the entire Comments section UI
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Real-time list with pagination limit
        _buildCommentsList(),
        const SizedBox(height: 8),
        // Styled TextField to add comment
        _buildAddCommentField(),
      ],
    );
  }

  /// Real-time + pagination in the same stream
  Widget _buildCommentsList() {
    // Instead of showing `_commentDocs`, we show a StreamBuilder
    // that includes `.limit(_currentLimit)`.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(_currentLimit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('Something went wrong.')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
                child: Text('No comments yet. Be the first to comment!')),
          );
        }

        final commentDocs = snapshot.data!.docs;
        if (commentDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No comments yet. Be the first to comment!'),
          );
        }

        return Column(
          children: [
            // The list of loaded comments
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: commentDocs.length,
              itemBuilder: (context, index) {
                final doc = commentDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final commentText = data['commentText'] ?? '';
                final userName = data['userName'] ?? 'Anonymous';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Avatar or Placeholder
                      const CircleAvatar(
                        radius: 12,
                        backgroundImage:
                        AssetImage('assets/resource_images/user.png'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$userName:'),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  commentText,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // "Load More" or "No more comments"
            _buildLoadMoreCommentsBtn(commentDocs.length),
          ],
        );
      },
    );
  }

  /// Show a load-more button if the count equals the current limit,
  /// otherwise show "No more comments."
  Widget _buildLoadMoreCommentsBtn(int fetchedCount) {
    final noMoreToLoad = fetchedCount < _currentLimit;
    if (noMoreToLoad) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: Text("No more comments.")),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _loadMoreComments,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          child: const Text(
            "Load More Comments",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  /// Styled comment input field with rounded corners and send button
  Widget _buildAddCommentField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              // Slight background color & rounding for the text field
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _addComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// LikeSectionWidget: Streams only 'likes' and 'likesCount' in real time
// with OPTIMISTIC UI updates and NO "setState during build" error
// -------------------------------------------------------------------
class LikeSectionWidget extends StatefulWidget {
  final String postId;
  final String? bearerToken;
  final _SocialMediaHomeViewState parentState;

  const LikeSectionWidget({
    Key? key,
    required this.postId,
    required this.bearerToken,
    required this.parentState,
  }) : super(key: key);

  @override
  _LikeSectionWidgetState createState() => _LikeSectionWidgetState();
}

class _LikeSectionWidgetState extends State<LikeSectionWidget> {
  /// Whether we're currently processing a like/unlike transaction.
  bool _pendingLikeTransaction = false;

  /// Local "isLiked" state, used for optimistic updates.
  bool _isLiked = false;

  /// Local "likesCount" state, used for optimistic updates.
  int _likesCount = 0;

  /// Backup old states in case the transaction fails.
  bool _oldIsLiked = false;
  int _oldLikesCount = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        // If the doc doesn't exist or there's no data, just return nothing.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final postData = snapshot.data!.data() as Map<String, dynamic>;
        final firestoreLikesCount = postData['likesCount'] ?? 0;
        final List firestoreLikes = postData['likes'] ?? [];
        final firestoreIsLiked = firestoreLikes.contains(widget.bearerToken);

        // We’ll display these ephemeral values in the UI,
        // so we don't do setState() *during* the build method.
        bool isLikedForUI = _isLiked;
        int likesCountForUI = _likesCount;

        // If we are NOT in the middle of an optimistic transaction,
        // show the live Firestore data directly.
        if (!_pendingLikeTransaction) {
          isLikedForUI = firestoreIsLiked;
          likesCountForUI = firestoreLikesCount;
        } else {
          // If Firestore now matches our optimistic state, we know the update
          // made it to Firestore, so we can stop ignoring new snapshots.
          final transactionHasArrived = (firestoreIsLiked == _isLiked &&
              firestoreLikesCount == _likesCount);

          if (transactionHasArrived) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _pendingLikeTransaction = false;
              });
            });
          }
        }

        return Row(
          children: [
            // Like button with optimistic update
            InkWell(
              onTap: () async {
                // Prevent double-tapping while transaction is in progress
                if (_pendingLikeTransaction) return;

                // Save old values so we can revert if the transaction fails
                _oldIsLiked = isLikedForUI;
                _oldLikesCount = likesCountForUI;

                // Now do an optimistic update
                setState(() {
                  _pendingLikeTransaction = true;
                  if (isLikedForUI) {
                    _isLiked = false;
                    _likesCount =
                    likesCountForUI > 0 ? (likesCountForUI - 1) : 0;
                  } else {
                    _isLiked = true;
                    _likesCount = likesCountForUI + 1;
                  }
                });

                // Run the Firestore transaction in the background
                try {
                  await widget.parentState.handleLike(
                    context,
                    widget.postId,
                    [], // current likes array not needed
                  );
                  // If success, do nothing: we wait for Firestore’s snapshot
                  // to catch up. Once it does, we set _pendingLikeTransaction
                  // to false in a post-frame callback.
                } catch (e) {
                  // If transaction fails, revert immediately
                  setState(() {
                    _isLiked = _oldIsLiked;
                    _likesCount = _oldLikesCount;
                    _pendingLikeTransaction = false;
                  });
                }
              },
              child: Row(
                children: [
                  Icon(
                    isLikedForUI ? Icons.favorite : Icons.favorite_border,
                    color: isLikedForUI ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(likesCountForUI.toString()),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Comment icon is static
            // Row(
            //   children: const [
            //     Icon(Icons.comment, color: Colors.grey),
            //     SizedBox(width: 4),
            //     Text('Comments'),
            //   ],
            // ),
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------------------
// Modified FullScreenView: Now a StatefulWidget with dynamic aspect ratio
// -------------------------------------------------------------------
class FullScreenView extends StatefulWidget {
  final String url;
  final bool isVideo;

  const FullScreenView({Key? key, required this.url, required this.isVideo})
      : super(key: key);

  @override
  _FullScreenViewState createState() => _FullScreenViewState();
}

class _FullScreenViewState extends State<FullScreenView> {
  late VideoPlayerController _videoController; // Add this declaration
  ChewieController? _chewieController;
  bool _isLoading = true;

  double? _aspectRatio;
  // bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final cachedFile = await DefaultCacheManager().getSingleFile(widget.url);

    try {
      _videoController = VideoPlayerController.file(cachedFile);
      await _videoController.initialize();

      setState(() {
        _aspectRatio = _videoController.value.aspectRatio;
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
        );
        _isLoading = false;
      });
    } catch (e) {
      print("Error initializing video player: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  // @override
  // void initState() {
  //   super.initState();
  //   if (widget.isVideo) {
  //     _fetchVideoMetadata();
  //   }
  // }

  Future<void> _fetchVideoMetadata() async {
    VideoPlayerController controller =
    VideoPlayerController.network(widget.url);
    try {
      await controller.initialize();
      final size = controller.value.size;
      controller.dispose();
      setState(() {
        _aspectRatio = size.width / size.height;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors if any (e.g., network issues)
      controller.dispose();
      setState(() {
        _aspectRatio = 16 / 9; // Fallback aspect ratio
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVideo) {
      if (_isLoading) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      } else {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio!,
              child: Chewie(controller: _chewieController!),
            ),
          ),
        );
      }
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      );
    }
  }
}
