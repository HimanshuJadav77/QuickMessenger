// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_screen_header.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/core/services/user_profile_cache_service.dart';
import 'package:quick_messenger/features/profile/screens/user_profile_screen.dart';

/// WhatsApp iOS "Updates" Screen.
///
/// Features:
/// - Top header action buttons and Large Bold Title: "Updates"
/// - Search bar for updates
/// - "Status" section: "My Status" card with gradient avatar + recent contacts status
/// - "Follow Requests" & "New Followers" sections with frosted liquid glass tiles
/// - Bottom clearance for floating LGBottomBar
class Updates extends ConsumerStatefulWidget {
  const Updates({super.key});

  @override
  ConsumerState<Updates> createState() => _UpdatesState();
}

class _UpdatesState extends ConsumerState<Updates> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Stream<QuerySnapshot<Map<String, dynamic>>>? _requestsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _followersStream;
  String? _streamUserId;

  void _ensureStreams(String currentUserId) {
    if (_streamUserId == currentUserId && _requestsStream != null) return;
    _streamUserId = currentUserId;
    if (currentUserId.isNotEmpty) {
      _requestsStream = FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("requests")
          .where("request", isEqualTo: true)
          .snapshots();
      _followersStream = FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("followers")
          .where("follower", isEqualTo: true)
          .snapshots();
    } else {
      _requestsStream = null;
      _followersStream = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProfile(BuildContext context, Map<String, dynamic> userData,
      String targetUserId) {
    final image = (userData["userimageurl"] ??
            userData["imageurl"] ??
            userData["image_url"] ??
            userData["photoURL"] ??
            '')
        .toString();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => SearchUserProfile(
          username: (userData["username"] ?? 'User').toString(),
          email: (userData["email"] ?? '').toString(),
          about: (userData["about"] ?? '').toString(),
          imageurl: image,
          userid: targetUserId,
        ),
      ),
    );
  }

  void _confirmAccept(
    BuildContext context,
    String currentUserId,
    String requesterId,
    String username,
  ) {
    GlassDialog.showConfirmation(
      context: context,
      title: 'Accept request?',
      message: 'Accept $username\'s follow request?',
      confirmLabel: 'Accept',
      onConfirm: () async {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUserId)
            .collection("followers")
            .doc(requesterId)
            .set({"follower": true});

        await FirebaseFirestore.instance
            .collection("Users")
            .doc(requesterId)
            .collection("following")
            .doc(currentUserId)
            .set({"following": true});

        await FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUserId)
            .collection("requests")
            .doc(requesterId)
            .set({"request": false});

        await FirebaseFirestore.instance
            .collection("Users")
            .doc(requesterId)
            .collection("requests")
            .doc(currentUserId)
            .set({"requested": false});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    _ensureStreams(currentUserId);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Header Row ──
            const SliverToBoxAdapter(
              child: AppScreenHeader(
                title: 'Activity',
              ),
            ),

            // ── Search Field ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 16),
                child: LGSearchField(
                  controller: _searchController,
                  placeholder: 'Search activity',
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ),

            // ── Follow Requests Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 6),
                child: Text(
                  'FOLLOW REQUESTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(isDark),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _requestsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SizedBox(
                        height: 60,
                        child: Center(child: CupertinoActivityIndicator()));
                  }
                  final updatesList = snapshot.data?.docs ?? [];
                  if (updatesList.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 8),
                      child: Text(
                        'No pending follow requests',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted(isDark)),
                      ),
                    );
                  }

                  return CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.background(isDark),
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    children: updatesList.map((update) {
                      return _ActivityUserTile(
                        key: ValueKey('req_${update.id}'),
                        userId: update.id,
                        currentUserId: currentUserId,
                        searchQuery: _searchQuery,
                        subtitle: 'requested to follow you',
                        onOpenProfile: _openProfile,
                        trailing: (uName) => CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          color: accent,
                          borderRadius: BorderRadius.circular(16),
                          minimumSize: Size.zero,
                          onPressed: () => _confirmAccept(
                              context, currentUserId, update.id, uName),
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              color: AppColors.onPrimary(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Followers Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 6),
                child: Text(
                  'NEW FOLLOWERS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(isDark),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _followersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SizedBox(
                        height: 60,
                        child: Center(child: CupertinoActivityIndicator()));
                  }
                  final followerList = snapshot.data?.docs ?? [];
                  if (followerList.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 8),
                      child: Text(
                        'No new followers',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted(isDark)),
                      ),
                    );
                  }

                  return CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.background(isDark),
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    children: followerList.map((doc) {
                      return _ActivityUserTile(
                        key: ValueKey('fol_${doc.id}'),
                        userId: doc.id,
                        currentUserId: currentUserId,
                        searchQuery: _searchQuery,
                        subtitle: 'started following you',
                        trailing: (_) => const CupertinoListTileChevron(),
                        onOpenProfile: _openProfile,
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Bottom clearance for floating LGBottomBar
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

class _ActivityUserTile extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String searchQuery;
  final String subtitle;
  final Widget Function(String username)? trailing;
  final void Function(BuildContext context, Map<String, dynamic> userData, String targetUserId) onOpenProfile;

  const _ActivityUserTile({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.searchQuery,
    required this.subtitle,
    this.trailing,
    required this.onOpenProfile,
  });

  @override
  State<_ActivityUserTile> createState() => _ActivityUserTileState();
}

class _ActivityUserTileState extends State<_ActivityUserTile> {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant _ActivityUserTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.currentUserId != widget.currentUserId) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final syncData = UserProfileCacheService.instance.getProfileSync(widget.userId);
    if (syncData != null) {
      _userData = syncData;
      return;
    }

    _isLoading = true;
    UserProfileCacheService.instance
        .getProfile(currentUserId: widget.currentUserId, targetUid: widget.userId)
        .then((profile) {
      if (mounted) {
        setState(() {
          _userData = profile;
          _isLoading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = _userData;
    if (userData == null) {
      if (_isLoading) {
        return const SizedBox(
          height: 52,
          child: Center(child: CupertinoActivityIndicator()),
        );
      }
      return const SizedBox.shrink();
    }

    final username = (userData["username"] ?? 'User').toString();
    final imageUrl = (userData["userimageurl"] ??
            userData["imageurl"] ??
            userData["image_url"] ??
            userData["photoURL"] ??
            '')
        .toString();

    if (widget.searchQuery.isNotEmpty &&
        !username.toLowerCase().contains(widget.searchQuery)) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      key: ValueKey('activity_user_${widget.userId}'),
      child: CupertinoListTile(
        padding: AppSpacing.listTilePadding,
        leadingSize: AppSpacing.listTileLeadingSize,
        leadingToTitle: AppSpacing.listTileLeadingToTitle,
        leading: UserAvatar(
          username: username,
          seed: widget.userId,
          imageUrl: imageUrl,
          radius: AppAvatarSize.listTile,
        ),
        title: Text(
          username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          widget.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: widget.trailing != null ? widget.trailing!(username) : null,
        onTap: () => widget.onOpenProfile(context, userData, widget.userId),
      ),
    );
  }
}

