// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/socket_service.dart';
import '../services/navigation_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotification = FlutterLocalNotificationsPlugin();

  bool _isInitializing = false;
  bool _isRequestingPermission = false;
  StreamSubscription? _authSub;
  StreamSubscription? _tokenRefreshSub;

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await initializeLocalNotification();
      await getFirebaseMessagingToken();
      await setupNotificationHandlers();

      // Ensure token is fetched and synced whenever user signs in or restores session
      _authSub?.cancel();
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          getFirebaseMessagingToken();
        }
      });
    } catch (e) {
      // Safe fallback if permission or initialization error occurs
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> getFirebaseMessagingToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_isRequestingPermission) {
      _isRequestingPermission = true;
      try {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {
        // Ignore duplicate permission requests
      } finally {
        _isRequestingPermission = false;
      }
    }

    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
          "fcmToken": token,
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection("Users").doc(currentUser.uid).set({
          "fcmToken": newToken,
        }, SetOptions(merge: true));
      }
    });
  }

  void Function(Map<String, dynamic> callData)? onIncomingCall;

  Future<void> initializeLocalNotification() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotification.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationPayload(response.payload!);
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Chat Notifications',
      description: 'High priority chat message notifications',
      importance: Importance.max,
    );

    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'call_channel',
      'Incoming Calls',
      description: 'High priority incoming call notifications',
      importance: Importance.max,
    );

    final androidPlugin = _localNotification
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(callChannel);
  }

  Future<void> setupNotificationHandlers() async {
    // 1. Foreground Notification Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;

      // Handle incoming call notification
      if (data['type'] == 'incoming_call') {
        onIncomingCall?.call(data);
        await _localNotification.show(
          id: 999999,
          title: message.notification?.title ?? data['callerName'] ?? 'Incoming Call',
          body: message.notification?.body ?? 'Incoming call...',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              "call_channel",
              "Incoming Calls",
              importance: Importance.max,
              priority: Priority.high,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.call,
            ),
          ),
          payload: 'call|${data['callId'] ?? ''}|${data['callerId'] ?? ''}|${data['channelId'] ?? ''}|${data['token'] ?? ''}|${data['callType'] ?? 'audio'}|${data['callerName'] ?? 'Someone'}|${data['callerImageUrl'] ?? ''}',
        );
        return;
      }

      final conversationId = data['conversationId'];

      // If recipient is actively viewing the same chat, suppress foreground banner
      if (conversationId != null && SocketService.instance.activeConversationId == conversationId) {
        return;
      }

      final payloadString = _buildPayloadString(data);

      await _localNotification.show(
        id: message.hashCode,
        title: message.notification?.title ?? data['senderName'] ?? 'New Message',
        body: message.notification?.body ?? 'Sent a message',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            "high_importance_channel",
            "Chat Notifications",
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: payloadString,
      );
    });

    // 2. Background Notification Tap Handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessageData(message.data);
    });

    // 3. Terminated-State Notification Tap Handler
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageData(initialMessage.data);
      }
    } catch (_) {}
  }

  String _buildPayloadString(Map<String, dynamic> data) {
    return [
      data['senderId'] ?? '',
      data['senderName'] ?? '',
      data['senderAvatarUrl'] ?? '',
      data['senderAbout'] ?? '',
      data['senderEmail'] ?? '',
      data['conversationId'] ?? '',
    ].join('|');
  }

  void _handleNotificationPayload(String rawPayload) {
    if (rawPayload.startsWith('call|')) {
      final parts = rawPayload.split('|');
      onIncomingCall?.call({
        'callId': parts.length > 1 ? parts[1] : '',
        'callerId': parts.length > 2 ? parts[2] : '',
        'channelId': parts.length > 3 ? parts[3] : '',
        'token': parts.length > 4 ? parts[4] : '',
        'callType': parts.length > 5 ? parts[5] : 'audio',
        'callerName': parts.length > 6 ? parts[6] : 'Someone',
        'callerImageUrl': parts.length > 7 ? parts[7] : '',
      });
      return;
    }

    final parts = rawPayload.split('|');
    if (parts.length >= 6) {
      NavigationService.navigateToChat(
        userId: parts[0],
        username: parts[1],
        imageUrl: parts[2],
        about: parts[3],
        email: parts[4],
        conversationId: parts[5],
        source: ChatEntrySource.notification,
      );
    }
  }

  void _handleRemoteMessageData(Map<String, dynamic> data) {
    if (data['type'] == 'incoming_call') {
      onIncomingCall?.call(data);
      return;
    }

    final senderId = data['senderId'];
    final conversationId = data['conversationId'];
    if (senderId != null && conversationId != null) {
      NavigationService.navigateToChat(
        userId: senderId,
        username: data['senderName'] ?? 'Chat',
        imageUrl: data['senderAvatarUrl'] ?? '',
        about: data['senderAbout'] ?? '',
        email: data['senderEmail'] ?? '',
        conversationId: conversationId,
        source: ChatEntrySource.notification,
      );
    }
  }
}

