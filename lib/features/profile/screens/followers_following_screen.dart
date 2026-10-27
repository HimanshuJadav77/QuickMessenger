// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:quick_messenger/core/database/local_database_helper.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/features/chat/screens/chat_screen.dart';
import 'package:quick_messenger/features/profile/screens/profile_screen.dart';
import 'package:quick_messenger/features/profile/screens/user_profile_screen.dart';

/// iOS-native followers / following with segmented control and cached user lookups.
class FollowFollowingPage extends StatefulWidget {
  const FollowFollowingPage({super.key, required this.userid});

  final dynamic userid;

  @override
  State<FollowFollowingPage> createState() => _FollowFollowingPageState();
}

class _FollowFollowingPageState extends State<FollowFollowingPage> {
  final _firestore = FirebaseFirestore.instance;
  int _segment = 0;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final targetUserId = widget.userid.toString();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('People'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _segment,
                  backgroundColor: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFE5E5EA),
                  thumbColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.all(4),
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Followers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _segment == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: _segment == 0
                              ? AppColors.textPrimary(isDark)
                              : AppColors.textSecondary(isDark),
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Following',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _segment == 1 ? FontWeight.w600 : FontWeight.w500,
                          color: _segment == 1
                              ? AppColors.textPrimary(isDark)
                              : AppColors.textSecondary(isDark),
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (v) {
                    if (v != null) setState(() => _segment = v);
                  },
                ),
              ),
            ),
            Expanded(
              child: _segment == 0
                  ? _UserList(
                      stream: _firestore
                          .collection("Users")
                          .doc(targetUserId)
                          .collection("followers")
                          .where("follower", isEqualTo: true)
                          .snapshots(),
                      emptyText: 'No followers yet',
                      isDark: isDark,
                      currentUserId: currentUserId,
                    )
                  : _UserList(
                      stream: _firestore
                          .collection("Users")
                          .doc(targetUserId)
                          .collection("following")
                          .where("following", isEqualTo: true)
                          .snapshots(),
                      emptyText: 'Not following anyone yet',
                      isDark: isDark,
                      currentUserId: currentUserId,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyText;
  final bool isDark;
  final String currentUserId;

  const _UserList({
    required this.stream,
    required this.emptyText,
    required this.isDark,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: TextStyle(color: AppColors.textMuted(isDark)),
            ),
          );
        }

        return CupertinoListSection.insetGrouped(
          backgroundColor: AppColors.background(isDark),
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          children: docs.map((doc) {
            return _CachedUserTile(
              otherId: doc.id,
              currentUserId: currentUserId,
              isDark: isDark,
            );
          }).toList(),
        );
      },
    );
  }
}

class _CachedUserTile extends StatefulWidget {
  final String otherId;
  final String currentUserId;
  final bool isDark;

  const _CachedUserTile({
    required this.otherId,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  State<_CachedUserTile> createState() => _CachedUserTileState();
}

class _CachedUserTileState extends State<_CachedUserTile> {
  static final Map<String, Map<String, dynamic>> _inMemoryProfileCache = {};
  static final Map<String, Future<Map<String, dynamic>?>> _inFlightFetches = {};

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didUpdateWidget(covariant _CachedUserTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherId != widget.otherId) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final otherId = widget.otherId;
    if (otherId.isEmpty) return;

    // 1. Fast in-memory check
    if (_inMemoryProfileCache.containsKey(otherId)) {
      if (mounted) {
        setState(() {
          _userData = _inMemoryProfileCache[otherId];
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Fast local SQLite cache check
    if (widget.currentUserId.isNotEmpty) {
      final localProfile = await LocalDatabaseHelper.instance.getUserProfile(
        widget.currentUserId,
        otherId,
      );
      if (localProfile != null &&
          (localProfile['username'] ?? '').toString().isNotEmpty) {
        _inMemoryProfileCache[otherId] = localProfile;
        if (mounted) {
          setState(() {
            _userData = localProfile;
            _isLoading = false;
          });
        }
        return;
      }
    }

    // 3. Deduplicated Firestore fetch
    if (!_inFlightFetches.containsKey(otherId)) {
      _inFlightFetches[otherId] = _fetchFromFirestore(otherId);
    }

    final data = await _inFlightFetches[otherId];
    _inFlightFetches.remove(otherId);

    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchFromFirestore(String otherId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(otherId)
          .get();
      final data = doc.data();
      if (data != null) {
        final profile = {
          'username': data['username'] ?? 'User',
          'display_name': data['username'] ?? 'User',
          'about': data['about'] ?? '',
          'email': data['email'] ?? '',
          'image_url': data['userimageurl'] ?? data['imageurl'] ?? '',
          'userimageurl': data['userimageurl'] ?? data['imageurl'] ?? '',
        };
        _inMemoryProfileCache[otherId] = profile;
        if (widget.currentUserId.isNotEmpty) {
          await LocalDatabaseHelper.instance.upsertUserProfile(
            widget.currentUserId,
            otherId,
            profile,
          );
        }
        return profile;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userData == null) {
      return const SizedBox(
        height: 56,
        child: Center(child: CupertinoActivityIndicator(radius: 10)),
      );
    }

    final otherId = widget.otherId;
    final currentUserId = widget.currentUserId;
    final isDark = widget.isDark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final data = _userData ?? {};
    final username =
        (data["username"] ?? data["display_name"] ?? 'User').toString();
    final imageUrl =
        (data["userimageurl"] ?? data["image_url"] ?? '').toString();
    final about = (data["about"] ?? '').toString();
    final email = (data["email"] ?? '').toString();
    final isSelf = otherId == currentUserId;

    return CupertinoListTile(
      padding: AppSpacing.listTilePadding,
      leadingSize: AppSpacing.listTileLeadingSize,
      leadingToTitle: AppSpacing.listTileLeadingToTitle,
      leading: UserAvatar(
        username: username,
        seed: otherId,
        imageUrl: imageUrl,
        radius: AppAvatarSize.listTile,
      ),
      title: Text(
        isSelf ? '$username (you)' : username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        about.isNotEmpty
            ? about
            : '@${username.toLowerCase().replaceAll(' ', '')}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textMuted(isDark),
          fontSize: 13,
        ),
      ),
      trailing: isSelf
          ? const CupertinoListTileChevron()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(34, 34),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => ChatScreen(
                          participantId: otherId,
                          participantName: username,
                          participantImageUrl: imageUrl,
                          participantAbout: about,
                          participantEmail: email,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        size: 16,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const CupertinoListTileChevron(),
              ],
            ),
      onTap: () {
        if (isSelf) {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const MyProfile()),
          );
        } else {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => SearchUserProfile(
                username: username,
                email: email,
                about: about,
                imageurl: imageUrl,
                userid: otherId,
              ),
            ),
          );
        }
      },
    );
  }
}
