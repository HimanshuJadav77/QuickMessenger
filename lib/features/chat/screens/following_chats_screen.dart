import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_filter_chip.dart';
import 'package:quick_messenger/core/widgets/app_screen_header.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/core/services/user_profile_cache_service.dart';
import 'package:quick_messenger/features/chat/providers/chat_provider.dart';
import 'package:quick_messenger/features/chat/screens/chat_screen.dart';
import 'package:quick_messenger/features/chat/screens/create_group_screen.dart';
import 'package:quick_messenger/features/chat/screens/user_search_screen.dart';
import 'package:quick_messenger/features/chat/widgets/group_chat_tile.dart';

/// WhatsApp iOS "Communities & Groups" Screen.
///
/// Features:
/// - Header actions (... menu and circular + action for New Group / Community)
/// - Large Bold Title: "Communities"
/// - Search bar (LGSearchField)
/// - Filter chips: "All", "Communities", "Groups"
/// - New Community & New Group quick action banners
/// - Live stream of followed communities/users & group chats
/// - Bottom clearance for floating LGBottomBar
class FollowedChatList extends ConsumerStatefulWidget {
  const FollowedChatList({super.key});

  @override
  ConsumerState<FollowedChatList> createState() => _FollowedChatListState();
}

class _FollowedChatListState extends ConsumerState<FollowedChatList> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: All, 1: Communities, 2: Groups
  String _searchQuery = '';
  Stream<QuerySnapshot<Map<String, dynamic>>>? _followingStream;
  String? _streamUserId;

  void _ensureFollowingStream(String currentUserId) {
    if (_streamUserId == currentUserId && _followingStream != null) return;
    _streamUserId = currentUserId;
    if (currentUserId.isNotEmpty) {
      _followingStream = FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("following")
          .where("following", isEqualTo: true)
          .snapshots();
    } else {
      _followingStream = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateOptions(BuildContext context) {
    LGActionSheet.show(
      context: context,
      title: 'Create New',
      actions: [
        LGActionSheetAction(
          title: 'New Group',
          icon: CupertinoIcons.person_2_fill,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const CreateGroupScreen()),
            );
          },
        ),
        LGActionSheetAction(
          title: 'New Community / Find People',
          icon: CupertinoIcons.person_3_fill,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const SearchUser()),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(currentUserIdProvider);
    final groupsAsync = ref.watch(groupsProvider);

    final filterOptions = ['All', 'Communities', 'Groups'];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Header Row ──
            SliverToBoxAdapter(
              child: AppScreenHeader(
                title: 'Communities',
                actions: [
                  AppHeaderIconButton(
                    icon: CupertinoIcons.search,
                    onPressed: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SearchUser()),
                    ),
                  ),
                  AppHeaderIconButton(
                    icon: CupertinoIcons.plus,
                    isPrimary: true,
                    onPressed: () => _showCreateOptions(context),
                  ),
                ],
              ),
            ),

            // ── Pill Search Field ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 10),
                child: LGSearchField(
                  controller: _searchController,
                  placeholder: 'Search communities & groups',
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ),

            // ── Filter Chips (All, Communities, Groups) ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filterOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final isSelected = _selectedFilter == idx;
                    return AppFilterChip(
                      label: filterOptions[idx],
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedFilter = idx),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Quick Action Cards: "New Community" & "New Group" ──
            if (_selectedFilter == 0 || _selectedFilter == 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SearchUser()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xB31C1C1E)
                            : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF3A3A3C),
                                        const Color(0xFF1C1C1E)
                                      ]
                                    : [
                                        const Color(0xFF2C2C2E),
                                        const Color(0xFF111111)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(CupertinoIcons.person_3_fill,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Community',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bring members together into topic-based groups',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(isDark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward,
                              size: 16, color: AppColors.textMuted(isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (_selectedFilter == 0 || _selectedFilter == 2)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (_) => const CreateGroupScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xB31C1C1E)
                            : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF3A3A3C),
                                        const Color(0xFF1C1C1E)
                                      ]
                                    : [
                                        const Color(0xFF2C2C2E),
                                        const Color(0xFF111111)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(CupertinoIcons.person_2_fill,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Group',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Create a chat with friends or colleagues',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(isDark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward,
                              size: 16, color: AppColors.textMuted(isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Section: Joined Groups ──
            if (_selectedFilter == 0 || _selectedFilter == 2) ...[
              groupsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                ),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (groups) {
                  final filteredGroups = groups.where((g) {
                    if (_searchQuery.isEmpty) return true;
                    return g.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredGroups.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                                AppSpacing.md, 12, AppSpacing.md, 6),
                            child: Text(
                              'GROUPS (${filteredGroups.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted(isDark),
                                letterSpacing: 0.6,
                              ),
                            ),
                          );
                        }
                        final group = filteredGroups[index - 1];
                        return RepaintBoundary(
                          key: ValueKey('group_${group.groupId}'),
                          child: GroupChatTile(group: group),
                        );
                      },
                      findChildIndexCallback: (Key key) {
                        final valKey = key as ValueKey<String>?;
                        if (valKey == null) return null;
                        final val = valKey.value;
                        if (!val.startsWith('group_')) return null;
                        final gId = val.substring('group_'.length);
                        final idx =
                            filteredGroups.indexWhere((g) => g.groupId == gId);
                        return idx == -1 ? null : idx + 1;
                      },
                      childCount: filteredGroups.length + 1,
                    ),
                  );
                },
              ),
            ],

            // ── Section: Followed Contacts / Communities ──
            if (_selectedFilter == 0 || _selectedFilter == 1) ...[
              if (currentUserId.isEmpty)
                const SliverToBoxAdapter(child: SizedBox.shrink())
              else
                Builder(
                  builder: (context) {
                    _ensureFollowingStream(currentUserId);
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _followingStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const SliverToBoxAdapter(child: SizedBox.shrink());
                        }
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CupertinoActivityIndicator()),
                            ),
                          );
                        }
                        final usersList = snapshot.data?.docs ?? [];
                        if (usersList.isEmpty) {
                          return const SliverToBoxAdapter(child: SizedBox.shrink());
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      AppSpacing.md, 12, AppSpacing.md, 6),
                                  child: Text(
                                    'COMMUNITIES & CHANNELS (${usersList.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted(isDark),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                );
                              }
                              final followDoc = usersList[index - 1];
                              return _FollowedUserTile(
                                key: ValueKey('followed_${followDoc.id}'),
                                userId: followDoc.id,
                                currentUserId: currentUserId,
                                searchQuery: _searchQuery,
                                isDark: isDark,
                              );
                            },
                            findChildIndexCallback: (Key key) {
                              final valKey = key as ValueKey<String>?;
                              if (valKey == null) return null;
                              final val = valKey.value;
                              if (!val.startsWith('followed_')) return null;
                              final uId = val.substring('followed_'.length);
                              final idx = usersList.indexWhere((doc) => doc.id == uId);
                              return idx == -1 ? null : idx + 1;
                            },
                            childCount: usersList.length + 1,
                          ),
                        );
                      },
                    );
                  },
                ),
            ],

            // ── End of List Clearance for Floating LGBottomBar ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowedUserTile extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String searchQuery;
  final bool isDark;

  const _FollowedUserTile({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.searchQuery,
    required this.isDark,
  });

  @override
  State<_FollowedUserTile> createState() => _FollowedUserTileState();
}

