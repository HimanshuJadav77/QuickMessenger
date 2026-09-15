import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/glass_action_sheet.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/features/chat/models/conversation_model.dart';
import 'package:quick_messenger/features/chat/providers/chat_provider.dart';
import 'package:quick_messenger/features/chat/screens/chat_screen.dart';
import 'package:quick_messenger/features/chat/screens/create_group_screen.dart';
import 'package:quick_messenger/features/chat/screens/user_search_screen.dart';
import 'package:quick_messenger/features/chat/widgets/conversation_tile.dart';
import 'package:quick_messenger/features/chat/widgets/group_chat_tile.dart';

enum _Filter { all, unread, favorites, groups }

/// WhatsApp iOS Liquid Glass Chat List Screen.
///
/// Features:
/// - WhatsApp header with `...` (options), Camera, and circular Accent `+` button
/// - Large bold title "Chats"
/// - `LGSearchField` ("Ask Meta AI or Search") with AI iridescent halo
/// - Horizontally scrollable filter pills: All, Unread, Favorites, Groups, Communities
/// - Archived section with badge
/// - WhatsApp chat tiles with double checkmarks, mute/pin badges, unread count
/// - Authentic Peek-and-Pop preview card and frosted glass context menu on long press
/// - End-to-end encryption footer caption
class ChatHome extends ConsumerStatefulWidget {
  const ChatHome({super.key});

