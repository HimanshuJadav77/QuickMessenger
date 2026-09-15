// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _openProfile(BuildContext context, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => SearchUserProfile(
          username: userData["username"],
          email: userData["email"],
          about: userData["about"],
          imageurl: userData["userimageurl"],
          userid: userData["userid"],
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

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Large Title: "Activity" (34pt Bold) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 4),
                child: Text(
                  'Activity',
                  style: AppTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // ── Search Field ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 16),
                child: LGSearchField(
                  controller: _searchController,
                  placeholder: 'Search activity',
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ),

            // ── Follow Requests Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 6),
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
                stream: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(currentUserId)
                    .collection("requests")
                    .where("request", isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 60, child: Center(child: CupertinoActivityIndicator()));
                  }
                  final updatesList = snapshot.data?.docs ?? [];
                  if (updatesList.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                      child: Text(
                        'No pending follow requests',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted(isDark)),
                      ),
                    );
                  }

                  return CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.background(isDark),
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    children: updatesList.map((update) {
                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection("Users").doc(update.id).snapshots(),
                        builder: (context, uSnapshot) {
                          final userData = uSnapshot.data?.data();
                          if (userData == null) return const SizedBox.shrink();
                          final username = (userData["username"] ?? 'User').toString();
                          final imageUrl = (userData["userimageurl"] ?? '').toString();

                          if (_searchQuery.isNotEmpty && !username.toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return CupertinoListTile(
                            leading: UserAvatar(username: username, imageUrl: imageUrl, radius: 20),
                            title: Text(username),
                            subtitle: const Text('requested to follow you'),
                            trailing: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              color: accent,
                              borderRadius: BorderRadius.circular(16),
                              minimumSize: Size.zero,
                              onPressed: () => _confirmAccept(context, currentUserId, update.id, username),
                              child: const Text(
                                'Accept',
                                style: TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            onTap: () => _openProfile(context, userData),
                          );
                        },
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
                padding: EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 6),
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
                stream: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(currentUserId)
                    .collection("followers")
                    .where("follower", isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 60, child: Center(child: CupertinoActivityIndicator()));
                  }
                  final followerList = snapshot.data?.docs ?? [];
                  if (followerList.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                      child: Text(
                        'No new followers',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted(isDark)),
                      ),
                    );
                  }

                  return CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.background(isDark),
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    children: followerList.map((doc) {
                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection("Users").doc(doc.id).snapshots(),
                        builder: (context, uSnapshot) {
                          final userData = uSnapshot.data?.data();
                          if (userData == null) return const SizedBox.shrink();
                          final username = (userData["username"] ?? 'User').toString();
                          final imageUrl = (userData["userimageurl"] ?? '').toString();

                          if (_searchQuery.isNotEmpty && !username.toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return CupertinoListTile(
                            leading: UserAvatar(username: username, imageUrl: imageUrl, radius: 20),
                            title: Text(username),
                            subtitle: const Text('started following you'),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () => _openProfile(context, userData),
                          );
                        },
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