class _FollowedUserTileState extends State<_FollowedUserTile> {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant _FollowedUserTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.currentUserId != widget.currentUserId) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final syncData =
        UserProfileCacheService.instance.getProfileSync(widget.userId);
    if (syncData != null) {
      _userData = syncData;
      return;
    }

    _isLoading = true;
    UserProfileCacheService.instance
        .getProfile(
            currentUserId: widget.currentUserId, targetUid: widget.userId)
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
          height: 60,
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
    final about = (userData["about"] ?? 'Available').toString();

    if (widget.searchQuery.isNotEmpty &&
        !username.toLowerCase().contains(widget.searchQuery)) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xB31C1C1E)
              : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.75,
          ),
        ),
        child: CupertinoListTile(
          leadingSize: AppSpacing.listTileLeadingSize,
          leadingToTitle: AppSpacing.listTileLeadingToTitle,
          padding: AppSpacing.listTilePadding,
          onTap: () async {
            if (widget.currentUserId.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection("Users")
                  .doc(widget.currentUserId)
                  .collection("chats")
                  .doc(userData["userid"] ?? widget.userId)
                  .set({"chat": true, "time": FieldValue.serverTimestamp()});
            }
            if (context.mounted) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => ChatScreen(
                    participantId: widget.userId,
                    participantName: username,
                    participantImageUrl: imageUrl,
                    participantAbout: about,
                    participantEmail: (userData["email"] ?? '').toString(),
                  ),
                ),
              );
            }
          },
          leading: UserAvatar(
            username: username,
            seed: widget.userId,
            imageUrl: imageUrl,
            radius: AppAvatarSize.listTile,
          ),
          title: Text(
            username,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary(widget.isDark),
            ),
          ),
          subtitle: Text(
            about,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(widget.isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            CupertinoIcons.chat_bubble_fill,
            color: AppColors.textPrimary(widget.isDark),
            size: 20,
          ),
        ),
      ),
    );
  }
}

