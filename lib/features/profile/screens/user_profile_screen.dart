// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';
import 'package:quick_messenger/core/widgets/glass_action_sheet.dart';
import 'package:quick_messenger/features/profile/screens/followers_following_screen.dart';
import 'package:quick_messenger/features/chat/screens/chat_screen.dart';

/// iOS-native other-user profile.
///
/// - [CupertinoPageScaffold] + [CupertinoNavigationBar]
/// - Follow / Request / Following via accent [CupertinoButton]
/// - Message FAB → accent circle button → [ChatScreen] via [CupertinoPageRoute]
/// - Block/Unblock via [CupertinoActionSheet] + [CupertinoAlertDialog]
/// - Firestore follow/request/block logic unchanged from original.
class SearchUserProfile extends ConsumerStatefulWidget {
  const SearchUserProfile(
      {super.key,
      required this.username,
      required this.email,
      required this.about,
      required this.imageurl,
      required this.userid});

  final imageurl;
  final username;
  final email;
  final about;
  final userid;

  @override
  ConsumerState<SearchUserProfile> createState() =>
      _SearchUserProfileState();
}

class _SearchUserProfileState extends ConsumerState<SearchUserProfile> {
  bool private = true;
  bool public = true;
  final _firestore = FirebaseFirestore.instance;
  bool followState = false;
  bool block = false;
  bool blockedbyUser = false;
  bool requested = false;

  String get currentUserId => ref.read(currentUserIdProvider);

  @override
  void initState() {
    super.initState();
    getBlockState();
    setFollowFollowing();
    getRequestState();
  }

