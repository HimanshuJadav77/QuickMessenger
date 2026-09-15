import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_action_sheet.dart';
import '../../../core/widgets/user_avatar.dart';
import '../models/group_model.dart';
import '../providers/chat_provider.dart';
import '../screens/group_chat_screen.dart';
import '../screens/group_profile_screen.dart';

class GroupChatTile extends ConsumerWidget {
  final GroupModel group;
  final VoidCallback? onTap;

  const GroupChatTile({
    super.key,
    required this.group,
    this.onTap,
  });

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[dt.month - 1]} ${dt.day}';
      }
    } catch (_) {
      return '';
    }
  }

  void _showGroupOptions(BuildContext context, WidgetRef ref, bool isOwner) {
    HapticFeedback.lightImpact();
    LGActionSheet.show(
      context: context,
      title: group.name,
      actions: [
        LGActionSheetAction(
          title: 'Group Info',
          icon: CupertinoIcons.info_circle,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => GroupProfileScreen(
                  groupId: group.groupId,
                  groupName: group.name,
                ),
              ),
            );
          },
        ),
        if (isOwner)
          LGActionSheetAction(
            title: 'Delete Group',
            icon: CupertinoIcons.trash_fill,
            isDestructive: true,
            onPressed: () {
              LGActionSheet.showConfirmation(
                context: context,
                title: 'Delete "${group.name}"?',
                message: 'This group will be deleted for all members and cannot be undone.',
                confirmTitle: 'Delete Group',
                isDestructive: true,
                onConfirm: () {
                  ref.read(groupsProvider.notifier).deleteGroup(group.groupId);
                },
              );
            },
          )
        else
          LGActionSheetAction(
            title: 'Exit Group',
            icon: CupertinoIcons.square_arrow_right,
            isDestructive: true,
            onPressed: () {
              LGActionSheet.showConfirmation(
                context: context,
                title: 'Exit "${group.name}"?',
                message: 'You will no longer be a member of this group.',
                confirmTitle: 'Exit Group',
                isDestructive: true,
                onConfirm: () {
                  ref.read(groupsProvider.notifier).leaveGroup(group.groupId);
                },
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = (group.createdBy == currentUserId) || (group.myRole == 'owner');
    final hasMessage = group.lastMessage != null && group.lastMessage!.trim().isNotEmpty;
    final subtitleText = hasMessage ? group.lastMessage! : 'No messages yet';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => GroupChatScreen(
                  groupId: group.groupId,
                  groupName: group.name,
                ),
              ),
            );
          },
      onLongPress: () => _showGroupOptions(context, ref, isOwner),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Group Avatar with distinction badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    username: group.name,
                    imageUrl: group.imageUrl,
                    radius: 26,
                  ),
                  // Group distinction badge
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.person_2_fill,
                        size: 11,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.md),
              // Group Name + Distinction Tag + Last Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Group',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        if (group.lastTimestamp != null && group.lastTimestamp!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(group.lastTimestamp!),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted(isDark),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitleText,
                            style: hasMessage
                                ? AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 13,
                                  )
                                : AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textMuted(isDark),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${group.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
}
