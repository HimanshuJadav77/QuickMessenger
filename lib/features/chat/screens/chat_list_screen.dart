import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_filter_chip.dart';
import 'package:quick_messenger/core/widgets/app_screen_header.dart';
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

    final unreadCountTotal =
        conversationsAsync.value?.where((c) => c.unreadCount > 0).length ?? 0;

    return Column(
      children: [
        // ── Header Top Row ──
        AppScreenHeader(
          title: 'Chats',
          actions: [
            AppHeaderIconButton(
              icon: CupertinoIcons.plus,
              isPrimary: true,
              iconSize: 22,
              onPressed: _showMoreMenu,
            ),
          ],
        ),

        // ── Search Field ──
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: LGSearchField(
            controller: _searchController,
            placeholder: 'Search chats or messages',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            onClear: () => setState(() => _query = ''),
          ),
        ),

        // ── Filter Pills Row ──
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              AppFilterChip(
                label: 'All',
                isSelected: _filter == _Filter.all,
                onTap: () => setState(() => _filter = _Filter.all),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Unread',
                count: unreadCountTotal,
                isSelected: _filter == _Filter.unread,
                onTap: () => setState(() => _filter = _Filter.unread),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Favorites',
                isSelected: _filter == _Filter.favorites,
                onTap: () => setState(() => _filter = _Filter.favorites),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Groups',
                isSelected: _filter == _Filter.groups,
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
              final groups = rawGroups
                  .where((g) =>
                      (g.lastMessage != null &&
                          g.lastMessage!.trim().isNotEmpty) ||
                      g.createdBy == currentUserId)
                  .toList();
              final visible = _applyFilter(conversations);
              final searched = _query.isEmpty
                  ? visible
                  : visible
                      .where((c) =>
                          c.participantName.toLowerCase().contains(_query) ||
                          c.lastMessage.toLowerCase().contains(_query))
                      .toList();
              final showGroups =
                  (_filter == _Filter.all || _filter == _Filter.groups) &&
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
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
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
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          onPressed: () =>
                              setState(() => _showArchived = false),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.back,
                                  size: 18, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                'Back to chats',
                                style: TextStyle(
                                    color: accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Groups List ──
                    if (showGroups)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => RepaintBoundary(
                            key: ValueKey('group_${searchedGroups[i].groupId}'),
                            child: GroupChatTile(group: searchedGroups[i]),
                          ),
                          findChildIndexCallback: (Key key) {
                            final valKey = key as ValueKey<String>?;
                            if (valKey == null) return null;
                            final val = valKey.value;
                            if (!val.startsWith('group_')) return null;
                            final gId = val.substring('group_'.length);
                            final idx = searchedGroups
                                .indexWhere((g) => g.groupId == gId);
                            return idx == -1 ? null : idx;
                          },
                          childCount: searchedGroups.length,
                        ),
                      ),

                    // ── Direct Conversations ──
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => RepaintBoundary(
                          key: ValueKey('chat_${searched[i].id}'),
                          child: ConversationTile(
                            conversation: searched[i],
                            onTap: () => _openChat(searched[i]),
                          ),
                        ),
                        findChildIndexCallback: (Key key) {
                          final valKey = key as ValueKey<String>?;
                          if (valKey == null) return null;
                          final val = valKey.value;
                          if (!val.startsWith('chat_')) return null;
                          final cId = val.substring('chat_'.length);
                          final idx = searched.indexWhere((c) => c.id == cId);
                          return idx == -1 ? null : idx;
                        },
                        childCount: searched.length,
                      ),
                    ),

                    // Bottom navigation clearance
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
    final activeOnly = all
        .where((c) =>
            c.lastMessage.trim().isNotEmpty && c.lastMessage != 'Tap to chat')
        .toList();

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
                : (isGroups
                    ? CupertinoIcons.person_2_fill
                    : CupertinoIcons.chat_bubble_2),
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
