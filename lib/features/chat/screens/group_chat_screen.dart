import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';

import 'package:quick_messenger/features/chat/providers/chat_provider.dart';
import 'package:quick_messenger/features/chat/widgets/message_bubble.dart';
import 'package:quick_messenger/features/chat/widgets/message_input.dart';
import 'package:quick_messenger/features/chat/screens/group_profile_screen.dart';

/// iOS-native group chat screen.
///
/// - [CupertinoPageScaffold] + [CupertinoNavigationBar]
/// - Messages via [groupMessagesProvider] (Riverpod → SQLite → Socket → UI)
/// - Input via [MessageInput] (CupertinoTextField, morphing send, haptics)
/// - Long-press → [CupertinoActionSheet] (handled by MessageBubble)
/// - Group info tap → [GroupProfileScreen] via [CupertinoPageRoute]
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageC = TextEditingController();
  final ScrollController _scrollC = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .update({"online": false});
    } else if (state == AppLifecycleState.resumed) {
      FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .update({"online": true});
    }
  }

  @override
  void dispose() {
    _messageC.dispose();
    _scrollC.dispose();
    WidgetsBinding.instance.removeObserver(this);
    NetworkCheck().cancelSubscription();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _messageC.text.trim();
    if (text.isEmpty) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid.isEmpty) return;

    // Send via Riverpod notifier (handles Socket + SQLite + Firestore)
    await ref.read(groupMessagesProvider(widget.groupId).notifier).sendMessage(
      senderId: uid,
      groupId: widget.groupId,
      text: text,
    );
    _messageC.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleBack() {
    ref.read(groupsProvider.notifier).loadGroups();
    Navigator.pop(context);
  }


  void _openGroupProfile() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => GroupProfileScreen(
          groupId: widget.groupId,
          groupName: widget.groupName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.groupName),
          leading: CupertinoNavigationBarBackButton(
            onPressed: _handleBack,
          ),
          trailing: CupertinoButton(

          padding: EdgeInsets.zero,
          onPressed: _openGroupProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.group_solid, color: CupertinoColors.white, size: 16),
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              const Icon(CupertinoIcons.chevron_right, size: 14),
            ],
          ),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle,
                          size: 48, color: CupertinoColors.systemRed),
                      SizedBox(height: AppSpacing.sm),
                      Text("Failed to load messages",
                          style: TextStyle(color: CupertinoColors.systemRed)),
                      SizedBox(height: AppSpacing.xs),
                      Text(e.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.chat_bubble_2,
                              size: 54, color: AppColors.textMuted(isDark)),
                          SizedBox(height: AppSpacing.sm),
                          Text("No messages yet",
                              style: TextStyle(color: AppColors.textSecondary(isDark))),
                          SizedBox(height: AppSpacing.xs),
                          Text("Say hi to the group!",
                              style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollC,
                    reverse: true,
                    padding: EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.senderId == currentUserId;

                      return MessageBubble(
                        key: ValueKey(msg.messageId),
                        message: msg,
                        isMe: isMe,
                        animateEntrance: true,
                        onReply: null,
                        onForward: null,
                        onEdit: isMe ? (newText) {
                          ref.read(groupMessagesProvider(widget.groupId).notifier)
                              .editMessage(msg.messageId, newText);
                        } : null,
                        onToggleReaction: (emoji) {
                          ref.read(groupMessagesProvider(widget.groupId).notifier)
                              .toggleReaction(msg.messageId, emoji, currentUserId);
                        },
                        onDeleteForMe: () {
                          ref.read(groupMessagesProvider(widget.groupId).notifier)
                              .deleteForMe(msg.messageId);
                        },
                        onDeleteForEveryone: isMe ? () {
                          ref.read(groupMessagesProvider(widget.groupId).notifier)
                              .deleteForEveryone(msg.messageId);
                        } : null,
                      );
                    },
                  );
                },
              ),
            ),
            MessageInput(
              controller: _messageC,
              onChanged: (_) {},
              onSend: _handleSend,
              onAttach: null, // group attachments not yet implemented
            ),
          ],
        ),
      ),
    ),
  );
}
}