import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_messenger/core/database/local_database_helper.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/features/chat/screens/chat_screen.dart';
import 'package:quick_messenger/features/chat/screens/group_chat_screen.dart';

/// iOS-native message search (local SQLite LIKE search).
///
/// [CupertinoSearchTextField] with debounce, results in
/// [CupertinoListSection] rows distinguishing direct vs group hits.
class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isNotEmpty) {
        final results = await LocalDatabaseHelper.instance
            .searchAllMessages(currentUserId, query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      }
    });
  }

  void _navigateToChat(Map<String, dynamic> result) {
    final chatType = result['chat_type'];
    final chatId = result['chat_id'];
    final chatName = result['chat_name'] ?? 'Unknown';

    if (chatType == 'direct') {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => ChatScreen(
            participantId: result['participant_id'] ?? chatId,
            participantName: chatName,
            participantImageUrl: result['chat_image'] ?? '',
            participantAbout: 'Hey there! I am using QuickMessenger.',
            participantEmail: '',
          ),
        ),
      );
    } else if (chatType == 'group') {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => GroupChatScreen(
            groupId: chatId,
            groupName: chatName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final query = _searchController.text.trim();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Search Messages'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs,
                  AppSpacing.md, AppSpacing.xs),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search messages',
                autofocus: true,
                onChanged: _onSearchChanged,
                onSuffixTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _searchResults.isEmpty && query.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.search,
                                  size: 44,
                                  color: AppColors.textMuted(isDark)),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'No messages found',
                                style: TextStyle(
                                    color: AppColors.textSecondary(
                                        isDark)),
                              ),
                            ],
                          ),
                        )
                      : _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'Search across all chats and groups',
                                style: TextStyle(
                                    color:
                                        AppColors.textMuted(isDark)),
                              ),
                            )
                          : CupertinoListSection.insetGrouped(
                              backgroundColor:
                                  AppColors.background(isDark),
                              margin: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              children: _searchResults.map((result) {
                                final text =
                                    (result['text'] ?? '').toString();
                                final chatName =
                                    (result['chat_name'] ?? 'Unknown')
                                        .toString();
                                final isGroup =
                                    result['chat_type'] == 'group';
                                final timestamp =
                                    (result['client_created_at'] ??
                                            '')
                                        .toString();

                                String formattedTime = '';
                                if (timestamp.isNotEmpty) {
                                  try {
                                    final dt =
                                        DateTime.parse(timestamp);
                                    formattedTime =
                                        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                  } catch (_) {}
                                }

                                return CupertinoListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CupertinoTheme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: Icon(
                                      isGroup
                                          ? CupertinoIcons.group
                                          : CupertinoIcons
                                              .person,
                                      color: CupertinoTheme.of(context)
                                          .primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    chatName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted(
                                              isDark),
                                        ),
                                      ),
                                      if (isGroup)
                                        Text(
                                          'Group',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoTheme.of(
                                                    context)
                                                .primaryColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () =>
                                      _navigateToChat(result),
                                );
                              }).toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
