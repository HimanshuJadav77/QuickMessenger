import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/features/chat/providers/chat_provider.dart';
import 'package:quick_messenger/features/chat/screens/calls_tab_screen.dart';
import 'package:quick_messenger/features/chat/screens/chat_list_screen.dart';
import 'package:quick_messenger/features/chat/screens/following_chats_screen.dart';
import 'package:quick_messenger/features/notifications/screens/notification_screen.dart';
import 'package:quick_messenger/features/settings/screens/settings_screen.dart';
import 'package:quick_messenger/features/auth/screens/auth_gate_screen.dart';
import 'package:quick_messenger/core/services/socket_service.dart';

import '../../../core/utils/networkcheck.dart';

@Deprecated('Use currentUserIdProvider instead. Kept for legacy screens.')
String currentUserId = "";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  late final PageController _pageController;
  int _currentIndex = 3; // Start on Chats tab (matching WhatsApp)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // ignore: deprecated_member_use_from_same_package
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    requestPermissions();
    _setOnline(true);
    _guardEmailVerified();
    SocketService.instance.connect();
    NetworkCheck().initializeInternetStatus(context);
    WidgetsBinding.instance.addObserver(this);
  }


  void _guardEmailVerified() {
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? true;
    if (!verified && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (_) => const LogReg()),
        (_) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = ref.read(currentUserIdProvider);
    if (uid.isEmpty) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _firestore.collection("Users").doc(uid).update({"online": false});
    } else if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    NetworkCheck().cancelSubscription();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setOnline(bool online) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    FirebaseFirestore.instance
        .collection("Users")
        .doc(uid)
        .update({"online": online});
  }

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidAsync = ref.watch(currentUserIdStreamProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    final unreadTotal = conversationsAsync.value
            ?.where((c) => c.unreadCount > 0)
            .length ??
        0;

    return uidAsync.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => const CupertinoPageScaffold(
        child: Center(child: Text("Something went wrong")),
      ),
      data: (uid) {
        if (uid.isEmpty) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        // ignore: deprecated_member_use_from_same_package
        if (currentUserId != uid) currentUserId = uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection("disabled_account").doc(uid).snapshots(),
          builder: (context, dsnapshot) {
            if (!dsnapshot.hasData || !(dsnapshot.data?.exists ?? false)) {
              if (dsnapshot.connectionState != ConnectionState.waiting) {
                _firestore
                    .collection("disabled_account")
                    .doc(uid)
                    .set({"disabled": false});
              }
              return const CupertinoPageScaffold(
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
            final disabled = dsnapshot.data?.get("disabled") == true;
            if (disabled) {
              return const CupertinoPageScaffold(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "Your account has been disabled by the administrator.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return CupertinoPageScaffold(
              backgroundColor: AppColors.background(isDark),
              child: Stack(
                children: [
                  // ── Slideable PageView (Left to Right navigation) ──
                  PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = index);
                    },
                    children: [
                      // Page 0: Updates
                      const SafeArea(bottom: false, child: Updates()),
                      // Page 1: Calls
                      const CallsTabScreen(),
                      // Page 2: Communities / Followed Contacts
                      const SafeArea(bottom: false, child: FollowedChatList()),
                      // Page 3: Chats (Primary chat list)
                      const SafeArea(bottom: false, child: ChatHome()),
                      // Page 4: Settings
                      const SettingsPage(),
                    ],
                  ),

                  // ── Floating WhatsApp Liquid Glass Bottom Bar ──
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LGBottomBar(
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
                      accentColor: accent,
                      items: [
                        const LiquidGlassNavigationBarItem(
                          icon: CupertinoIcons.bell,
                          activeIcon: CupertinoIcons.bell_fill,
                          label: "Activity",
                        ),
                        const LiquidGlassNavigationBarItem(
                          icon: CupertinoIcons.phone,
                          activeIcon: CupertinoIcons.phone_fill,
                          label: "Calls",
                        ),
                        const LiquidGlassNavigationBarItem(
                          icon: CupertinoIcons.person_3,
                          activeIcon: CupertinoIcons.person_3_fill,
                          label: "Groups",
                        ),
                        LiquidGlassNavigationBarItem(
                          icon: CupertinoIcons.chat_bubble_2,
                          activeIcon: CupertinoIcons.chat_bubble_2_fill,
                          label: "Chats",
                          badgeCount: unreadTotal > 0 ? unreadTotal : null,
                        ),
                        LiquidGlassNavigationBarItem(
                          icon: CupertinoIcons.person_crop_circle,
                          activeIcon: CupertinoIcons.person_crop_circle_fill,
                          label: "You",
                          customWidget: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _firestore.collection("Users").doc(uid).snapshots(),
                            builder: (context, userSnap) {
                              final data = userSnap.data?.data() ?? {};
                              final username = (data["username"] ?? 'User').toString();
                              final photoUrl = (data["userimageurl"] ?? '').toString();
                              final isSelected = _currentIndex == 4;
                              return Container(
                                padding: const EdgeInsets.all(1.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? accent : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: UserAvatar(
                                  username: username,
                                  imageUrl: photoUrl,
                                  radius: 10.5,
                                  showOnlineBadge: false,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

