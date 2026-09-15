import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_action_sheet.dart';
import '../../../core/widgets/user_avatar.dart';
import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';

class ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  void _showChatActions(BuildContext context, WidgetRef ref, ConversationModel c) {
    HapticFeedback.selectionClick();
    LGActionSheet.show(
      context: context,
      title: c.participantName,
      message: c.lastMessage.isNotEmpty ? c.lastMessage : null,
      actions: [
        LGActionSheetAction(
          title: c.unreadCount > 0 ? 'Mark as read' : 'Mark as unread',
          icon: c.unreadCount > 0 ? CupertinoIcons.check_mark_circled : CupertinoIcons.chat_bubble,
          onPressed: () => ref.read(conversationsProvider.notifier).markUnread(c.id),
        ),
        LGActionSheetAction(
          title: c.isPinned ? 'Unpin chat' : 'Pin chat',
          icon: c.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          onPressed: () => ref.read(conversationsProvider.notifier).togglePin(c.id, !c.isPinned),
        ),
        LGActionSheetAction(
          title: c.isMuted ? 'Unmute' : 'Mute',
          icon: c.isMuted ? CupertinoIcons.bell : CupertinoIcons.bell_slash,
          onPressed: () => ref.read(conversationsProvider.notifier).toggleMute(c.id, !c.isMuted),
        ),
        LGActionSheetAction(
          title: c.isArchived ? 'Unarchive' : 'Archive',
          icon: CupertinoIcons.archivebox,
          onPressed: () => ref.read(conversationsProvider.notifier).toggleArchive(c.id, !c.isArchived),
        ),
        LGActionSheetAction(
          title: 'Add to Favorites',
          icon: CupertinoIcons.heart,
          onPressed: () => ref.read(conversationsProvider.notifier).togglePin(c.id, true),
        ),
        LGActionSheetAction(
          title: 'Clear chat',
          icon: CupertinoIcons.clear,
          isDestructive: true,
          onPressed: () {
            LGActionSheet.showConfirmation(
              context: context,
              title: 'Clear Chat?',
              message: 'Delete all messages in this conversation from this device?',
              confirmTitle: 'Clear Chat',
              isDestructive: true,
              onConfirm: () => ref.read(conversationsProvider.notifier).deleteConversation(c.id),
            );
          },
        ),
        LGActionSheetAction(
          title: 'Delete chat',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () {
            LGActionSheet.showConfirmation(
              context: context,
              title: 'Delete Chat?',
              message: 'Are you sure you want to delete this chat with ${c.participantName}?',
              confirmTitle: 'Delete Chat',
              isDestructive: true,
              onConfirm: () => ref.read(conversationsProvider.notifier).deleteConversation(c.id),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final c = conversation;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showChatActions(context, ref, c),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            UserAvatar(
              username: c.participantName,
              seed: c.participantId.isNotEmpty ? c.participantId : c.id,
              imageUrl: c.participantImageUrl,
              radius: 26,
            ),
            SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (c.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            CupertinoIcons.pin_fill,
                            size: 13,
                            color: AppColors.textMuted(isDark),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          c.participantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(c.lastTimestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: c.unreadCount > 0
                              ? accent
                              : AppColors.textMuted(isDark),
                          fontWeight: c.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (c.isMuted)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            CupertinoIcons.bell_slash_fill,
                            size: 13,
                            color: AppColors.textMuted(isDark),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 14,
                          color: AppColors.textMuted(isDark),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: c.unreadCount > 0
                                ? AppColors.textPrimary(isDark)
                                : AppColors.textSecondary(isDark),
                          ),
                        ),
                      ),
                      if (c.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat('HH:mm').format(dt);
      }
      if (now.difference(dt).inDays < 7) {
        return DateFormat('EEE').format(dt);
      }
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return '';
    }
  }
}


