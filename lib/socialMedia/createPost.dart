import 'dart:async'; // For TimeoutException
import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crapadvisor/resource_module/constants/AppConstants.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import '../resource_module/utilities/sharedPrefs.dart';
import 'socialpstview.dart'; // Ensure this import points to your SocialMediaHomeView

class UploadTaskModel {
  final String id;
  final File file;
  final String fileName;
  double progress; // 0.0 to 1.0
  UploadTask? uploadTask;
  bool isCompleted;
  bool isFailed;
  String errorMessage;

  UploadTaskModel({
    required this.id,
    required this.file,
    required this.fileName,
    this.progress = 0.0,
    this.uploadTask,
    this.isCompleted = false,
    this.isFailed = false,
    this.errorMessage = '',
  });
}

/// Model to pair a video with its thumbnail future
class VideoItem {
  final File videoFile;
  final Future<File?> thumbnailFuture;

  VideoItem({required this.videoFile, required this.thumbnailFuture});
}

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _descriptionController = TextEditingController();

  // Lists to hold selected media
  List<XFile> _selectedImages = [];
  List<VideoItem> _videoItems = []; // Unified list for videos and thumbnails

  final ImagePicker _picker = ImagePicker();

  // Flags and variables for upload and compression state and progress
  bool _isUploading = false;
  bool _isCompressing = false;
  bool _isCancelling = false; // Flag for Cancellation
  double _overallProgress = 0.0; // Range from 0.0 to 1.0
  double _compressionProgress = 0.0; // Range from 0.0 to 1.0

  // To track the currently compressing file
  String? _currentCompressingFileName;

  // Status message for compression
  String _statusMessage = "Idle";

  // List to track individual upload tasks
  List<UploadTaskModel> _uploadTasks = [];

  // Variables to track total bytes and bytes transferred
  int _totalBytes = 0;
  int _bytesTransferred = 0;

  // Connectivity
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;

  // Store postId for use in retries
  String? _currentPostId;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _connectivitySubscription.cancel();
    VideoCompress.cancelCompression(); // Cancel any ongoing video compressions
    VideoCompress.dispose();
    // Ensure All Resources Are Canceled on Dispose
    _cancelAllUploads(fromDispose: true);
    super.dispose();
  }

  /// Check the initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  /// Update the connectivity status
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  /// Helper method to map FirebaseException codes to user-friendly messages
  String? getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "You don't have permission to perform this action.";
      case 'unavailable':
        return "Service is currently unavailable. Please try again later.";
      case 'network-request-failed':
        return "Network error. Please check your internet connection.";
      case 'invalid-argument':
        return "Invalid input provided. Please check and try again.";
      case 'deadline-exceeded':
        return "Request timed out. Please try again.";
      case 'already-exists':
        return "The item you're trying to add already exists.";
      case 'not-found':
        return "The requested item was not found.";
      case 'canceled': // Handle 'canceled' Exception
        return null;
      default:
        return "An unexpected error occurred. Please try again.";
    }
  }

  /// Pick multiple images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedImages = await _picker.pickMultiImage();
      if (pickedImages != null) {
        setState(() {
          _selectedImages = pickedImages;
        });
      }
    } on FirebaseException catch (e) {
      String? errorMessage = getFirebaseErrorMessage(e);
      if (errorMessage != null) {
        // Only show if not canceled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      // If e.code == 'canceled', do not show any SnackBar here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("An unexpected error occurred while picking images.")),
      );
    }
  }

  /// Pick multiple videos from gallery using FilePicker
  Future<void> _pickVideos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();
        setState(() {
          for (var file in files) {
            _videoItems.add(
              VideoItem(
                videoFile: file,
                thumbnailFuture: VideoCompress.getFileThumbnail(
                  file.path,
                  quality: 50, // Adjust quality as needed
                  position: -1, // -1 to get the first frame
                ),
              ),
            );
          }
        });
      }
    } on FirebaseException catch (e) {
      String? errorMessage = getFirebaseErrorMessage(e);
      if (errorMessage != null) {
        // Only show if not canceled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      // If e.code == 'canceled', do not show any SnackBar here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("An unexpected error occurred while picking videos.")),
      );
    }
  }

  /// Compress an image dynamically by adjusting `quality` based on file size
  Future<File> _compressImage(File file) async {
    int minQuality = 30;
    int maxQuality = 90;
    int step = 10;
    int currentQuality = maxQuality;
    int targetSizeInBytes = 500 * 1024; // 500 KB

    final Directory tempDir = await getTemporaryDirectory();
    String targetPath = '${tempDir.path}/${Uuid().v4()}.jpg';

    File? compressedFile;
    bool isCompressed = false;

    while (currentQuality >= minQuality && !isCompressed) {
      List<int>? compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: currentQuality,
      );

      if (compressedBytes == null) {
        throw Exception("Image compression failed.");
      }

      if (compressedBytes.length <= targetSizeInBytes ||
          currentQuality == minQuality) {
        compressedFile = File(targetPath)..writeAsBytesSync(compressedBytes);
        isCompressed = true;
      } else {
        currentQuality -= step;
      }
    }

    return compressedFile!;
  }

  /// Generate a thumbnail for an image by resizing it
  Future<File> _generateImageThumbnail(File file) async {
    final Directory tempDir = await getTemporaryDirectory();
    String thumbPath = '${tempDir.path}/${Uuid().v4()}_thumb.jpg';

    List<int>? thumbBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 200,
      minHeight: 200,
      quality: 100,
    );

    if (thumbBytes == null) {
      throw Exception("Image thumbnail generation failed.");
    }

    return File(thumbPath)..writeAsBytesSync(thumbBytes);
  }

  Future<File> _compressVideo(File file) async {
    final Directory tempDir = await getTemporaryDirectory();
    String outputPath = '${tempDir.path}/${Uuid().v4()}.mp4';

    // Get video metadata
    MediaInfo? info = await VideoCompress.getMediaInfo(file.path);
    double duration = info?.duration != null
        ? info!.duration! / 1000
        : 1.0; // Duration in seconds
    int videoWidth = info?.width ?? 0;
    int videoHeight = info?.height ?? 0;

    Completer<File> completer = Completer<File>();

    try {
      // Start compression with video_compress
      MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.LowQuality, // Set quality to your preference
        deleteOrigin: false, // Retain original video
        includeAudio: true,
      );

      if (compressedVideo != null && compressedVideo.path != null) {
        File compressedFile = File(compressedVideo.path!);

        // Start tracking progress
        int startTime = DateTime.now().millisecondsSinceEpoch;

        Timer.periodic(Duration(seconds: 1), (timer) async {
          int currentTime = DateTime.now().millisecondsSinceEpoch;
          double elapsedTime =
              (currentTime - startTime) / 1000; // Elapsed time in seconds

          if (elapsedTime < duration) {
            double progress =
                elapsedTime / duration; // Calculate progress based on duration

            if (mounted) {
              setState(() {
                _compressionProgress = progress;
                _statusMessage =
                    "Compressing... ${(progress * 100).toStringAsFixed(0)}%";
              });
            }
          } else {
            timer.cancel(); // Stop the timer once compression is finished

            if (mounted) {
              setState(() {
                _compressionProgress = 1.0; // Set progress to 100% when done
                _statusMessage = "Compression Complete!";
              });
              completer.complete(compressedFile);
            }
          }
        });
      } else {
        if (mounted) {
          completer.completeError(Exception("Video compression failed."));
        } else {
          completer.completeError(
              Exception("Widget disposed before compression completed."));
        }
      }
    } catch (e) {
      if (mounted) {
        completer.completeError(Exception("Video compression failed: $e"));
      } else {
        completer.completeError(
            Exception("Widget disposed before compression completed."));
      }
    }

    return completer.future;
  }

  /// Compress a video using FFmpegKit with progress callbacks
  // Future<File> _compressVideo(File file) async {
  //   final Directory tempDir = await getTemporaryDirectory();
  //   String outputPath = '${tempDir.path}/${Uuid().v4()}.mp4';
  //
  //   // Get video duration using video_compress package
  //   MediaInfo? info = await VideoCompress.getMediaInfo(file.path);
  //   double duration = info.duration != null ? info.duration! / 1000 : 1.0; // in seconds
  //
  //   // FFmpeg command for compression with 'ultrafast' preset
  //   final String command =
  //       '-i "${file.path}" -vcodec libx264 -preset ultrafast -crf 28 -acodec aac -b:a 128k "$outputPath"';
  //
  //   Completer<File> completer = Completer<File>();
  //
  //   FFmpegKit.executeAsync(
  //     command,
  //         (session) async {
  //       // Execution completed
  //       final returnCode = await session.getReturnCode();
  //       if (ReturnCode.isSuccess(returnCode)) {
  //         File compressedFile = File(outputPath);
  //         if (await compressedFile.exists()) {
  //           if (mounted) {
  //             completer.complete(compressedFile);
  //           } else {
  //             completer.completeError(Exception("Widget disposed before compression completed."));
  //           }
  //         } else {
  //           if (mounted) {
  //             completer.completeError(Exception("Compressed video file does not exist."));
  //           } else {
  //             completer.completeError(Exception("Widget disposed before compression completed."));
  //           }
  //         }
  //       } else {
  //         if (mounted) {
  //           completer.completeError(Exception("Video compression failed with return code: $returnCode"));
  //         } else {
  //           completer.completeError(Exception("Widget disposed before compression completed."));
  //         }
  //       }
  //     },
  //         (log) {
  //       // Log callback (optional)
  //       debugPrint("FFmpeg Log: ${log.getMessage()}");
  //     },
  //         (statistics) {
  //       // Statistics callback for progress
  //       int? time = statistics.getTime(); // Fixed: Use int instead of double
  //
  //       if (time != null && duration > 0) {
  //         double progress = (time / (duration * 1000));
  //         if (progress.isFinite && progress <= 1.0 && mounted) {
  //           setState(() {
  //             _compressionProgress = progress;
  //             _statusMessage = "Compressing... ${(progress * 100).toStringAsFixed(0)}%";
  //           });
  //         }
  //       }
  //     },
  //     //     (statistics) {
  //     //   // Statistics callback for progress
  //     //   double? time = statistics.getTime(); // Current time in milliseconds
  //     //
  //     //   if (time != null && duration > 0) {
  //     //     double progress = (time / (duration * 1000)); // Convert duration to milliseconds
  //     //     if (progress.isFinite && progress <= 1.0 && mounted) {
  //     //       setState(() {
  //     //         _compressionProgress = progress;
  //     //         _statusMessage = "Compressing... ${(progress * 100).toStringAsFixed(0)}%";
  //     //       });
  //     //     }
  //     //   }
  //     // },
  //   );
  //
  //   return completer.future;
  // }

  /// Helper method to delete temporary compressed files
  Future<void> _deleteTempFiles(List<UploadTaskModel> tasks) async {
    for (UploadTaskModel task in tasks) {
      try {
        if (await task.file.exists()) {
          await task.file.delete();
          debugPrint("Deleted temp file: ${task.file.path}");
        }
      } catch (e) {
        debugPrint("Failed to delete temp file ${task.file.path}: $e");
        // Optionally, you can inform the user or handle the error as needed.
      }
    }
  }

  /// Initialize and start uploading all selected files
  Future<void> _uploadPost() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No internet connection. Please try again later.")),
      );
      return;
    }

    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.0;
      _isUploading = false;
      _overallProgress = 0.0;
      _bytesTransferred = 0;
      _isCancelling = false; // Ensure cancellation flag is reset
      _uploadTasks = [];
      _currentCompressingFileName = null;
    });

    try {
      if (_selectedImages.isEmpty && _videoItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No images or videos selected.")),
        );
        setState(() {
          _isCompressing = false;
        });
        return;
      }

      final String? bearerToken = await getToken();
      final String? userName = await getUserName();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString("fcm_token");

      // Generate a post ID
      final String postId = const Uuid().v4();
      _currentPostId = postId; // Store for retry

      // Prepare lists for the download URLs
      List<String> imageUrls = [];
      List<String> videoUrls = [];
      List<String> videoThumbnailUrls = []; // New List for Video Thumbnails
      List<String> imageThumbnailUrls = []; // New List for Image Thumbnails

      // Calculate total number of files to compress
      int totalFilesToCompress = _selectedImages.length + _videoItems.length;
      int filesCompressed = 0;

      // Initialize UploadTaskModel for each file
      List<UploadTaskModel> tasks = [];

      // Compress and add image tasks
      for (XFile image in _selectedImages) {
        if (!mounted) break; // Exit if widget is no longer mounted
        setState(() {
          _currentCompressingFileName = 'Compressing Image: ${image.name}';
        });
        debugPrint('Starting compression for image: ${image.name}');
        final File originalFile = File(image.path);
        final File compressedFile = await _compressImage(originalFile);
        debugPrint('Completed compression for image: ${image.name}');
        final String fileName =
            'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        tasks.add(UploadTaskModel(
          id: Uuid().v4(),
          file: compressedFile,
          fileName: fileName,
        ));
        filesCompressed++;
        setState(() {
          _compressionProgress = filesCompressed / totalFilesToCompress;
          _currentCompressingFileName = null;
        });
        debugPrint(
            'Compression Progress: ${(_compressionProgress * 100).toStringAsFixed(0)}%');

        // Generate and Add Thumbnail for Each Image
        final File thumbnail = await _generateImageThumbnail(compressedFile);
        final String thumbFileName =
            'thumb_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        tasks.add(UploadTaskModel(
          id: Uuid().v4(),
          file: thumbnail,
          fileName: thumbFileName,
        ));
        debugPrint('Added thumbnail task: $thumbFileName');
      }

      // Compress and add video tasks
      for (VideoItem videoItem in _videoItems) {
        if (!mounted) break; // Exit if widget is no longer mounted
        setState(() {
          _currentCompressingFileName =
              'Compressing Video: ${videoItem.videoFile.path.split('/').last}';
        });
        debugPrint(
            'Starting compression for video: ${videoItem.videoFile.path.split('/').last}');
        final File compressedVideoFile =
            await _compressVideo(videoItem.videoFile);
        debugPrint(
            'Completed compression for video: ${videoItem.videoFile.path.split('/').last}');
        final String fileName =
            'vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
        tasks.add(UploadTaskModel(
          id: Uuid().v4(),
          file: compressedVideoFile,
          fileName: fileName,
        ));
        filesCompressed++;
        setState(() {
          _compressionProgress = filesCompressed / totalFilesToCompress;
          _currentCompressingFileName = null;
        });
        debugPrint(
            'Compression Progress: ${(_compressionProgress * 100).toStringAsFixed(0)}%');

        // Generate and Add Thumbnail for Each Video
        final File? thumbnail = await VideoCompress.getFileThumbnail(
          compressedVideoFile.path,
          quality: 100, // Adjust quality as needed
          position: -1, // -1 to get the first frame
        );

        if (thumbnail != null) {
          final String thumbFileName =
              'thumb_vid_${DateTime.now().millisecondsSinceEpoch}.jpg';
          tasks.add(UploadTaskModel(
            id: Uuid().v4(),
            file: thumbnail,
            fileName: thumbFileName,
          ));
          debugPrint('Added thumbnail task: $thumbFileName');
        }
      }

      setState(() {
        _uploadTasks = tasks;
        _isCompressing = false;
        _isUploading = true;
      });

      // Calculate total number of bytes to upload
      _totalBytes = 0;
      for (UploadTaskModel task in _uploadTasks) {
        _totalBytes += await task.file.length();
      }

      // Edge case: If totalBytes is 0, avoid division by zero
      if (_totalBytes == 0) {
        _totalBytes = 1;
      }

      // Start uploading each file
      for (UploadTaskModel task in _uploadTasks) {
        _startUpload(task, postId);
      }

      // Wait for all uploads to complete
      await Future.wait(
          _uploadTasks.map((task) => task.uploadTask!.whenComplete(() {})));

      // Check for any failed uploads
      bool hasFailures = _uploadTasks.any((task) => task.isFailed);
      if (hasFailures) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Some files failed to upload. Please retry uploading.")),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Collect download URLs
      imageUrls = await Future.wait(_uploadTasks
          .where((task) => task.fileName.startsWith('img_'))
          .map((task) async {
        String downloadUrl = await _getDownloadURL(task, postId);
        return downloadUrl;
      }));

      videoUrls = await Future.wait(_uploadTasks
          .where((task) => task.fileName.startsWith('vid_'))
          .map((task) async {
        String downloadUrl = await _getDownloadURL(task, postId);
        return downloadUrl;
      }));

      // Collect Video Thumbnail URLs
      videoThumbnailUrls = await Future.wait(_uploadTasks
          .where((task) => task.fileName.startsWith('thumb_vid_'))
          .map((task) async {
        String downloadUrl = await _getDownloadURL(task, postId);
        return downloadUrl;
      }));

      // Collect Image Thumbnail URLs
      imageThumbnailUrls = await Future.wait(_uploadTasks
          .where((task) => task.fileName.startsWith('thumb_img_'))
          .map((task) async {
        String downloadUrl = await _getDownloadURL(task, postId);
        return downloadUrl;
      }));

      // Store post metadata in Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'userId': bearerToken,
        'fcmToken': deviceId,
        'description': _descriptionController.text.trim(),
        'imageUrls': imageUrls,
        'imageThumbnailUrls': imageThumbnailUrls, // Added Image Thumbnails URLs
        'videoUrls': videoUrls,
        'videoThumbnailUrls': videoThumbnailUrls, // Added Video Thumbnails URLs
        'createdAt': FieldValue.serverTimestamp(),
        'userName': userName,
        'likesCount': 0,
        'likes': [],
      }).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException(
            "The connection has timed out. Please try again!");
      });

      // Delete temporary compressed files after successful upload
      await _deleteTempFiles(_uploadTasks);

      // Clear fields after upload
      _descriptionController.clear();
      setState(() {
        _selectedImages.clear();
        _videoItems.clear(); // Clear video items after successful upload
        _uploadTasks.clear();
        _overallProgress = 1.0;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevents dialog from closing on tap outside
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Success"),
            content: const Text("Your post has been uploaded successfully!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(true);
                  // Navigator.of(context).pushReplacement(
                  //   MaterialPageRoute(
                  //     builder: (context) => SocialMediaHomeView(),
                  //   ),
                  // );
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } on FirebaseException catch (e) {
      String? errorMessage = getFirebaseErrorMessage(e);
      if (errorMessage != null) {
        // Only show if not canceled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      // If e.code == 'canceled', do not show any SnackBar here
    } on TimeoutException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? "Request timed out. Please try again.")),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e'); // or print(e)
      // Handle any other exceptions
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //       content:
      //       Text("An unexpected error occurred. Please try again.")),
      // );
    } finally {
      if (mounted) {
        // Check if mounted before calling setState
        setState(() {
          _isCompressing = false;
          _isUploading = false;
          _currentCompressingFileName = null;
        });
      }
    }
  }

  /// Start uploading a single file
  void _startUpload(UploadTaskModel task, String postId) {
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(postId)
        .child(task.fileName);

    final UploadTask uploadTask = storageRef.putFile(task.file);

    // Immediate Assignment of uploadTask
    task.uploadTask = uploadTask;

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (_isCancelling) return; // Skip updates if cancelling

      if (snapshot.state == TaskState.running) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() {
            task.progress = progress;
            _updateOverallProgress();
          });
        }
      } else if (snapshot.state == TaskState.success) {
        if (mounted) {
          setState(() {
            task.isCompleted = true;
            task.progress = 1.0;
            _updateOverallProgress();
          });
        }
      } else if (snapshot.state == TaskState.error ||
          snapshot.state == TaskState.canceled) {
        if (mounted) {
          setState(() {
            task.isFailed = true;
            task.errorMessage = snapshot.state == TaskState.canceled
                ? "Upload canceled."
                : "Upload failed.";
            _updateOverallProgress();
          });
        }
      }
    }, onError: (e) {
      if (_isCancelling) return; // Skip error handling if cancelling
      if (mounted) {
        setState(() {
          task.isFailed = true;
          task.errorMessage = "An error occurred during upload.";
          _updateOverallProgress();
        });
      }
    });
  }

  /// Update overall upload progress based on individual task progresses
  void _updateOverallProgress() {
    double total = 0.0;
    for (UploadTaskModel task in _uploadTasks) {
      total += task.progress;
    }
    setState(() {
      _overallProgress =
          _uploadTasks.isNotEmpty ? total / _uploadTasks.length : 0.0;
    });
  }

  /// Get download URL for a completed upload task
  Future<String> _getDownloadURL(UploadTaskModel task, String postId) async {
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(postId)
        .child(task.fileName);
    return await storageRef.getDownloadURL();
  }

  /// Retry uploading a failed task
  Future<void> _retryUpload(UploadTaskModel task, String postId) async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No internet connection. Please try again later.")),
      );
      return;
    }

    setState(() {
      task.isFailed = false;
      task.errorMessage = '';
      task.progress = 0.0;
    });
    _startUpload(task, postId);
  }

  /// Cancel an ongoing upload task
  Future<void> _cancelUpload(UploadTaskModel task) async {
    await task.uploadTask?.cancel();
  }

  /// Cancel all ongoing uploads and release resources
  Future<void> _cancelAllUploads({bool fromDispose = false}) async {
    if (_isCancelling) return; // Prevent multiple cancellation attempts

    // Only call setState if not called from dispose and widget is mounted
    if (!fromDispose && mounted) {
      setState(() {
        _isCancelling = true; // Set cancellation flag
      });
    }

    try {
      // Cancel all upload tasks concurrently
      List<Future<void>> cancelFutures = _uploadTasks.map((task) async {
        if (task.uploadTask != null) {
          try {
            await task.uploadTask!.cancel();
            debugPrint('Canceled upload task: ${task.fileName}');
          } catch (e) {
            debugPrint(
                'Failed to cancel upload task: ${task.fileName}, Error: $e');
          }
        }
      }).toList();

      await Future.wait(cancelFutures);


      // Cancel any ongoing video compression via VideoCompress package
      await VideoCompress.cancelCompression();

      // Optionally, delete temporary compressed files
      await _deleteTempFiles(_uploadTasks);
    } catch (e) {
      debugPrint('Error during cancellation: $e');
    } finally {
      if (!fromDispose && mounted) {
        // Only setState if not called from dispose and still mounted
        setState(() {
          _isUploading = false;
          _isCompressing = false;
          _uploadTasks.clear(); // Clear only after all cancellations
          _videoItems.clear(); // Clear video items
          _overallProgress = 0.0;
          _bytesTransferred = 0;
          _compressionProgress = 0.0;
          _currentCompressingFileName = null;
          _isCancelling = false; // Reset cancellation flag
        });

        // Inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploads have been canceled.")),
        );
      }
    }
  }

  bool _agreedToTerms = false;

  /// Handles the back navigation action.
  /// Returns `true` if the navigation should proceed, otherwise `false`.
  Future<bool> _handleBackAction() async {
    if (_isUploading || _isCompressing) {
      // Prompt the user to confirm cancellation
      bool? shouldCancel = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Cancel Upload"),
          content: const Text("Are you sure you want to cancel the upload?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes"),
            ),
          ],
        ),
      );

      if (shouldCancel == true) {
        await _cancelAllUploads();
        return true; // Allow navigation
      } else {
        return false; // Prevent navigation
      }
    }
    return true; // Allow navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackAction,
      child: Scaffold(
        // Use a Stack to place the background image and the content
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: SvgPicture.asset(
                AppConstants.homeBG,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  title: const Text(
                    "Create Post",
                    style: TextStyle(
                      color: Colors.black,
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
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () async {
                          bool shouldPop = await _handleBackAction();
                          if (shouldPop) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      // Optional: Add spacing between the back button and avatar
                      const SizedBox(width: 8),
                      GestureDetector(
                        child: CircleAvatar(
                          backgroundImage: AssetImage(
                            AppConstants.crapLogo,
                          ),
                          radius: 16, // Adjust the size as needed
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Display connectivity status
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: _isConnected ? Colors.white : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content with SafeArea to avoid notches and system UI
            Positioned.fill(
              top: kToolbarHeight + 60, // Adjusted to account for AppBar height
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description Input Field
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Ubuntu",
                            fontSize: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: "Ubuntu",
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons Row: Pick Images, Pick Videos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Pick Images Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isUploading || _isCompressing || !_isConnected
                                    ? null
                                    : _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Pick Images"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.blueAccent, // Button color
                              foregroundColor: Colors.white, // Text/icon color
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pick Videos Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isUploading || _isCompressing || !_isConnected
                                    ? null
                                    : _pickVideos,
                            icon: const Icon(Icons.videocam),
                            label: const Text("Pick Videos"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                          ),
                          Flexible(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontFamily: "Ubuntu",
                                ),
                                children: [
                                  const TextSpan(text: "I agree to the "),
                                  TextSpan(
                                      text: "Terms of Use (EULA)",
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .black, // ✅ clickable text white too
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final Uri url = Uri.parse(
                                              "https://crapadvisor.semicolonstech.com/privacy.html");
                                          if (!await launchUrl(
                                            url,
                                            mode:
                                                LaunchMode.externalApplication,
                                          )) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Could not open Terms of Use link.")),
                                            );
                                          }
                                        }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Post Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ||
                                _isCompressing ||
                                !_isConnected
                            ? null
                            : () {
                                if (!_agreedToTerms) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "You must agree to the Terms of Use (EULA) before uploading."),
                                    ),
                                  );
                                  return;
                                }
                                _uploadPost();
                              },
                        child: _isUploading || _isCompressing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(_isCompressing
                                      ? "Compressing..."
                                      : "Uploading..."),
                                ],
                              )
                            : const Text("Upload Post"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Display Selected Images with Delete Option
                    if (_selectedImages.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selected Images:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin:
                                          const EdgeInsets.only(right: 12.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        child: Image.file(
                                          File(_selectedImages[index].path),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // Delete Icon
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: _isUploading || _isCompressing
                                            ? null
                                            : () {
                                                setState(() {
                                                  _selectedImages
                                                      .removeAt(index);
                                                });
                                              },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Display Selected Video(s) with Delete Option
                    if (_videoItems.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selected Videos:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _videoItems.length,
                              itemBuilder: (context, index) {
                                final videoItem = _videoItems[index];
                                return Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      margin:
                                          const EdgeInsets.only(right: 12.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Use cached thumbnail future
                                            FutureBuilder<File?>(
                                              future: videoItem.thumbnailFuture,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                                if (snapshot.hasError ||
                                                    !snapshot.hasData) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.videocam,
                                                      size: 50,
                                                      color: Colors.redAccent,
                                                    ),
                                                  );
                                                }
                                                return Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.file(
                                                      snapshot.data!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    const Center(
                                                      child: Icon(
                                                        Icons.play_circle_fill,
                                                        color: Colors.white70,
                                                        size: 50,
                                                      ),
                                                    ),
                                                    // Overlay Progress Indicator
                                                    if (_isUploading ||
                                                        _isCompressing)
                                                      Positioned(
                                                        bottom: 8,
                                                        right: 8,
                                                        child: SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Delete Icon
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: _isUploading || _isCompressing
                                            ? null
                                            : () {
                                                setState(() {
                                                  _videoItems.removeAt(index);
                                                });
                                              },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Display Compression and Upload Progress
                    if (_isCompressing || _uploadTasks.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compression Progress
                          if (_isCompressing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_currentCompressingFileName != null)
                                  Text(
                                    _currentCompressingFileName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _compressionProgress,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.lightBlue,
                                  minHeight: 8.0,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Compression Progress: ${(_compressionProgress * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Uncomment the following section if you want to display individual upload progress
                          /*
                          if (_uploadTasks.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Upload Progress:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _uploadTasks.length,
                                  itemBuilder: (context, index) {
                                    final task = _uploadTasks[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    task.fileName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (!task.isCompleted &&
                                                    !task.isFailed)
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      _cancelUpload(task);
                                                    },
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value: task.progress,
                                              backgroundColor: Colors.grey[300],
                                              color: task.isFailed
                                                  ? Colors.red
                                                  : Colors.blueAccent,
                                              minHeight: 8.0,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${(task.progress * 100).toStringAsFixed(0)}%",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: task.isFailed
                                                        ? Colors.red
                                                        : Colors.black,
                                                  ),
                                                ),
                                                if (task.isFailed)
                                                  TextButton(
                                                    onPressed: () {
                                                      if (_currentPostId != null) {
                                                        _retryUpload(
                                                            task,
                                                            _currentPostId!);
                                                      }
                                                    },
                                                    child: const Text(
                                                      "Retry",
                                                      style: TextStyle(
                                                          color: Colors.blue),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (task.isFailed)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 8.0),
                                                child: Text(
                                                  task.errorMessage,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Overall Progress Indicator
                                LinearProgressIndicator(
                                  value: _overallProgress,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.green,
                                  minHeight: 8.0,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Overall Progress: ${(_overallProgress * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          */
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Uploading Overlay with Cancel Button
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 32.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              "Uploading... ${(_overallProgress * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isCancelling
                                  ? null
                                  : _cancelAllUploads, // Disable if already cancelling
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 12.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text("Cancel Upload"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
