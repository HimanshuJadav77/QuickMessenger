import 'package:flutter/cupertino.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/main_navigation_screen.dart';

enum ChatEntrySource {
  home,
  notification,
  search,
  profile,
  deepLink,
  other,
}

class NavigationService {
  NavigationService._();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> navigateToChat({
    required String userId,
    required String username,
    required String imageUrl,
    String about = '',
    String email = '',
    required String conversationId,
    ChatEntrySource source = ChatEntrySource.notification,
  }) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // Navigator not ready yet (e.g. cold-start from notification) -> retry shortly
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToChat(
          userId: userId,
          username: username,
          imageUrl: imageUrl,
          about: about,
          email: email,
          conversationId: conversationId,
          source: source,
        );
      });
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Avoid pushing duplicate ChatScreen if already viewing this conversation
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && modalRoute.settings.name == '/chat_$conversationId') {
      return;
    }

    nav.push(
      CupertinoPageRoute(
        settings: RouteSettings(name: '/chat_$conversationId'),
        builder: (_) => ChatScreen(
          participantId: userId,
          participantName: username,
          participantImageUrl: imageUrl,
          participantAbout: about,
          participantEmail: email,
        ),
      ),
    );
  }

  static void handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Launched from notification in terminated state -> Open HomeScreen cleanly with all features
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }
}