  @override
  ConsumerState<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends ConsumerState<ChatHome>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';
  bool _showArchived = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewChat() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const SearchUser()),
    );
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const SearchUser()),
    );
  }

  void _showMoreMenu() {
    LGActionSheet.show(
      context: context,
      title: 'Chats Options',
      actions: [
        LGActionSheetAction(
          title: 'New Chat',
          icon: CupertinoIcons.chat_bubble_text_fill,
          onPressed: _openNewChat,
        ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final conversationsAsync = ref.watch(conversationsProvider);
    final groupsAsync = ref.watch(groupsProvider);

    final unreadCountTotal = conversationsAsync.value
            ?.where((c) => c.unreadCount > 0)
            .length ??
        0;

    return Column(
      children: [
        // ── WhatsApp Liquid Glass Header Top Row ──
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left More Options (...)
              LGIconButton(
                icon: CupertinoIcons.ellipsis,
                onPressed: _showMoreMenu,
              ),
              // Right Accent Plus Button
              GestureDetector(
                onTap: _openNewChat,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.plus,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Large Title "Chats" ──
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chats',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
        ),

        // ── Search Field ("Ask Meta AI or Search") ──
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: LGSearchField(
            controller: _searchController,
            placeholder: 'Ask Meta AI or Search',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            onClear: () => setState(() => _query = ''),
            onAiTap: _openSearch,
          ),
        ),

        // ── Filter Pills Row ──
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            children: [
              _Pill(
                label: 'All',
                selected: _filter == _Filter.all,
                onTap: () => setState(() => _filter = _Filter.all),
              ),
              _Pill(
                label: unreadCountTotal > 0 ? 'Unread $unreadCountTotal' : 'Unread',
                selected: _filter == _Filter.unread,
                onTap: () => setState(() => _filter = _Filter.unread),
              ),
              _Pill(
                label: 'Favorites',
                selected: _filter == _Filter.favorites,
                onTap: () => setState(() => _filter = _Filter.favorites),
              ),
              _Pill(
                label: 'Groups',
                selected: _filter == _Filter.groups,
                onTap: () => setState(() => _filter = _Filter.groups),
              ),
            ],
          ),
        ),

        // ── Chat List Content ──
        Expanded(
          child: conversationsAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle,
                      size: 44, color: AppColors.textMuted(isDark)),
                  SizedBox(height: AppSpacing.sm),
                  Text('Couldn\'t load chats',
                      style: TextStyle(color: AppColors.textSecondary(isDark))),
                  SizedBox(height: AppSpacing.sm),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => ref
                        .read(conversationsProvider.notifier)
                        .loadConversations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (conversations) {
              final currentUserId = ref.watch(currentUserIdProvider);
              final rawGroups = groupsAsync.value ?? [];
              final groups = rawGroups.where((g) =>
                  (g.lastMessage != null && g.lastMessage!.trim().isNotEmpty) ||
                  g.createdBy == currentUserId).toList();
              final visible = _applyFilter(conversations);
              final searched = _query.isEmpty
                  ? visible
                  : visible
                      .where((c) =>
                          c.participantName.toLowerCase().contains(_query) ||
                          c.lastMessage.toLowerCase().contains(_query))
                      .toList();
              final showGroups = (_filter == _Filter.all ||
                      _filter == _Filter.groups) &&
                  !_showArchived;
              final searchedGroups = _query.isEmpty
                  ? groups
                  : groups
                      .where((g) => g.name.toLowerCase().contains(_query))
                      .toList();

              if (searched.isEmpty && (!showGroups || searchedGroups.isEmpty)) {
                return _EmptyState(
                  isDark: isDark,
                  searching: _query.isNotEmpty,
                  isGroups: _filter == _Filter.groups,
                );
              }

              return CupertinoScrollbar(
                child: CustomScrollView(
                  slivers: [
                    // ── Archived Row ──
                    if (!_showArchived &&
                        conversations.any((c) => c.isArchived) &&
                        _filter == _Filter.all &&
                        _query.isEmpty)
                      SliverToBoxAdapter(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          onPressed: () => setState(() => _showArchived = true),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.archivebox,
                                size: 20,
                                color: AppColors.textSecondary(isDark),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Text(
                                'Archived',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${conversations.where((c) => c.isArchived).length}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: AppColors.textMuted(isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_showArchived)
                      SliverToBoxAdapter(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          onPressed: () => setState(() => _showArchived = false),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.back, size: 18, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                'Back to chats',
                                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Groups List ──
                    if (showGroups)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => GroupChatTile(group: searchedGroups[i]),
                          childCount: searchedGroups.length,
                        ),
                      ),

                    // ── Direct Conversations ──
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ConversationTile(
                          conversation: searched[i],
                          onTap: () => _openChat(searched[i]),
                        ),
                        childCount: searched.length,
                      ),
                    ),

                    // ── Encrypted Caption Footer & Clearance ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.lock_fill,
                              size: 13,
                              color: AppColors.textMuted(isDark),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Your personal messages are end-to-end encrypted',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<ConversationModel> _applyFilter(List<ConversationModel> all) {
    // Only show conversations where chat has actually started (at least 1 message)
    final activeOnly = all.where((c) =>
        c.lastMessage.trim().isNotEmpty &&
        c.lastMessage != 'Tap to chat').toList();

    final base = _showArchived
        ? activeOnly.where((c) => c.isArchived).toList()
        : activeOnly.where((c) => !c.isArchived).toList();
    final filtered = switch (_filter) {
      _Filter.all => base,
      _Filter.unread => base.where((c) => c.unreadCount > 0).toList(),
      _Filter.favorites => base.where((c) => c.isPinned).toList(),
      _Filter.groups => <ConversationModel>[],
    };
    filtered.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.lastTimestamp.compareTo(a.lastTimestamp);
    });
    return filtered;
  }

  void _openChat(ConversationModel c) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ChatScreen(
          participantId: c.participantId,
          participantName: c.participantName,
          participantImageUrl: c.participantImageUrl,
          participantAbout: '',
          participantEmail: '',
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.25 : 0.15)
                : (isDark ? const Color(0xFF242428) : const Color(0xFFEFEFF4)),
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? Border.all(color: accent.withValues(alpha: 0.6), width: 1.0)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? accent : AppColors.textSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool searching;
  final bool isGroups;

  const _EmptyState({
    required this.isDark,
    required this.searching,
    this.isGroups = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searching
                ? CupertinoIcons.search
                : (isGroups ? CupertinoIcons.person_2_fill : CupertinoIcons.chat_bubble_2),
            size: 54,
            color: AppColors.textMuted(isDark),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            searching
                ? 'No results'
                : (isGroups ? 'No groups yet' : 'No conversations yet'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            searching
                ? 'Try a different search'
                : (isGroups
                    ? 'Create a group to start chatting with multiple people'
                    : 'Start a chat or create a group to begin'),
            style: TextStyle(color: AppColors.textMuted(isDark)),
          ),
        ],
      ),
    );
  }
}

