import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crapadvisor/resource_module/HomeView.dart';
import 'package:crapadvisor/resource_module/appSelectionView.dart';
import 'package:crapadvisor/resource_module/providers/eventsProvider.dart';
import 'package:crapadvisor/resource_module/providers/festivalProvider.dart';
import 'package:crapadvisor/resource_module/providers/newsProvider.dart';
import 'package:crapadvisor/resource_module/providers/performanceProvider.dart';
import 'package:crapadvisor/resource_module/providers/toiletProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'resource_module/providers/activitesProvider.dart';
import 'resource_module/utilities/sharedPrefs.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
RemoteMessage? _pendingNotificationMessage;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    print('Message contains a notification payload. System will display it.');
  }
}

Future<void> _showNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    styleInformation: BigPictureStyleInformation(
      DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    ),
  );

  const notificationDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
      0, title, body, notificationDetails,
      payload: 'deep_link_home');
}

Future<void> _navigateByLoginState() async {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  final isLoggedIn = (await getIsLogedIn()) ?? false;
  final destination = isLoggedIn ? HomeView() : AppSelectionView();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}

/// Save FCM token locally & to Firestore
Future<void> _saveFcmTokenToServer(String? token) async {
  if (token == null) return;
  print('testtoken ${token}');

  await saveTokenToPrefs(token);

  final userId = FirebaseAuth.instance.currentUser?.uid;
  print("userId ${userId}");
  if (userId != null) {
    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "fcmToken": token,
    });
    print("✅ FCM token saved for user $userId");
  } else {
    print("⚠️ No logged-in user, skipped saving FCM token");
  }
}

Future<void> initializeLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final iosSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
    onDidReceiveLocalNotification: (id, title, body, payload) async {
      if (payload != null) _navigateByLoginState();
    },
  );
  final linuxSettings = LinuxInitializationSettings(
    defaultActionName: 'Open notification',
  );

  final settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
    linux: linuxSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) async {
      if (response.payload != null && response.payload!.isNotEmpty) {
        _navigateByLoginState();
      }
    },
  );
}

Future<void> initializeFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  if (Platform.isAndroid) {
    await messaging.setAutoInitEnabled(true);
  }

  if (Platform.isIOS) {
    final apnsToken = await messaging.getAPNSToken();
    if (apnsToken != null) {
      print("📱 APNS token ready: $apnsToken");
    }
  }

  final fcmToken = await messaging.getToken();
  print("🔑 Initial FCM token: $fcmToken");
  await _saveFcmTokenToServer(fcmToken);

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("♻️ FCM Token refreshed: $newToken");
    await _saveFcmTokenToServer(newToken);
  });

  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification != null) {
      _showNotification(
          notification.title ?? "No Title", notification.body ?? "No Body");
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((_) => _navigateByLoginState());

  _pendingNotificationMessage =
      await FirebaseMessaging.instance.getInitialMessage();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeLocalNotifications();
  await initializeFCM();

  // UI setup
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => BulletinProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ToiletProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingNotificationMessage != null) {
        _pendingNotificationMessage = null;
        _navigateByLoginState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Crap Adviser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AppSelectionView(),
    );
  }
}
