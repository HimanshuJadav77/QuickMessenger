import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode, WidgetsFlutterBinding;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/services/navigation_service.dart';
import 'package:quick_messenger/core/services/notification_service.dart';
import 'package:quick_messenger/core/services/socket_service.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/theme_provider.dart';
import 'package:quick_messenger/features/splash/screens/splash_screen.dart';
import 'package:quick_messenger/features/chat/widgets/incoming_call_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final data = message.data;
  if (data['type'] == 'incoming_call') {
    final localNotification = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await localNotification.initialize(settings: initSettings);

    const callChannel = AndroidNotificationChannel(
      'call_channel',
      'Incoming Calls',
      description: 'High priority incoming call notifications',
      importance: Importance.max,
    );
    final androidPlugin = localNotification
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(callChannel);

    final callerName = data['callerName'] ?? 'Someone';
    final callType = data['callType'] ?? 'voice';

    await localNotification.show(
      id: 999999,
      title: 'Incoming $callType call',
      body: '$callerName is calling...',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'call_channel',
          'Incoming Calls',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
        ),
      ),
      payload: 'call|${data['callId'] ?? ''}|${data['callerId'] ?? ''}|${data['channelId'] ?? ''}|${data['token'] ?? ''}|${data['callType'] ?? 'voice'}|${data['callerName'] ?? 'Someone'}|${data['callerImageUrl'] ?? ''}',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();

  // Manage socket connection lifecycle based on Firebase authentication
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      SocketService.instance.connect();
    } else {
      SocketService.instance.disconnect();
    }
  });

  runApp(const ProviderScope(child: QuickMessenger()));
}


/// iOS-first app shell: CupertinoApp wired to Riverpod theme state.
/// - ThemeMode (system/light/dark) + user accent flow from [themeStateProvider]
/// - No hardcoded seed color; scaffold + primary derive from tokens.
class QuickMessenger extends ConsumerWidget {
  const QuickMessenger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateProvider);
    final accent = themeState.accentColor;

    // Resolve actual brightness for Cupertino (system follows platform).
    final platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = switch (themeState.mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

    return CupertinoApp(
      navigatorKey: NavigationService.navigatorKey,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const IncomingCallDialog(),
          ],
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'QuickMessenger',
      theme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: accent,
        scaffoldBackgroundColor: AppColors.background(isDark),
        barBackgroundColor:
            AppColors.glassFill(isDark).withValues(alpha: 0.85),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.textPrimary(isDark),
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: AppColors.textPrimary(isDark),
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: '.SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppColors.textPrimary(isDark),
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: '.SF Pro Display',
            fontWeight: FontWeight.w700,
            fontSize: 34,
            letterSpacing: -0.5,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // CupertinoPageScaffold keeps nav-bar blur + safe-area correct.
          return CupertinoPageScaffold(
            backgroundColor: AppColors.background(isDark),
            child: Splash(snapshot: snapshot),
          );
        },
      ),
    );
  }
}