  Future<void> getRequestState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final get = await _firestore
        .collection("Users")
        .doc(uid)
        .collection("requests")
        .doc(widget.userid)
        .get();
    if (get.exists && mounted) {
      if (get.data()?["requested"] == true) {
        setState(() => requested = true);
      }
    }
  }

  Future<void> setFollowFollowing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final myfollower = await FirebaseFirestore.instance
        .collection("Users")
        .doc(uid)
        .collection("followers")
        .doc(widget.userid)
        .get();
    final myfollowing = await FirebaseFirestore.instance
        .collection("Users")
        .doc(uid)
        .collection("following")
        .doc(widget.userid)
        .get();
    final userfollower = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.userid)
        .collection("followers")
        .doc(uid)
        .get();
    final userfollowing = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.userid)
        .collection("following")
        .doc(uid)
        .get();
    if (!myfollower.exists) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .collection("followers")
          .doc(widget.userid)
          .set({"follower": false});
    } else if (!myfollowing.exists) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .collection("following")
          .doc(widget.userid)
          .set({"following": false});
    } else if (!userfollowing.exists) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("following")
          .doc(uid)
          .set({"following": false});
    } else if (!userfollower.exists) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("followers")
          .doc(uid)
          .set({"follower": false});
    }
  }

  Future<void> blockUser(blockUserid) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    if (block) {
      await FirebaseFirestore.instance
          .collection("block")
          .doc(uid)
          .collection("blockedid")
          .doc(blockUserid)
          .set({"blocked": false});
      if (mounted) setState(() => block = false);
    } else {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .collection("followers")
          .doc(widget.userid)
          .update({"follower": false});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .collection("following")
          .doc(widget.userid)
          .update({"following": false});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("followers")
          .doc(uid)
          .update({"follower": false});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("following")
          .doc(uid)
          .update({"following": false});
      await FirebaseFirestore.instance
          .collection("block")
          .doc(uid)
          .collection("blockedid")
          .doc(blockUserid)
          .set({"blocked": true});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(blockUserid)
          .collection("requests")
          .doc(uid)
          .update({"request": false});
      if (mounted) {
        setState(() {
          block = true;
          requested = false;
        });
      }
    }
  }

  Future<void> getBlockState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection("block")
        .doc(uid)
        .collection("blockedid")
        .doc(widget.userid)
        .get();
    if (!doc.exists) {
      await FirebaseFirestore.instance
          .collection("block")
          .doc(uid)
          .collection("blockedid")
          .doc(widget.userid)
          .set({"blocked": false});
      return;
    }
    if (doc.data()?["blocked"] == true && mounted) {
      setState(() => block = true);
    }
  }

  Future<void> request() async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    if (requested) {
      await _firestore
          .collection("Users")
          .doc(uid)
          .collection("requests")
          .doc(widget.userid)
          .set({"requested": true});
      await _firestore
          .collection("Users")
          .doc(widget.userid)
          .collection("requests")
          .doc(uid)
          .set({"request": true});
    } else {
      await _firestore
          .collection("Users")
          .doc(uid)
          .collection("requests")
          .doc(widget.userid)
          .set({"requested": false});
      await _firestore
          .collection("Users")
          .doc(widget.userid)
          .collection("requests")
          .doc(uid)
          .set({"request": false});
    }
  }

  Future<void> followUnfollowUser(bool state) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final doc = await _firestore
        .collection("block")
        .doc(uid)
        .collection("blockedid")
        .doc(widget.userid)
        .get();
    if (doc.data()?["blocked"] == true) {
      if (mounted) showSnackBar(context, "Unblock ${widget.username} first.");
      return;
    }
    try {
      if (state) {
        await _firestore
            .collection("Users")
            .doc(uid)
            .collection("following")
            .doc(widget.userid)
            .set({"following": true});
        await _firestore
            .collection("Users")
            .doc(widget.userid)
            .collection("followers")
            .doc(uid)
            .set({"follower": true});
      } else {
        await _firestore
            .collection("Users")
            .doc(uid)
            .collection("following")
            .doc(widget.userid)
            .update({"following": false});
        await _firestore
            .collection("Users")
            .doc(widget.userid)
            .collection("followers")
            .doc(uid)
            .set({"follower": false});
        if (mounted) setState(() => requested = false);
      }
    } on FirebaseException catch (e) {
      if (mounted) showSnackBar(context, "$e");
    }
  }

  void _showBlockSheet() {
    LGActionSheet.showConfirmation(
      context: context,
      title: block ? 'Unblock ${widget.username}?' : 'Block ${widget.username}?',
      message: block
          ? 'They will be able to send you messages and view your profile.'
          : 'Blocked users cannot message you or view your profile.',
      confirmTitle: block ? 'Unblock' : 'Block',
      isDestructive: !block,
      onConfirm: () => blockUser(widget.userid),
    );
  }

  void _openChat() async {
    if (private && followState || public) {
      if (!mounted) return;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => ChatScreen(
            participantId: widget.userid,
            participantName: widget.username,
            participantImageUrl: widget.imageurl,
            participantAbout: widget.about,
            participantEmail: widget.email,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Private profile'),
          content: const Text('This profile is private — send a request first.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final uid = ref.watch(currentUserIdProvider);
    if (uid.isEmpty) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.username.toString()),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        trailing: blockedbyUser
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showBlockSheet,
                child: const Icon(CupertinoIcons.ellipsis_circle),
              ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("block")
              .doc(widget.userid)
              .collection("blockedid")
              .doc(uid)
              .snapshots(),
          builder: (context, blockSnap) {
            if (blockSnap.connectionState == ConnectionState.waiting ||
                !blockSnap.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!(blockSnap.data?.exists ?? false)) {
              FirebaseFirestore.instance
                  .collection("block")
                  .doc(widget.userid)
                  .collection("blockedid")
                  .doc(uid)
                  .set({"blocked": false});
              return const Center(child: CupertinoActivityIndicator());
            }

            final isBlockedByThem =
                blockSnap.data?.data()?["blocked"] == true;
            if (isBlockedByThem) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    "${widget.username} has blocked you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary(isDark)),
                  ),
                ),
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(widget.userid)
                  .collection("privacy")
                  .doc("mode")
                  .snapshots(),
              builder: (context, privacySnap) {
                if (!privacySnap.hasData ||
                    !(privacySnap.data?.exists ?? false)) {
                  if (privacySnap.connectionState !=
                      ConnectionState.waiting) {
                    FirebaseFirestore.instance
                        .collection("Users")
                        .doc(widget.userid)
                        .collection("privacy")
                        .doc("mode")
                        .set({"privacy": "public"});
                  }
                  return const Center(
                      child: CupertinoActivityIndicator());
                }

                final privacy =
                    privacySnap.data?.data()?["privacy"] ?? 'public';
                final isPrivate = privacy == "private";

                return ListView(
                  children: [
                    SizedBox(height: AppSpacing.md),
                    // Header: avatar + counts + message button
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.15),
                              image: (widget.imageurl ?? '')
                                      .toString()
                                      .isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          widget.imageurl.toString()),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {},
                                    )
                                  : null,
                              border: Border.all(
                                color: AppColors.divider(isDark),
                                width: 0.5,
                              ),
                            ),
                            child: (widget.imageurl ?? '')
                                    .toString()
                                    .isEmpty
                                ? Center(
                                    child: Text(
                                      widget.username
                                              .toString()
                                              .isNotEmpty
                                          ? widget.username
                                              .toString()[0]
                                              .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: (isPrivate && followState ||
                                      !isPrivate)
                                  ? () => Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (_) =>
                                              FollowFollowingPage(
                                            userid: widget.userid,
                                          ),
                                        ),
                                      )
                                  : null,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _FollowCount(
                                    label: 'Followers',
                                    stream: _firestore
                                        .collection("Users")
                                        .doc(widget.userid)
                                        .collection("followers")
                                        .where("follower",
                                            isEqualTo: true)
                                        .snapshots(),
                                    isDark: isDark,
                                  ),
                                  _FollowCount(
                                    label: 'Following',
                                    stream: _firestore
                                        .collection("Users")
                                        .doc(widget.userid)
                                        .collection("following")
                                        .where("following",
                                            isEqualTo: true)
                                        .snapshots(),
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openChat,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                              ),
                              child: const Icon(
                                CupertinoIcons.chat_bubble_2_fill,
                                color: CupertinoColors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Privacy badge
                    Padding(
                      padding: EdgeInsets.only(
                          top: AppSpacing.xs,
                          left: AppSpacing.md),
                      child: Text(
                        isPrivate ? 'Private' : 'Public',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    // Info section
                    CupertinoListSection.insetGrouped(
                      backgroundColor: AppColors.background(isDark),
                      header: const Text('INFO'),
                      children: [
                        CupertinoListTile(
                          title: const Text('Username'),
                          subtitle: Text(widget.username.toString()),
                        ),
                        CupertinoListTile(
                          title: const Text('Email'),
                          subtitle: Text(widget.email.toString()),
                        ),
                        if ((widget.about ?? '').toString().isNotEmpty)
                          CupertinoListTile(
                            title: const Text('About'),
                            subtitle:
                                Text(widget.about.toString()),
                          ),
                      ],
                    ),
                    // Follow / Request button
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _firestore
                            .collection("Users")
                            .doc(uid)
                            .collection("following")
                            .doc(widget.userid)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData ||
                              !(snap.data?.exists ?? false)) {
                            if (snap.connectionState !=
                                ConnectionState.waiting) {
                              _firestore
                                  .collection("Users")
                                  .doc(uid)
                                  .collection("following")
                                  .doc(widget.userid)
                                  .set({"following": false});
                            }
                            return const SizedBox(
                              height: 48,
                              child: Center(
                                  child:
                                      CupertinoActivityIndicator()),
                            );
                          }

                          final following =
                              snap.data?.data()?["following"] == true;
                          followState = following;
                          final showFollow = !isPrivate ||
                              following ||
                              (isPrivate && following);

                          if (showFollow) {
                            return SizedBox(
                              width: double.infinity,
                              child: CupertinoButton.filled(
                                onPressed: block
                                    ? () => showSnackBar(context,
                                        "Unblock ${widget.username} first.")
                                    : () {
                                        if (!following) {
                                          followUnfollowUser(true);
                                        } else {
                                          followUnfollowUser(false);
                                          if (mounted) {
                                            setState(() =>
                                                requested = false);
                                          }
                                          request();
                                        }
                                      },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      following
                                          ? CupertinoIcons
                                              .checkmark_circle
                                          : CupertinoIcons.person_add,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(following
                                        ? 'Following'
                                        : 'Follow'),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            child: CupertinoButton.filled(
                              onPressed: block
                                  ? () => showSnackBar(context,
                                      "Unblock ${widget.username} first.")
                                  : () {
                                      if (mounted) {
                                        setState(() =>
                                            requested = !requested);
                                      }
                                      request();
                                    },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    requested
                                        ? CupertinoIcons
                                            .checkmark_circle
                                        : CupertinoIcons.person_add,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(requested
                                      ? 'Requested'
                                      : 'Request'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FollowCount extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final bool isDark;

  const _FollowCount({
    required this.label,
    required this.stream,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            snapshot.connectionState == ConnectionState.waiting
                ? const CupertinoActivityIndicator(radius: 8)
                : Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(isDark),
              ),
            ),
          ],
        );
      },
    );
  }
}
