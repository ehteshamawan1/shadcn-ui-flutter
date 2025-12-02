import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Service for handling Firebase Cloud Messaging push notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  // Listeners for token changes and messages
  final List<Function(String)> _tokenListeners = [];
  final List<Function(RemoteMessage)> _messageListeners = [];

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase (may already be initialized)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // Initialize local notifications for foreground messages
        await _initializeLocalNotifications();

        // Get FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('[FCM] Token refreshed');
          _fcmToken = newToken;
          _notifyTokenListeners(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle message taps when app is in background/terminated
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

        // Check for initial message (app opened from notification)
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageTap(initialMessage);
        }

        _initialized = true;
        debugPrint('[FCM] Push notification service initialized');
      } else {
        debugPrint('[FCM] Notifications not authorized');
      }
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Initialize local notifications for showing foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'ska_dan_messages',
      'Beskeder',
      description: 'Notifikationer for nye beskeder',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Get FCM token and save it
  Future<void> _getAndSaveToken() async {
    try {
      // For web, we need to pass the VAPID key
      if (kIsWeb) {
        _fcmToken = await _messaging.getToken(
          vapidKey: 'BNaWRxx1pubdHYBF_VyKjapqCJWetqMdbBKzZq1uLlH34N1uppIKsc2w3JPDN9KZfBSrykY92rl2J88mCGkKkI8',
        );
      } else {
        _fcmToken = await _messaging.getToken();
      }

      debugPrint('[FCM] Token: $_fcmToken');

      if (_fcmToken != null) {
        _notifyTokenListeners(_fcmToken!);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    // Show local notification
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'SKA-DAN',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ska_dan_messages',
            'Beskeder',
            channelDescription: 'Notifikationer for nye beskeder',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['sagId'],
      );
    }

    // Notify listeners
    for (var listener in _messageListeners) {
      listener(message);
    }
  }

  /// Handle message tap (app opened from notification)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('[FCM] Message tap: ${message.data}');

    // Notify listeners for navigation
    for (var listener in _messageListeners) {
      listener(message);
    }
  }

  /// Add listener for token changes
  void addTokenListener(Function(String) listener) {
    _tokenListeners.add(listener);
    // Immediately call with current token if available
    if (_fcmToken != null) {
      listener(_fcmToken!);
    }
  }

  /// Remove token listener
  void removeTokenListener(Function(String) listener) {
    _tokenListeners.remove(listener);
  }

  /// Add listener for incoming messages
  void addMessageListener(Function(RemoteMessage) listener) {
    _messageListeners.add(listener);
  }

  /// Remove message listener
  void removeMessageListener(Function(RemoteMessage) listener) {
    _messageListeners.remove(listener);
  }

  /// Notify all token listeners
  void _notifyTokenListeners(String token) {
    for (var listener in _tokenListeners) {
      listener(token);
    }
  }

  /// Subscribe to a topic (e.g., for all employees or specific sag)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (e.g., on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] Token deleted');
    } catch (e) {
      debugPrint('[FCM] Error deleting token: $e');
    }
  }
}
