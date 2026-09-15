import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/glass_action_sheet.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
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
    final accent = CupertinoTheme.of(context).primaryColor;
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
            // ── Top Header Actions (Matching Chats Page) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: Row(
                  children: [
                    LGIconButton(
                      icon: CupertinoIcons.ellipsis,
                      onPressed: () => _showCreateOptions(context),
                    ),
                    const Spacer(),
                    LGIconButton(
                      icon: CupertinoIcons.search,
                      onPressed: () => Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const SearchUser()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    LGIconButton(
                      icon: CupertinoIcons.plus,
                      color: accent,
                      iconColor: Colors.white,
                      onPressed: () => _showCreateOptions(context),
                    ),
                  ],
                ),
              ),
            ),

            // ── Large Title: "Communities" (34pt Bold) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                child: Text(
                  'Communities',
                  style: AppTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // ── Pill Search Field ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 10),
                child: LGSearchField(
                  controller: _searchController,
                  placeholder: 'Search communities & groups',
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ),

            // ── Filter Chips (All, Communities, Groups) ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filterOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final isSelected = _selectedFilter == idx;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = idx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withValues(alpha: isDark ? 0.25 : 0.16)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? accent.withValues(alpha: 0.6)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filterOptions[idx],
                            style: TextStyle(
                              color: isSelected ? accent : AppColors.textSecondary(isDark),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
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
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SearchUser()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xB31C1C1E) : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF007AFF), Color(0xFF0056B3)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(CupertinoIcons.person_3_fill, color: Colors.white, size: 24),
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
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMuted(isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (_selectedFilter == 0 || _selectedFilter == 2)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const CreateGroupScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xB31C1C1E) : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F62FE), Color(0xFF0043CE)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(CupertinoIcons.person_2_fill, color: Colors.white, size: 24),
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
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMuted(isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Section Title: Joined Groups ──
            if (_selectedFilter == 0 || _selectedFilter == 2) ...[
              groupsAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (groups) {
                  final filteredGroups = groups.where((g) {
                    if (_searchQuery.isEmpty) return true;
                    return g.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredGroups.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = filteredGroups[index];
                        return GroupChatTile(group: group);
                      },
                      childCount: filteredGroups.length,
                    ),
                  );
                },
              ),
            ],

            // ── Section Title: Followed Contacts / Communities ──
            if (_selectedFilter == 0 || _selectedFilter == 1) ...[
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("Users")
                      .doc(currentUserId)
                      .collection("following")
                      .where("following", isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    final usersList = snapshot.data?.docs ?? [];
                    if (usersList.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: usersList.length,
                      itemBuilder: (context, index) {
                        final followDoc = usersList[index];
                        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance.collection("Users").doc(followDoc.id).get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData || !(userSnapshot.data?.exists ?? false)) {
                              return const SizedBox.shrink();
                            }
                            final userData = userSnapshot.data!.data()!;
                            final username = (userData["username"] ?? 'User').toString();
                            final imageUrl = (userData["userimageurl"] ?? '').toString();
                            final about = (userData["about"] ?? 'Available').toString();

                            if (_searchQuery.isNotEmpty && !username.toLowerCase().contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xB31C1C1E) : const Color(0xF2FFFFFF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                                  width: 0.75,
                                ),
                              ),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    username: username,
                                    imageUrl: imageUrl,
                                    radius: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppColors.textPrimary(isDark),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          about,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary(isDark),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final uid = ref.read(currentUserIdProvider);
                                      await FirebaseFirestore.instance
                                          .collection("Users")
                                          .doc(uid)
                                          .collection("chats")
                                          .doc(userData["userid"])
                                          .set({"chat": true, "time": FieldValue.serverTimestamp()});
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) => ChatScreen(
                                              participantId: followDoc.id,
                                              participantName: userData["username"],
                                              participantImageUrl: userData["userimageurl"],
                                              participantAbout: userData["about"],
                                              participantEmail: userData["email"],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(CupertinoIcons.chat_bubble_fill, color: accent, size: 22),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
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
